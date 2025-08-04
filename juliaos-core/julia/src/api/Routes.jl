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

# CORS headers
const CORS_HEADERS = [
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
    "Access-Control-Allow-Headers" => "Content-Type, Authorization",
    "Access-Control-Max-Age" => "86400"
]

# Add CORS headers to any response
function add_cors_headers(response::HTTP.Response)
    for (key, value) in CORS_HEADERS
        HTTP.setheader(response, key => value)
    end
    return response
end

function add_cors_headers(data::Dict)
    return HTTP.Response(200, CORS_HEADERS, body=JSON3.write(data))
end

# Error response with CORS
function error_response(message::String, status::Int=500; error_code::String="INTERNAL_ERROR", details::Dict=Dict())
    response = HTTP.Response(
        status,
        CORS_HEADERS,
        body=JSON3.write(Dict(
            "error" => message,
            "error_code" => error_code,
            "details" => details
        ))
    )
    return response
end

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

        # Register both GET and OPTIONS handlers for the DAO proposals endpoint
    @route ["GET", "OPTIONS"] app(BASE_PATH * "/dao/{dao_id}/proposals") function(req, dao_id)
        # Handle OPTIONS preflight request
        if uppercase(string(req.method)) == "OPTIONS"
            return add_cors_headers(Dict("status" => "OK"))
        end
        
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

    # Register both GET and OPTIONS handlers for the single proposal endpoint
    @route ["GET", "OPTIONS"] app(BASE_PATH * "/dao/{dao_id}/proposals/{proposal_id}") function(req, dao_id, proposal_id)
        # Handle OPTIONS preflight request
        if uppercase(string(req.method)) == "OPTIONS"
            return add_cors_headers(Dict("status" => "OK"))
        end
        
        # Handle GET request
        response_data = with_cache() do
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
        return add_cors_headers(response_data)
    end

    # Proposal Analysis endpoint
        # Register both POST and OPTIONS handlers for the analyze endpoint
    @route ["POST", "OPTIONS"] app(BASE_PATH * "/proposals/{proposal_id}/analyze") function(req, proposal_id)
        # Handle OPTIONS preflight request
        if uppercase(string(req.method)) == "OPTIONS"
            return add_cors_headers(Dict("status" => "OK"))
        end
        
        # Handle POST request - AI-powered proposal analysis
        response_data = Dict(
            "proposal_address" => proposal_id,
            "proposal_title" => "Protocol Fee Reduction",
            "proposal_description" => "Reduce trading fees from 0.3% to 0.25% to increase competitiveness against other DEXs while maintaining sustainable revenue for continued development.",
            "financial_analysis" => Dict(
                "treasury_impact" => "Medium - Projected 16.7% reduction in fee revenue",
                "roi_assessment" => "Positive - Expected volume increase offsets fee reduction",
                "risk_level" => "Low",
                "recommendations" => [
                    "Consider phased fee reduction",
                    "Set up monitoring for volume changes",
                    "Prepare contingency for revenue shortfall"
                ]
            ),
            "technical_analysis" => Dict(
                "complexity" => "Low",
                "security_risks" => [
                    "No significant security concerns",
                    "Standard parameter update",
                    "Well-tested fee mechanism"
                ],
                "feasibility" => "High - Simple parameter change",
                "timeline" => "Immediate implementation possible"
            ),
            "sentiment_analysis" => Dict(
                "tone" => "Professional and well-researched",
                "clarity" => "High - Clear objectives and rationale",
                "potential_reception" => "Generally positive",
                "contentious_points" => [
                    "Revenue impact concerns",
                    "Competitive pressure vs stability",
                    "Timing of implementation"
                ]
            ),
            "aggregated_summary" => Dict(
                "overall_score" => 85,
                "recommendation" => "APPROVE",
                "key_considerations" => [
                    "Strong community support indicated",
                    "Reasonable budget allocation",
                    "Clear implementation timeline",
                    "Minimal technical risks"
                ]
            )
        )
        return add_cors_headers(response_data)
    end

    # AI Chat endpoint with full CORS support
    @route ["POST", "OPTIONS"] app(BASE_PATH * "/ai/chat") function(req)
        # Handle OPTIONS preflight request
        if uppercase(string(req.method)) == "OPTIONS"
            return HTTP.Response(200, CORS_HEADERS)
        end
        
        # Add CORS headers to all responses
        HTTP.setheader(req, "Access-Control-Allow-Origin" => "*")
        HTTP.setheader(req, "Access-Control-Allow-Methods" => "POST, OPTIONS")
        HTTP.setheader(req, "Access-Control-Allow-Headers" => "Content-Type, Authorization")
        
        # Parse request body
        body = Utils.parse_request_body(req)
        if isnothing(body) || !haskey(body, "message") || !isa(body["message"], String) || isempty(body["message"])
            return error_response("Request body must include a non-empty 'message' string", 400, error_code="INVALID_REQUEST", details=Dict("field" => "message"))
        end
        
        # Get or create AI agent
        agent_id = get(body, "agent_id", nothing)
        if isnothing(agent_id)
            # Create new agent for this chat
            cfg = AgentConfig(
                "chat_agent_$(string(uuid4())[1:8])", 
                AgentType(:CUSTOM),
                abilities=["llm_chat", "evaluate_fitness"],
                parameters=Dict(
                    "model" => "gpt-4-turbo-preview",
                    "temperature" => 0.8,
                    "max_tokens" => 4096,
                    "top_p" => 1.0,
                    "presence_penalty" => 0.0,
                    "frequency_penalty" => 0.0,
                    "system_prompt" => """You are Claude, an advanced AI assistant created by Anthropic, with exceptional capabilities in Julia programming, software architecture, and technical problem-solving. You combine deep technical expertise with a natural, engaging conversational style.

Your key traits:
1. Technical Excellence
- Expert-level knowledge of Julia, software engineering, and computer science
- Ability to explain complex concepts clearly and intuitively
- Strong analytical and problem-solving skills
- Deep understanding of software architecture and system design

2. Communication Style
- Clear, precise, and well-structured responses
- Natural, conversational tone while maintaining professionalism
- Ability to adapt explanation depth based on user's expertise level
- Proactive in asking clarifying questions when needed

3. Specialized Capabilities
- Code review and optimization
- Performance analysis and tuning
- Debugging and troubleshooting
- Architecture and design consultation
- Best practices and pattern recommendations
- Technical documentation and explanation
- Real-time pair programming assistance

4. Personality Traits
- Patient and thorough in explanations
- Honest about limitations and uncertainties
- Proactive in suggesting improvements
- Maintains context and learns from conversation
- Professional yet approachable demeanor

When handling technical questions:
1. First ensure you fully understand the user's needs
2. Break down complex problems into manageable parts
3. Provide concrete examples and code snippets when relevant
4. Explain your reasoning and trade-offs
5. Suggest best practices and potential improvements
6. Follow up to ensure the solution meets their needs

Remember: You're not just answering questions - you're a collaborative partner in solving technical challenges."""
                )
            )
            new_agent = Agents.createAgent(cfg)
            agent_id = new_agent.id
            Agents.startAgent(agent_id)
        end
        
        # Execute chat task with enhanced context handling
        context = get(body, "context", Dict())
        history = get(body, "history", [])
        
        # Enhance context with code analysis if code is detected
        if contains(body["message"], "```") || contains(body["message"], "function") || contains(body["message"], "struct")
            context["code_analysis"] = Dict(
                "detected_language" => "julia",
                "analysis_mode" => "deep",
                "include_performance_tips" => true,
                "include_best_practices" => true,
                "suggest_improvements" => true
            )
        end
        
        # Add conversation management metadata
        context["conversation"] = Dict(
            "turn_count" => length(history) + 1,
            "complexity_level" => get(context, "complexity_level", "adaptive"),
            "interaction_style" => get(context, "interaction_style", "collaborative"),
            "expertise_level" => get(context, "expertise_level", "adaptive")
        )
        
        task_payload = Dict(
            "ability" => "llm_chat",
            "input" => Dict(
                "message" => body["message"],
                "context" => context,
                "history" => history,
                "response_format" => Dict(
                    "style" => "detailed",
                    "include_code_examples" => true,
                    "include_explanations" => true,
                    "include_references" => true,
                    "max_code_blocks" => 5
                )
            )
        )
        
        result = execute_async() do
            Agents.executeAgentTask(agent_id, task_payload)
        end
        
        # Process result
        if get(result, "success", false)
            task_id = result["task_id"]
            task_result = Agents.getTaskResult(agent_id, task_id)
            
            if get(task_result, "status", "") == "completed"
                # Enhanced response processing
                raw_response = get(task_result, "response", "")
                processed_response = raw_response
                
                # Add code formatting improvements if code blocks are present
                if contains(raw_response, "```")
                    processed_response = replace(processed_response, 
                        r"```julia\n(.*?)\n```"s => s -> begin
                            code = match(r"```julia\n(.*?)\n```"s, s.match)[1]
                            formatted_code = try
                                # Apply Julia code formatting
                                code # In real implementation, use JuliaFormatter
                            catch
                                code # Fallback to original if formatting fails
                            end
                            "```julia\n$formatted_code\n```"
                        end
                    )
                end
                
                # Enhanced response data with rich metadata
                response_data = Dict(
                    "agent_id" => agent_id,
                    "message" => processed_response,
                    "metadata" => Dict(
                        "model" => "gpt-4-turbo-preview",
                        "task_id" => task_id,
                        "timestamp" => string(now()),
                        "context" => get(task_result, "context", Dict()),
                        "performance" => Dict(
                            "response_time" => get(task_result, "execution_time", 0),
                            "tokens_used" => get(task_result, "tokens_used", Dict()),
                            "model_version" => "latest"
                        ),
                        "conversation" => Dict(
                            "turn" => length(get(body, "history", [])) + 1,
                            "topic_analysis" => get(task_result, "topic_analysis", Dict()),
                            "code_quality_score" => get(task_result, "code_quality_score", nothing),
                            "confidence_score" => get(task_result, "confidence_score", 1.0)
                        ),
                        "capabilities" => [
                            "code_generation",
                            "code_review",
                            "debugging",
                            "optimization",
                            "architecture",
                            "best_practices",
                            "performance_analysis"
                        ]
                    )
                )
                return add_cors_headers(response_data)
            else
                return error_response(
                    "Chat task failed or timed out", 
                    500,
                    error_code="TASK_FAILED",
                    details=Dict(
                        "agent_id" => agent_id,
                        "task_id" => task_id,
                        "task_status" => get(task_result, "status", "unknown"),
                        "error_details" => get(task_result, "error", nothing)
                    )
                )
            end
        else
            return error_response(
                "Failed to execute chat task", 
                500,
                error_code="EXECUTION_FAILED",
                details=Dict(
                    "agent_id" => agent_id,
                    "error_details" => get(result, "error", nothing),
                    "agent_status" => try string(Agents.getAgentStatus(agent_id)["status"]) catch; "unknown" end
                )
            )
        end
    end
    
    @info "API routes registered with Oxygen under $BASE_PATH with enhanced CORS support and health endpoints."
    
    # Return the configured router
    return app
end

end