# src/agents/core/config.jl

"""
Configuration types and utilities for the Agent system.
"""

# Agent Configuration
struct AgentConfig
    name::String
    type::Symbol
    abilities::Vector{String}
    chains::Vector{Dict{String, Any}}
    parameters::Dict{String, Any}
    llm_config::Dict{String, Any}
    memory_config::Dict{String, Any}
    queue_config::Dict{String, Any}
    max_task_history::Int
end

# Default configuration values
const DEFAULT_CONFIG = Dict{String, Any}(
    "agent.max_task_history" => 100,
    "agent.xp_decay_rate" => 0.999,
    "agent.default_sleep_ms" => 1000,
    "agent.paused_sleep_ms" => 500,
    "agent.auto_restart" => false,
    "agent.auto_restart_delay_seconds" => 5
)

# Configuration utilities
function get_config(key::String, default::Any=nothing)
    get(DEFAULT_CONFIG, key, default)
end