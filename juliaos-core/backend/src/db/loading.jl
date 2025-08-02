using LibPQ, JSON3, SQLStrings, Base.Threads
using ..Agents: string_to_agent_state, string_to_trigger_type, trigger_type_to_params_type, create_agent, set_agent_state
using ..Agents.CommonTypes: TriggerParams, TriggerConfig, AgentBlueprint, ToolBlueprint, StrategyBlueprint, CREATED_STATE

# Cache configuration
const CACHE_TTL = 300  # 5 minutes
const AGENT_CACHE = Dict{String, Tuple{Agent, Float64}}()  # {agent_id => (agent, timestamp)}
const TOOLS_CACHE = Dict{String, Tuple{Vector{ToolBlueprint}, Float64}}()  # {agent_id => (tools, timestamp)}
const CACHE_LOCK = ReentrantLock()

"""
Load all agents from the database with caching and parallel processing.
"""
function load_state()
    conn = get_connection()
    try
        _load_agents(conn)
    finally
        release_connection(conn)
    end
end

"""
Load agents in parallel with caching.
"""
function _load_agents(conn::LibPQ.Connection)
    # Get all agent IDs first
    query = SQLStrings.sql`
        SELECT id FROM agents
    `
    result = LibPQ.execute(conn, query)
    agent_ids = [row.id for row in result]
    
    # Process agents in parallel
    agents = Vector{Union{Agent, Nothing}}(nothing, length(agent_ids))
    
    @threads for i in 1:length(agent_ids)
        agent_id = agent_ids[i]
        
        # Check cache first
        cached_agent = get_cached_agent(agent_id)
        if cached_agent !== nothing
            agents[i] = cached_agent
            continue
        end
        
        # Load from database if not in cache
        try
            agents[i] = _load_single_agent(conn, agent_id)
        catch e
            @error "Failed to load agent $agent_id" exception=e
            agents[i] = nothing
        end
    end
    
    # Filter out failed loads and return successful ones
    return filter(a -> a !== nothing, agents)
end

"""
Load a single agent with its tools.
"""
function _load_single_agent(conn::LibPQ.Connection, agent_id::String)
    query = SQLStrings.sql`
        SELECT id, name, description, strategy, strategy_config, trigger_type, trigger_params, state
        FROM agents
        WHERE id = $agent_id
    `
    result = LibPQ.execute(conn, query)
    
    if LibPQ.num_rows(result) == 0
        return nothing
    end
    
    row = first(result)
    
    # Parse agent data
    agent_name = row.name
    agent_description = row.description
    strategy_name = row.strategy
    strategy_config = JSON3.read(row.strategy_config, Dict{String, Any})
    trigger_type = string_to_trigger_type(row.trigger_type)
    trigger_params_type = trigger_type_to_params_type(trigger_type)
    trigger_params = trigger_params_type(; JSON3.read(row.trigger_params)...)
    agent_state = string_to_agent_state(row.state)
    
    # Load tools with caching
    tools = _load_agent_tools(conn, agent_id)
    
    # Create agent blueprint
    agent_blueprint = AgentBlueprint(
        tools,
        StrategyBlueprint(strategy_name, strategy_config),
        TriggerConfig(trigger_type, trigger_params)
    )
    
    # Create and configure agent
    agent = create_agent(
        agent_id,
        agent_name,
        agent_description,
        agent_blueprint
    )
    
    if agent_state != CREATED_STATE
        set_agent_state(agent, agent_state)
    end
    
    # Cache the agent
    cache_agent(agent)
    
    return agent
end

"""
Load agent tools with caching.
"""
function _load_agent_tools(conn::LibPQ.Connection, agent_id::String)
    # Check cache first
    cached_tools = get_cached_tools(agent_id)
    if cached_tools !== nothing
        return cached_tools
    end
    
    # Load from database if not in cache
    query = SQLStrings.sql`
        SELECT tool_index, tool_name, tool_config
        FROM agent_tools
        WHERE agent_id = $agent_id
        ORDER BY tool_index
    `
    result = LibPQ.execute(conn, query)
    
    tools = Vector{ToolBlueprint}()
    for row in result
        name = row.tool_name
        config = JSON3.read(row.tool_config, Dict{String, Any})
        push!(tools, ToolBlueprint(name, config))
    end
    
    # Cache the tools
    cache_tools(agent_id, tools)
    
    return tools
end

"""
Get agent from cache if available and not expired.
"""
function get_cached_agent(agent_id::String)
    lock(CACHE_LOCK) do
        if haskey(AGENT_CACHE, agent_id)
            agent, timestamp = AGENT_CACHE[agent_id]
            if time() - timestamp < CACHE_TTL
                return agent
            end
            delete!(AGENT_CACHE, agent_id)
        end
        return nothing
    end
end

"""
Cache an agent.
"""
function cache_agent(agent::Agent)
    lock(CACHE_LOCK) do
        AGENT_CACHE[agent.id] = (agent, time())
    end
end

"""
Get tools from cache if available and not expired.
"""
function get_cached_tools(agent_id::String)
    lock(CACHE_LOCK) do
        if haskey(TOOLS_CACHE, agent_id)
            tools, timestamp = TOOLS_CACHE[agent_id]
            if time() - timestamp < CACHE_TTL
                return tools
            end
            delete!(TOOLS_CACHE, agent_id)
        end
        return nothing
    end
end

"""
Cache agent tools.
"""
function cache_tools(agent_id::String, tools::Vector{ToolBlueprint})
    lock(CACHE_LOCK) do
        TOOLS_CACHE[agent_id] = (tools, time())
    end
end

"""
Clear all caches.
"""
function clear_caches()
    lock(CACHE_LOCK) do
        empty!(AGENT_CACHE)
        empty!(TOOLS_CACHE)
    end
end