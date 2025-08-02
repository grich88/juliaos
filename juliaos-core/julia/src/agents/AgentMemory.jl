# src/agents/AgentMemory.jl

"""
Memory management for Agents.
"""
module AgentMemory

using ..types: AbstractAgentMemory

# Memory implementations
struct SimpleMemory <: AbstractAgentMemory
    data::Dict{String, Any}
end

# Export types and functions
export SimpleMemory

end # module