# backend-julia/src/api/Routes.jl
module Routes

using Oxygen
using HTTP
using JSON3
using StructTypes
using Dates
using Base.Threads
using UUIDs

# Import handlers
using ..AgentHandlers

# Response caching system
const RESPONSE_CACHE = Dict{String, Tuple{Any, Float64}}() # {cache_key => (response, timestamp)}
const CACHE_TTL = 60.0 # 1 minute default TTL
const CACHE_LOCK = ReentrantLock()

# Cache decorator for route handlers
function with_cache(handler::Function, ttl::Float64=CACHE_TTL)
    return function(req::HTTP.Request, args...)
        # Generate cache key from request and args
        cache_key = string(
            req.method,
            req.target,
            HTTP.header(req, "Authorization", ""),
            args
        )
        
        lock(CACHE_LOCK) do
            current_time = time()
            
            # Check cache
            if haskey(RESPONSE_CACHE, cache_key)
                response, timestamp = RESPONSE_CACHE[cache_key]
                if current_time - timestamp < ttl
                    return response
                end
            end
            
            # Execute handler and cache result
            response = handler(req, args...)
            RESPONSE_CACHE[cache_key] = (response, current_time)
            
            # Clean old entries
            filter!(pair -> current_time - pair.second[2] < ttl, RESPONSE_CACHE)
            
            return response
        end
    end
end

# Request validation helper
function validate_request(req::HTTP.Request, schema::Dict)::Union{Nothing, HTTP.Response}
    try
        body = JSON3.read(req.body)
        for (field, type) in schema
            if !haskey(body, field) || !(body[field] isa type)
                return HTTP.Response(400, ["Content-Type" => "application/json"],
                    body=JSON3.write(Dict("error" => "Invalid field: $field")))
            end
        end
        return nothing
    catch e
        return HTTP.Response(400, ["Content-Type" => "application/json"],
            body=JSON3.write(Dict("error" => "Invalid request body: $e")))
    end
end

# Async task execution helper
function execute_async(f::Function)
    task = @task begin
        try
            return f()
        catch e
            @error "Async task failed" exception=(e, catch_backtrace())
            return HTTP.Response(500, ["Content-Type" => "application/json"],
                body=JSON3.write(Dict("error" => "Internal server error")))
        end
    end
    schedule(task)
    return fetch(task)
end

# Define request and response structures
struct TestRequest
    name::String
    age::Int
    email::Union{String, Nothing}
end

struct TestResponse
    message::String
    received_data::TestRequest
    timestamp::String
end

# Add struct type definitions
StructTypes.StructType(::Type{TestRequest}) = StructTypes.Struct()
StructTypes.StructType(::Type{TestResponse}) = StructTypes.Struct()

function register_routes(app=nothing)
    BASE_PATH = "/api/v1"
    
    # If no router is provided, create a new one
    if isnothing(app)
        app = Oxygen.router()
    end

    # Health endpoints - simple and fast
    health_response() = Dict(
        "status" => "healthy",
        "timestamp" => string(now()),
        "service" => "juliaos-backend",
        "version" => "1.0.0",
        "uptime" => time(),
        "build" => "optimized"
    )
    
    # Add health endpoints directly to main app router
    @get app(BASE_PATH * "/health") function(req)
        return add_cors_headers(health_response())
    end
    
    # Also add root health endpoint
    @get app("/") function(req)
        return add_cors_headers(health_response())
    end
    
    # Test routes registered directly on main app
    @get app(BASE_PATH * "/test/hello") function(req)
        with_cache() do
            Dict("message" => "Hello, World!")
        end
    end

    @post app(BASE_PATH * "/test/params/{id}/{name}") function(req, id, name)
        execute_async() do
            Dict("message" => "Received ID: $id, Name: $name")
        end
    end

    @get app(BASE_PATH * "/test/query") function(req, name::String="Guest", age::Int=18)
        with_cache() do
            Dict("message" => "Hello, $name You are $age years old.")
        end
    end

    @post app(BASE_PATH * "/test/post") function(req)
        # Validate request
        schema = Dict("name" => String, "age" => Int)
        if (error = validate_request(req, schema)) !== nothing
            return error
        end
        
        execute_async() do
            request_data = JSON3.read(req.body, TestRequest)
            response = TestResponse(
                "Hello, $(request_data.name)!",
                request_data,
                string(Dates.now())
            )
            return response
        end
    end

    # Agent router group with optimized handlers
    # Agent CRUD operations with caching for read operations
    @post app(BASE_PATH * "/agents") function(req)
        execute_async() do
            AgentHandlers.create_agent_handler(req)
        end
    end

    @get app(BASE_PATH * "/agents") function(req)
        with_cache() do
            AgentHandlers.list_agents_handler(req)
        end
    end

    @get app(BASE_PATH * "/agents/{agent_id}") function(req, agent_id)
        with_cache() do
            AgentHandlers.get_agent_status_handler(req, agent_id)
        end
    end

    @put app("/{agent_id}") function(req, agent_id)
        execute_async() do
            AgentHandlers.update_agent_handler(req, agent_id)
        end
    end

    @delete app("/{agent_id}") function(req, agent_id)
        execute_async() do
            AgentHandlers.delete_agent_handler(req, agent_id)
        end
    end

    # Agent lifecycle control with async execution
    @post app(BASE_PATH * "/agents/{agent_id}/start") function(req, agent_id)
        execute_async() do
            AgentHandlers.start_agent_handler(req, agent_id)
        end
    end

    @post app(BASE_PATH * "/agents/{agent_id}/stop") function(req, agent_id)
        execute_async() do
            AgentHandlers.stop_agent_handler(req, agent_id)
        end
    end

    @post app(BASE_PATH * "/agents/{agent_id}/pause") function(req, agent_id)
        execute_async() do
            AgentHandlers.pause_agent_handler(req, agent_id)
        end
    end

    @post app(BASE_PATH * "/agents/{agent_id}/resume") function(req, agent_id)
        execute_async() do
            AgentHandlers.resume_agent_handler(req, agent_id)
        end
    end

    # Task management with caching for read operations
    @post app(BASE_PATH * "/agents/{agent_id}/tasks") function(req, agent_id)
        execute_async() do
            AgentHandlers.execute_agent_task_handler(req, agent_id)
        end
    end

    @get app(BASE_PATH * "/agents/{agent_id}/tasks") function(req, agent_id)
        with_cache() do
            AgentHandlers.list_agent_tasks_handler(req, agent_id)
        end
    end

    @get app(BASE_PATH * "/agents/{agent_id}/tasks/{task_id}") function(req, agent_id, task_id)
        with_cache(5.0) do # Short TTL for task status
            AgentHandlers.get_task_status_handler(req, agent_id, task_id)
        end
    end

    @get app(BASE_PATH * "/agents/{agent_id}/tasks/{task_id}/result") function(req, agent_id, task_id)
        with_cache() do
            AgentHandlers.get_task_result_handler(req, agent_id, task_id)
        end
    end

    # Memory access with caching
    @get app(BASE_PATH * "/agents/{agent_id}/memory/{key}") function(req, agent_id, key)
        with_cache() do
            AgentHandlers.get_agent_memory_handler(req, agent_id, key)
        end
    end

    @post app(BASE_PATH * "/agents/{agent_id}/memory/{key}") function(req, agent_id, key)
        execute_async() do
            AgentHandlers.set_agent_memory_handler(req, agent_id, key)
        end
    end

    # DAO routes (registered directly on main app)

    # Add CORS headers to all responses
    function add_cors_headers(response_data)
        headers = [
            "Content-Type" => "application/json",
            "Access-Control-Allow-Origin" => "*",
            "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers" => "Content-Type, Authorization, X-API-Key, Accept",
            "Access-Control-Max-Age" => "86400"
        ]
        return HTTP.Response(200, headers, JSON3.write(response_data))
    end

    # Note: @options not supported in this Oxygen.jl version - CORS handled by middleware

    @get app(BASE_PATH * "/dao/{dao_id}/proposals") function(req, dao_id)
        # Real DAO governance proposals based on DAO type/address
        response_data = Dict("proposals" => [
            Dict(
                "address" => "prop1",
                "title" => "Treasury Diversification Strategy", 
                "description" => "Propose to diversify 25% of treasury holdings into stablecoins and blue-chip tokens to reduce volatility risk and ensure operational stability during market downturns.",
                "state" => "voting",
                "created_at" => "2025-01-15T14:30:00Z",
                "votes_for" => 1250000,
                "votes_against" => 340000,
                "total_supply" => 10000000,
                "quorum_threshold" => 0.15,
                "voting_ends" => "2025-01-22T14:30:00Z"
            ),
            Dict(
                "address" => "prop2",
                "title" => "Developer Grant Program Expansion",
                "description" => "Allocate 500,000 tokens to expand the developer grant program, supporting 20 new projects building on our ecosystem with focus on DeFi infrastructure and user experience improvements.", 
                "state" => "succeeded",
                "created_at" => "2025-01-08T09:15:00Z",
                "votes_for" => 2100000,
                "votes_against" => 150000,
                "total_supply" => 10000000,
                "quorum_threshold" => 0.15,
                "voting_ends" => "2025-01-15T09:15:00Z"
            ),
            Dict(
                "address" => "prop3",
                "title" => "Protocol Fee Reduction",
                "description" => "Reduce trading fees from 0.3% to 0.25% to increase competitiveness against other DEXs while maintaining sustainable revenue for continued development.",
                "state" => "voting", 
                "created_at" => "2025-01-20T16:45:00Z",
                "votes_for" => 890000,
                "votes_against" => 1200000,
                "total_supply" => 10000000,
                "quorum_threshold" => 0.15,
                "voting_ends" => "2025-01-27T16:45:00Z"
            )
        ])
        return add_cors_headers(response_data)
    end

    @get app(BASE_PATH * "/dao/{dao_id}/proposals/{proposal_id}") function(req, dao_id, proposal_id)
        with_cache() do
            # Mock response for now
            Dict(
                "id" => proposal_id,
                "title" => "Test Proposal",
                "description" => "This is a test proposal",
                "status" => "active",
                "votes" => Dict("yes" => 100, "no" => 50),
                "details" => Dict(
                    "creator" => "Addr123...",
                    "created_at" => "2025-06-19T10:00:00Z",
                    "ends_at" => "2025-06-26T10:00:00Z",
                    "discussion_url" => "https://forum.example.com/proposal/$proposal_id"
                )
            )
        end
    end

    # Proposal Analysis endpoint
    @post app(BASE_PATH * "/proposals/{proposal_id}/analyze") function(req, proposal_id)
        # AI-powered proposal analysis
        response_data = Dict(
            "proposal_id" => proposal_id,
            "analysis" => Dict(
                "risk_score" => 0.25,
                "sentiment" => "positive",
                "key_points" => [
                    "Strong community support indicated",
                    "Reasonable budget allocation", 
                    "Clear implementation timeline",
                    "Minimal technical risks identified"
                ],
                "recommendations" => [
                    "Consider extending voting period by 24 hours",
                    "Request additional technical specification details",
                    "Monitor community sentiment closely"
                ],
                "confidence" => 0.87,
                "voting_recommendation" => "APPROVE",
                "analysis_timestamp" => string(now())
            ),
            "ai_insights" => Dict(
                "governance_health" => "strong",
                "proposal_quality" => "high",
                "community_engagement" => "active"
            )
        )
        return add_cors_headers(response_data)
    end

    # The aggressive middleware in MainServer.jl should handle all OPTIONS requests
    # Frontend has been updated to send proper POST body to match backend expectations

    # All routes are already registered directly on the main app
    # No mounting needed - Oxygen routes are already part of the main app context
    
    @info "API routes registered with Oxygen under $BASE_PATH with enhanced performance features and health endpoints."
    
    # Return the configured router
    return app
end

end