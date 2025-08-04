# src/agents/AgentCore.jl

"""
Core Agent functionality and state management.
"""
module AgentCore

using Base.Threads
using Dates
using UUIDs
using DataStructures: OrderedDict, PriorityQueue
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

# CUSTOM constant is now available from AgentTypes module
# const CUSTOM is imported from AgentTypes

# Define missing memory and queue implementations
struct OrderedDictAgentMemory <: AbstractAgentMemory
    data::OrderedDict{String, Any}
    capacity::Int
    OrderedDictAgentMemory(capacity::Int=1000) = new(OrderedDict{String, Any}(), capacity)
end

struct PriorityAgentQueue <: AbstractAgentQueue
    items::PriorityQueue{String, Int}
    PriorityAgentQueue() = new(PriorityQueue{String, Int}())
end

# Memory/Queue utility functions
function set_value!(memory::OrderedDictAgentMemory, key::String, value::Any)
    if length(memory.data) >= memory.capacity
        # Remove oldest item
        delete!(memory.data, first(keys(memory.data)))
    end
    memory.data[key] = value
end

function get_value(memory::OrderedDictAgentMemory, key::String)
    return get(memory.data, key, nothing)
end

function clear!(memory::OrderedDictAgentMemory)
    empty!(memory.data)
end

function clear!(queue::PriorityAgentQueue)
    empty!(queue.items)
end

# Agent status function
function getAgentStatus(agent_id::String)
    agent = get(AGENTS, agent_id, nothing)
    return agent === nothing ? nothing : agent.status
end

# Export types and functions
export Agent, AgentConfig, register_ability,
       AGENTS, AGENT_THREADS, ABILITY_REGISTRY, AGENTS_LOCK,
       OrderedDictAgentMemory, PriorityAgentQueue,
       set_value!, get_value, clear!, getAgentStatus

end # module