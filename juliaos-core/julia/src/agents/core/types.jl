# src/agents/core/types.jl

"""
Core types for the Agent system.
"""

using Dates

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