# src/agents/AgentCore.jl

"""
Core Agent functionality and state management.
"""
module AgentCore

using Base.Threads
using Dates
using UUIDs
using ..types: AbstractLLMIntegration, AbstractAgentMemory, AbstractAgentQueue
using ..AgentTypes
using ..AgentMemory
using ..AgentQueue
using ..LLMIntegration

# Global state
const AGENTS = Dict{String, Agent}()
const AGENT_THREADS = Dict{String, Task}()
const ABILITY_REGISTRY = Dict{String, Function}()
const AGENTS_LOCK = ReentrantLock()





# Ability Registration
function register_ability(name::String, fn::Function)
    lock(AGENTS_LOCK) do
        ABILITY_REGISTRY[name] = fn
        @info "Registered ability '$name'"
    end
end

# Export types and functions
export Agent, AgentConfig, register_ability,
       AGENTS, AGENT_THREADS, ABILITY_REGISTRY, AGENTS_LOCK

end # module