# src/agents/types.jl

"""
Core types and abstract types for the Agent system.
"""
module types

# Abstract types
abstract type AbstractLLMIntegration end
abstract type AbstractAgentMemory end
abstract type AbstractAgentQueue end

export AbstractLLMIntegration, AbstractAgentMemory, AbstractAgentQueue

end # module