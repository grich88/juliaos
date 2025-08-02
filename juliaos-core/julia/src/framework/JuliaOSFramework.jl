# julia/src/framework/JuliaOSFramework.jl
module JuliaOSFramework

using Logging

export initialize, Config, Types, AgentTypes, AgentMemory, AgentQueue, LLMIntegration,
       AgentCore, AgentMetrics, LeverageSystem, Monitoring, Persistence, Agents, AgentMonitor,
       AgentLoop, AgentLifecycle, AgentTasks, PlanAndExecute, SwarmBase, Swarms

# --- Minimal Core Includes for Fast Startup ---
# Only load essential modules needed for server to start
try
    # 1. Basic Configuration Module - No dependencies
    include("../agents/Config.jl")

    # 2. Core Types only - skip heavy modules for now
    include("../agents/types.jl")         # No dependencies
    
    @info "JuliaOSFramework: Agent modules included and using'd successfully."
catch e
    @error "Failed to include agent modules" exception=(e, catch_backtrace())
end

# Lazy loading functions for heavy modules
function load_full_agents()
    @eval begin
        include("../agents/AgentTypes.jl")    
        include("../agents/AgentMemory.jl")   
        include("../agents/AgentQueue.jl")    
        include("../agents/LLMIntegration.jl")
        include("../agents/AgentCore.jl")     
        include("../agents/AgentMetrics.jl")  
        include("../agents/Monitoring.jl")      
        include("../agents/Persistence.jl")     
        include("../agents/Agents.jl")
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