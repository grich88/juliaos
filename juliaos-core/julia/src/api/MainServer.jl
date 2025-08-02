module MainServer

using Oxygen
using HTTP
using ..Routes
using ..WebSockets.AlertsWebSocket
using JSON3
using Dates
using LRUCache: LRU
using Base.Threads: SpinLock, @spawn, @threads
using ..LeverageSystem # Use LeverageSystem module

# Constants
const CORS_HEADERS = Dict{String,String}(
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers" => "Content-Type, Authorization, X-API-Key, Accept",
    "Access-Control-Max-Age" => "86400",
    "Access-Control-Allow-Credentials" => "true",
    "Content-Type" => "application/json",
    "Access-Control-Expose-Headers" => "Content-Length, Content-Type"
)

# Thread-safe logger
mutable struct ThreadSafeLogger
    lock::SpinLock
    log_buffer::Vector{String}
    
    ThreadSafeLogger() = new(SpinLock(), String[])
end

const LOGGER = ThreadSafeLogger()

# Caches
const CORS_CACHE = LRU{String, Bool}(maxsize=1000)
const API_KEY_CACHE = LRU{String, Bool}(maxsize=1000)
const RATE_LIMITER = Dict{String, Tuple{Int, Dates.DateTime}}()
const RATE_LIMIT_LOCK = SpinLock()

# Middleware functions
function logging_middleware(handler)
    return function(req)
        start_time = now()
        try
            response = handler(req)
            duration = now() - start_time
            
            lock(LOGGER.lock) do
                push!(LOGGER.log_buffer, "$(now()) - $(req.method) $(req.target) - $(duration.value)ms")
            end
            
            return response
        catch e
            lock(LOGGER.lock) do
                push!(LOGGER.log_buffer, "$(now()) - ERROR: $(e)")
            end
            rethrow(e)
        end
    end
end

function content_type_middleware(handler)
    return function(req)
        response = handler(req)
        if !haskey(response.headers, "Content-Type")
            push!(response.headers, "Content-Type" => "application/json")
        end
        return response
    end
end

function auth_middleware(handler)
    return function(req)
        api_key = HTTP.header(req, "X-API-Key", "")
        
        # Check cache first
        cached = get(API_KEY_CACHE, api_key, nothing)
        if !isnothing(cached)
            return cached ? check_rate_limit(api_key, handler, req) : HTTP.Response(401)
        end
        
        # Validate API key
        if is_valid_api_key(api_key)
            API_KEY_CACHE[api_key] = true
            return check_rate_limit(api_key, handler, req)
        else
            API_KEY_CACHE[api_key] = false
            return HTTP.Response(401)
        end
    end
end

# Helper functions
function check_rate_limit(api_key::String, handler::Function, req)
    lock(RATE_LIMIT_LOCK) do
        current_time = now()
        if haskey(RATE_LIMITER, api_key)
            count, last_reset = RATE_LIMITER[api_key]
            
            # Reset counter if window has passed
            if current_time - last_reset > Second(60)
                RATE_LIMITER[api_key] = (1, current_time)
                return handler(req)
            end
            
            # Check limit
            if count >= 100  # 100 requests per minute
                return HTTP.Response(429)
            end
            
            # Increment counter
            RATE_LIMITER[api_key] = (count + 1, last_reset)
        else
            RATE_LIMITER[api_key] = (1, current_time)
        end
    end
    
    return handler(req)
end

function is_valid_origin(origin::String)::Bool
    # Implement origin validation logic
    return true  # Placeholder
end

function is_valid_api_key(api_key::String)::Bool
    # Implement API key validation logic
    return true  # Placeholder
end

# Server configuration and startup
const server_middleware = [
    logging_middleware,
    content_type_middleware,
    auth_middleware
]

function start_server(;
    default_host::String="0.0.0.0",
    default_port::Int=8080,
    ws_port::Int=8081
)
    # Skip leverage initialization at startup for faster boot time
    # The leverage system will be initialized on first use
    @info "Leverage system will be initialized on first use"
    
    # Get host and port from environment or use defaults
    api_host = get(ENV, "API_HOST", default_host)
    api_port = parse(Int, get(ENV, "API_PORT", string(default_port)))
    
    # Configure WebSocket server
    @async HTTP.WebSockets.listen(api_host, ws_port) do ws
        AlertsWebSocket.handle_ws_connection(ws)
    end
    
    # Start main API server with parallel serving
    @info "Starting API server on $api_host:$api_port"
    
    # Configure server with error handling
    try
        # Create a router with all our routes
        app = Oxygen.router()
        Routes.register_routes(app)
        
        # Start HTTP server with enhanced configuration
        server = Oxygen.serve(;
            router=app,
            host=api_host,
            port=api_port,
            before_request=[
                req -> begin
                    # Handle preflight requests
                    if req.method == "OPTIONS"
                        # Add CORS headers to response
                        response = HTTP.Response(200)
                        for (key, value) in CORS_HEADERS
                            push!(response.headers, key => value)
                        end
                        return response
                    end
                    
                    # Add Leverage context to request
                    req.context = Dict{Symbol,Any}(
                        :leverage_context => LeverageSystem.get_context(),
                        :cors_headers => CORS_HEADERS
                    )
                    
                    return req
                end
            ],
            after_request=[
                (req, res) -> begin
                    # Add CORS headers to all responses
                    for (key, value) in CORS_HEADERS
                        if !haskey(res.headers, key)
                            push!(res.headers, key => value)
                        end
                    end
                    
                    # Clean up Leverage context
                    if haskey(req.context, :leverage_context)
                        LeverageSystem.cleanup_context(req.context[:leverage_context])
                    end
                    
                    return res
                end
            ],
            error_handler=(req, err) -> begin
                # Ensure CORS headers are present even in error responses
                error_response = HTTP.Response(500, CORS_HEADERS)
                # Content-Type is already set in CORS_HEADERS
                error_response.body = JSON3.write(Dict(
                    "error" => "Internal server error",
                    "details" => sprint(showerror, err)
                ))
                return error_response
            end,
            websocket_options=(
                ping_interval=30.0,
                idle_timeout=120.0
            )
        )
        @info "Server started successfully on http://$api_host:$api_port"
        
        # Keep the server running
        wait(server)
    catch e
        @error "Failed to start server" exception=e
        rethrow(e)
    finally
        # Clean up Leverage system
        try
            @info "Cleaning up Leverage system..."
            LeverageSystem.cleanup()
        catch cleanup_err
            @error "Error during Leverage system cleanup" exception=cleanup_err
        end
    end
end

function cleanup()
    # Clean up any resources
    try
        @info "Cleaning up server resources..."
        empty!(CORS_CACHE)
        empty!(API_KEY_CACHE)
        empty!(RATE_LIMITER)
        empty!(LOGGER.log_buffer)
    catch e
        @error "Error during server cleanup" exception=e
    end
end

end # module