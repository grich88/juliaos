# src/agents/AgentTypes.jl

"""
Core types and constants for the Agent system.
"""
module AgentTypes

using DataStructures
using Dates
using Base.Threads: ReentrantLock
using ..types: AbstractLLMIntegration, AbstractAgentMemory, AbstractAgentQueue

# Agent Type enum (must be defined before AgentConfig)
@enum AgentType begin
    BASIC
    ADVANCED
    CUSTOM
    MONITORING
    ANALYSIS
end

# Agent Configuration
struct AgentConfig
    name::String
    type::AgentType
    abilities::Vector{String}
    chains::Vector{Dict{String, Any}}
    parameters::Dict{String, Any}
    llm_config::Dict{String, Any}
    memory_config::Dict{String, Any}
    queue_config::Dict{String, Any}
    max_task_history::Int
end

# Agent Status Types
@enum AgentStatus begin
    CREATED
    INITIALIZING
    RUNNING
    PAUSED
    STOPPED
    ERROR
end

# Task Status Types
@enum TaskStatus begin
    TASK_PENDING
    TASK_RUNNING
    TASK_COMPLETED
    TASK_FAILED
    TASK_CANCELLED
    TASK_UNKNOWN
end

# Schedule Types
struct Schedule
    type::Symbol  # :periodic, :once, :cron, :event
    value::Any    # seconds for periodic, DateTime for once, string for cron, event name for event
end

# Skill Types
struct Skill
    name::String
    fn::Function
    schedule::Union{Schedule, Nothing}
end

struct SkillState
    skill::Skill
    xp::Float64
    last_exec::DateTime
end

# Task Result Type
struct TaskResult
    task_id::String
    status::TaskStatus
    submitted_time::DateTime
    start_time::Union{DateTime, Nothing}
    end_time::Union{DateTime, Nothing}
    input_task::Dict{String, Any}
    output_result::Any
    error_details::Any
end

# Constructor for TaskResult
function TaskResult(task_id::String; 
                   status::TaskStatus=TASK_PENDING,
                   submitted_time::DateTime=now(),
                   start_time::Union{DateTime, Nothing}=nothing,
                   end_time::Union{DateTime, Nothing}=nothing,
                   output_result::Any=nothing,
                   error_details::Any=nothing)
    TaskResult(task_id, status, submitted_time, start_time, end_time, Dict{String, Any}(), output_result, error_details)
end

# Export types and constants
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

# Export types and functions
export AgentType, AgentStatus, TaskStatus, Schedule, Skill, SkillState, TaskResult, Agent, AgentConfig,
       BASIC, ADVANCED, CUSTOM, MONITORING, ANALYSIS,
       CREATED, INITIALIZING, RUNNING, PAUSED, STOPPED, ERROR,
       TASK_PENDING, TASK_RUNNING, TASK_COMPLETED, TASK_FAILED, TASK_CANCELLED, TASK_UNKNOWN

end # module