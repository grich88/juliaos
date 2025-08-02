using LibPQ, JSON3, SQLStrings, Base.Threads
using ..Agents: trigger_type_to_string, agent_state_to_string, Agent, AgentState

# Batch operation configuration
const MAX_BATCH_SIZE = 1000
const BATCH_LOCK = ReentrantLock()

"""
Insert an agent and its tools with optimized batching.
"""
function insert_agent(agent::Agent)
    conn = get_connection()
    try
        LibPQ.execute(conn, "BEGIN")
        try
            _insert_agent_proper(agent, conn)
            _insert_agent_tools_batch(agent, conn)
            LibPQ.execute(conn, "COMMIT")
            
            # Clear caches for this agent
            clear_agent_caches(agent.id)
        catch e
            LibPQ.execute(conn, "ROLLBACK")
            rethrow(e)
        end
    finally
        release_connection(conn)
    end
end

"""
Delete an agent with proper cleanup.
"""
function delete_agent(agent_id::String)
    conn = get_connection()
    try
        LibPQ.execute(conn, "BEGIN")
        try
            # Delete agent tools first (cascade will handle this, but explicit is better)
            tools_query = SQLStrings.sql`
                DELETE FROM agent_tools WHERE agent_id = $agent_id
            `
            LibPQ.execute(conn, tools_query)
            
            # Delete the agent
            agent_query = SQLStrings.sql`
                DELETE FROM agents WHERE id = $agent_id
            `
            LibPQ.execute(conn, agent_query)
            
            LibPQ.execute(conn, "COMMIT")
            
            # Clear caches for this agent
            clear_agent_caches(agent_id)
        catch e
            LibPQ.execute(conn, "ROLLBACK")
            rethrow(e)
        end
    finally
        release_connection(conn)
    end
end

"""
Update agent state with optimistic locking.
"""
function update_agent_state(agent_id::String, new_state::AgentState)
    conn = get_connection()
    try
        LibPQ.execute(conn, "BEGIN")
        try
            new_state_str = agent_state_to_string(new_state)
            
            # Get current state first
            current_state_query = SQLStrings.sql`
                SELECT state FROM agents WHERE id = $agent_id FOR UPDATE
            `
            result = LibPQ.execute(conn, current_state_query)
            
            if LibPQ.num_rows(result) == 0
                error("Agent not found: $agent_id")
            end
            
            # Update state
            update_query = SQLStrings.sql`
                UPDATE agents SET state = $new_state_str WHERE id = $agent_id
            `
            LibPQ.execute(conn, update_query)
            
            LibPQ.execute(conn, "COMMIT")
            
            # Clear caches for this agent
            clear_agent_caches(agent_id)
        catch e
            LibPQ.execute(conn, "ROLLBACK")
            rethrow(e)
        end
    finally
        release_connection(conn)
    end
end

"""
Insert agent with prepared statement.
"""
function _insert_agent_proper(agent::Agent, conn::LibPQ.Connection)
    # Prepare statement for better performance
    prepare_query = """
        INSERT INTO agents (
            id, name, description, strategy, strategy_config,
            trigger_type, trigger_params, state
        ) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8)
    """
    
    stmt = LibPQ.prepare(conn, prepare_query)
    
    # Execute prepared statement
    LibPQ.execute(
        stmt,
        [
            agent.id,
            agent.name,
            agent.description,
            agent.strategy.metadata.name,
            JSON3.write(struct_to_dict(agent.strategy.config)),
            trigger_type_to_string(agent.trigger.type),
            JSON3.write(struct_to_dict(agent.trigger.params)),
            agent_state_to_string(agent.state)
        ]
    )
end

"""
Insert agent tools with batching for better performance.
"""
function _insert_agent_tools_batch(agent::Agent, conn::LibPQ.Connection)
    if isempty(agent.context.tools)
        return
    end
    
    # Prepare batch insert statement
    prepare_query = """
        INSERT INTO agent_tools (agent_id, tool_index, tool_name, tool_config)
        VALUES (\$1, \$2, \$3, \$4)
    """
    
    stmt = LibPQ.prepare(conn, prepare_query)
    
    # Process tools in batches
    batch_size = min(length(agent.context.tools), MAX_BATCH_SIZE)
    for batch_start in 1:batch_size:length(agent.context.tools)
        batch_end = min(batch_start + batch_size - 1, length(agent.context.tools))
        batch = agent.context.tools[batch_start:batch_end]
        
        # Execute batch insert
        for (index, tool) in enumerate(batch, batch_start)
            LibPQ.execute(
                stmt,
                [
                    agent.id,
                    index,
                    tool.metadata.name,
                    JSON3.write(struct_to_dict(tool.config))
                ]
            )
        end
    end
end

"""
Clear caches for a specific agent.
"""
function clear_agent_caches(agent_id::String)
    lock(CACHE_LOCK) do
        delete!(AGENT_CACHE, agent_id)
        delete!(TOOLS_CACHE, agent_id)
    end
end

"""
Convert struct to dictionary for JSON serialization.
"""
function struct_to_dict(obj)
    Dict(String(name) => getfield(obj, name) for name in fieldnames(typeof(obj)))
end