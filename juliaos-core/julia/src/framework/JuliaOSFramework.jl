# julia/src/framework/JuliaOSFramework.jl
module JuliaOSFramework

using Logging

export initialize, Config, Types, AgentTypes, AgentMemory, AgentQueue, LLMIntegration,
       AgentCore, AgentMetrics, LeverageSystem, Monitoring, Persistence, Agents, AgentMonitor,
       AgentLoop, AgentLifecycle, AgentTasks, PlanAndExecute, SwarmBase, Swarms

# --- Include Core Agent Modules ---
# Paths are relative to this file (julia/src/framework/)
# going up to julia/src/ then down to the specific module directory
try
    # 1. Basic Configuration Module - No dependencies
    include("../agents/Config.jl")

    # 2. Core Modules - Depend on Config
    include("../agents/types.jl")         # No dependencies
    include("../agents/AgentTypes.jl")    # Depends on Types
    include("../agents/AgentMemory.jl")   # Depends on Types
    include("../agents/AgentQueue.jl")    # Depends on Types
    include("../agents/LLMIntegration.jl")# Depends on Types
    include("../agents/AgentCore.jl")     # Depends on Types, AgentTypes, AgentMemory, AgentQueue, LLMIntegration
    include("../agents/AgentMetrics.jl")  # Depends on Config, AgentCore

    # 3. Feature Modules - Depend on basic modules
    include("../leverage/LeverageSystem.jl") # Load Leverage system first
    include("../agents/Monitoring.jl")      # No dependencies
    include("../agents/Persistence.jl")     # Depends on Config, AgentMetrics
    include("../agents/Agents.jl")          # Depends on Config, AgentMetrics, LLMIntegration, Persistence
    include("../agents/AgentMonitor.jl")    # Depends on Config, AgentMetrics, Agents

    # 4. Advanced Agent Modules - Depend on Agents
    include("../agents/AgentLoop.jl")
    include("../agents/AgentLifecycle.jl")
    include("../agents/AgentTasks.jl")
    include("../agents/PlanAndExecute.jl")
    
    # Make Agent modules available in the same order as includes
    using .Config
    using .types
    using .AgentTypes
    using .AgentMemory
    using .AgentQueue
    using .LLMIntegration
    using .AgentCore
    using .AgentMetrics
    using .LeverageSystem
    using .Monitoring
    using .Persistence
    using .Agents
    using .AgentMonitor
    using .AgentLoop
    using .AgentLifecycle
    using .AgentTasks
    using .PlanAndExecute
    @info "JuliaOSFramework: Agent modules included and using'd successfully."
catch e
    @error "JuliaOSFramework: Critical error including Agent modules." exception=(e, catch_backtrace())
end

# --- Include Core Swarm Modules ---
try
    include("../swarm/SwarmBase.jl")
    include("../swarm/Swarms.jl")

    # Make Swarm modules available
    using .SwarmBase
    using .Swarms
    @info "JuliaOSFramework: Swarm modules included and using'd successfully."
catch e
    @error "JuliaOSFramework: Critical error including Swarm modules." exception=(e, catch_backtrace())
end

"""
    initialize(; storage_path::String)

Initialize the JuliaOS Framework backend components.
This function will call initialization routines for all included modules.
"""
function initialize(; storage_path::String="default_storage_path_from_framework") # storage_path might be used by multiple modules
    @info "Initializing JuliaOSFramework..."
    
    # Initialization for Agents is largely handled by their __init__ functions
    # (Config loading, Persistence loading, Monitor auto-start)
    # We might pass storage_path to a specific persistence re-init if needed,
    # but Persistence.jl already gets path from Agents.Config.
    
    # Initialization for Swarms (e.g., loading persisted state)
    # Swarms.jl also has an __init__ that calls _load_swarms_state.
    
    # If other modules need explicit initialization with parameters like storage_path,
    # they would be called here.
    # Example:
    # Blockchain.initialize(rpc_config_path="...", main_storage=storage_path)
    # DEX.initialize(dex_specific_config="...", shared_cache_path=storage_path)

    @info "JuliaOSFramework initialized."
    return true # Indicate success
end

end # module JuliaOSFramework