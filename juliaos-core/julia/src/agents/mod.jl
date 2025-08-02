module Agents

# Include core types first
include("types.jl")
using .Types

# Include all agent-related modules in the correct order
include("AgentTypes.jl")
using .AgentTypes

include("AgentMemory.jl")
using .AgentMemory

include("AgentQueue.jl")
using .AgentQueue

include("LLMIntegration.jl")
using .LLMIntegration

include("Config.jl")
using .Config

include("AgentMetrics.jl")
using .AgentMetrics

include("AgentCore.jl")
using .AgentCore

include("AgentLoop.jl")
using .AgentLoop

include("AgentLifecycle.jl")
using .AgentLifecycle

include("AgentTasks.jl")
using .AgentTasks

include("PlanAndExecute.jl")
using .PlanAndExecute

include("Persistence.jl")
using .Persistence

include("AgentMonitor.jl")
using .AgentMonitor

# Re-export types and functions from submodules
export AbstractLLMIntegration, AbstractAgentMemory, AbstractAgentQueue,
       AgentStatus, TaskStatus, Schedule, Skill, SkillState, TaskResult,
       CREATED, INITIALIZING, RUNNING, PAUSED, STOPPED, ERROR,
       TASK_PENDING, TASK_RUNNING, TASK_COMPLETED, TASK_FAILED, TASK_CANCELLED, TASK_UNKNOWN,
       Agent, AgentConfig, register_ability,
       AGENTS, AGENT_THREADS, ABILITY_REGISTRY, AGENTS_LOCK,
       AgentMetrics, AgentMonitor

end # module