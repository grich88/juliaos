# src/agents/core/agent.jl

"""
Core Agent type and functionality.
"""

using Base.Threads
using Dates

# Import local modules
include("types.jl")
include("config.jl")

# Agent Type
mutable struct Agent
    id::String
    name::String
    type::Symbol
    status::AgentStatus
    created::DateTime
    updated::DateTime
    config::AgentConfig
    memory::AbstractAgentMemory
    task_history::Vector{Dict{String, Any}}
    skills::Dict{String, SkillState}
    queue::AbstractAgentQueue
    task_results::Dict{String, TaskResult}
    llm_integration::Union{Nothing, AbstractLLMIntegration}
    swarm_connection::Any
    lock::ReentrantLock
    condition::Condition
    last_error::Union{Nothing, Exception}
    last_error_timestamp::Union{Nothing, DateTime}
    last_activity::DateTime
end

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

# Agent Creation Helper
function create_agent(config::AgentConfig)
    id = "agent-" * randstring(8)
    
    # Initialize components
    memory = create_memory_component(config.memory_config)
    queue = create_queue_component(config.queue_config)
    llm = create_llm_component(config.llm_config)
    
    # Initialize skills
    skills = Dict{String,SkillState}()
    for ability_name in config.abilities
        if haskey(ABILITY_REGISTRY, ability_name)
            skills[ability_name] = SkillState(
                Skill(ability_name, ABILITY_REGISTRY[ability_name], nothing),
                0.0,
                now()
            )
        end
    end
    
    # Create agent
    agent = Agent(
        id,
        config.name,
        config.type,
        CREATED,
        now(),
        now(),
        config,
        memory,
        Dict{String,Any}[],
        skills,
        queue,
        Dict{String,TaskResult}(),
        llm,
        nothing,
        ReentrantLock(),
        Condition(),
        nothing,
        nothing,
        now()
    )
    
    # Register agent
    lock(AGENTS_LOCK) do
        AGENTS[id] = agent
    end
    
    return agent
end

# Component creation helpers
function create_memory_component(config::Dict{String,Any})
    max_size = get(config, "max_size", 1000)
    return OrderedDictAgentMemory(max_size)
end

function create_queue_component(config::Dict{String,Any})
    return PriorityAgentQueue()
end

function create_llm_component(config::Dict{String,Any})
    if !haskey(config, "provider")
        config["provider"] = "openai"
    end
    return LLMIntegration.create_llm_integration(config)
end