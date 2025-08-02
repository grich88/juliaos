# src/agents/AgentQueue.jl

"""
Queue management for Agents.
"""
module AgentQueue

using ..Types: AbstractAgentQueue

# Queue implementations
struct SimpleQueue <: AbstractAgentQueue
    tasks::Vector{Dict{String, Any}}
end

# Export types and functions
export SimpleQueue

end # module