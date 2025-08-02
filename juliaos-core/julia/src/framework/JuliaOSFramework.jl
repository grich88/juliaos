# julia/src/framework/JuliaOSFramework.jl
module JuliaOSFramework

using Logging

export initialize, Config, Types, AgentTypes, AgentMemory, AgentQueue, LLMIntegration,
       AgentCore, AgentMetrics, LeverageSystem, Monitoring, Persistence, Agents, AgentMonitor,
       AgentLoop, AgentLifecycle, AgentTasks, PlanAndExecute, SwarmBase, Swarms

# --- Core Includes for Server Startup ---
# Load essential modules needed for server to start properly
try
    # 1. Basic Configuration Module - No dependencies
    include("../agents/Config.jl")

    # 2. Core Modules - Essential for server
    include("../agents/types.jl")         # No dependencies
    include("../agents/AgentTypes.jl")    # Depends on Types
    include("../agents/AgentMemory.jl")   # Depends on Types
    include("../agents/AgentQueue.jl")    # Depends on Types
    include("../agents/LLMIntegration.jl")# Depends on Types
    include("../agents/AgentCore.jl")     # Depends on Types, AgentTypes, AgentMemory, AgentQueue, LLMIntegration
    include("../agents/AgentMetrics.jl")  # Depends on Config, AgentCore

    # 3. Make core modules available (minimal set)
    using .Config
    using .types
    using .AgentTypes
    using .AgentMemory
    using .AgentQueue
    using .LLMIntegration
    using .AgentCore
    using .AgentMetrics
    
    @info "JuliaOSFramework: Agent modules included and using'd successfully."
catch e
    @error "Failed to include agent modules" exception=(e, catch_backtrace())
end

# Lazy loading functions for heavy modules
function load_heavy_modules()
    try
        @eval begin
            # Load potentially hanging modules only when needed
            include("../leverage/LeverageSystem.jl") # PyCall can hang
            include("../agents/Monitoring.jl")      
            include("../agents/Persistence.jl")     
            include("../agents/Agents.jl")          
            include("../agents/AgentMonitor.jl")    
            include("../agents/AgentLoop.jl")
            include("../agents/AgentLifecycle.jl")
            include("../agents/AgentTasks.jl")
            include("../agents/PlanAndExecute.jl")
            
            # Make heavy modules available
            using .LeverageSystem
            using .Monitoring
            using .Persistence
            using .Agents
            using .AgentMonitor
            using .AgentLoop
            using .AgentLifecycle
            using .AgentTasks
            using .PlanAndExecute
            
            @info "JuliaOSFramework: Heavy modules loaded successfully."
        end
    catch e
        @error "JuliaOSFramework: Error loading heavy modules." exception=(e, catch_backtrace())
    end
end

# Lazy loading function for Swarm modules (also heavy)
function load_swarm_modules()
    try
        @eval begin
            include("../swarm/SwarmBase.jl")
            include("../swarm/Swarms.jl")

            # Make Swarm modules available
            using .SwarmBase
            using .Swarms
            @info "JuliaOSFramework: Swarm modules included and using'd successfully."
        end
    catch e
        @error "JuliaOSFramework: Error loading Swarm modules." exception=(e, catch_backtrace())
    end
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