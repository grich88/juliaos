# src/agents/core/mod.jl

"""
Core module for the Agent system.
"""
module Core

using Base.Threads
using Dates

# Import local modules
include("types.jl")
include("config.jl")
include("agent.jl")

# Re-export types and functions
export AgentStatus, TaskStatus, Schedule, Skill, SkillState, TaskResult,
       AgentConfig, Agent, register_ability, create_agent,
       AGENTS, AGENT_THREADS, ABILITY_REGISTRY, AGENTS_LOCK

end # module