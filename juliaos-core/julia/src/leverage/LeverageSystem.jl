"""
Enhanced Leverage System Bridge
=============================

Julia interface to the Python-based Enhanced Leverage System.
Provides seamless integration between Julia and Python components.
"""

module LeverageSystem

using PyCall

# Initialize Python module
const leverage = PyNULL()

function __init__()
    # Delay Python import for faster startup
    # The leverage module will be imported on first use
end

function _get_leverage_module()
    if PyCall.PyNULL() == leverage
        try
            copy!(leverage, pyimport("juliaos.leverage"))
            @info "[LEVERAGE] Python module imported successfully"
        catch e
            @error "[LEVERAGE] Failed to import Python module: $e"
            rethrow(e)
        end
    end
    return leverage
end

"""
    run_intelligent_induction(project_path::String=".") -> Dict

Run complete intelligent induction process on the project.
Analyzes codebase and generates optimization strategy.
"""
function run_intelligent_induction(project_path::String=".")
    return _get_leverage_module().run_intelligent_induction(project_path)
end

"""
    quick_induction_analysis(project_path::String=".") -> Dict

Run quick automated analysis without developer consultation.
Good for CI/CD pipelines or automated checks.
"""
function quick_induction_analysis(project_path::String=".")
    return _get_leverage_module().quick_induction_analysis(project_path)
end

"""
    get_induction_recommendations(project_path::String=".") -> Vector{String}

Get quick actionable recommendations based on project analysis.
"""
function get_induction_recommendations(project_path::String=".")
    return _get_leverage_module().get_induction_recommendations(project_path)
end

"""
    health_check(project_path::String=".") -> Dict

Check system health and readiness for leverage operations.
"""
function health_check(project_path::String=".")
    return _get_leverage_module().health_check(project_path)
end

"""
    scan_my_app(project_path::String=".") -> Dict

Scan application for services and leverage opportunities.
"""
function scan_my_app(project_path::String=".")
    return _get_leverage_module().scan_my_app(project_path)
end

"""
    leverage_my_app(feature_name::String, project_path::String=".") -> Dict

Apply leverage to a specific feature with intelligent targeting.
"""
function leverage_my_app(feature_name::String, project_path::String=".")
    return _get_leverage_module().leverage_my_app(feature_name, project_path)
end

"""
    auto_leverage_everything(project_path::String=".") -> Dict

Automatically discover and leverage all opportunities.
"""
function auto_leverage_everything(project_path::String=".")
    return _get_leverage_module().auto_leverage_everything(project_path)
end

"""
    generate_leverage_report(project_path::String=".") -> String

Generate comprehensive leverage report with analysis and recommendations.
"""
function generate_leverage_report(project_path::String=".")
    return _get_leverage_module().generate_leverage_report(project_path)
end

# Context management
mutable struct LeverageContext
    initialized::Bool
    project_path::String
    health_status::Dict{String,Any}
    active_features::Vector{String}
    
    LeverageContext() = new(false, ".", Dict{String,Any}(), String[])
end

const GLOBAL_CONTEXT = LeverageContext()

"""
    initialize(project_path::String=".") -> Nothing

Initialize the Leverage system and prepare it for use.
"""
function initialize(project_path::String=".")
    if !GLOBAL_CONTEXT.initialized
        @info "[LEVERAGE] Initializing Leverage system..."
        
        # Store project path first
        GLOBAL_CONTEXT.project_path = project_path
        
        # Mark as initialized to prevent recursion
        GLOBAL_CONTEXT.initialized = true
        
        # Run health check (this may take time, so do it after marking initialized)
        try
            GLOBAL_CONTEXT.health_status = health_check(project_path)
            @info "[LEVERAGE] Universal Leverage System initialized successfully"
        catch e
            @warn "[LEVERAGE] Health check failed during initialization: $e"
            GLOBAL_CONTEXT.health_status = Dict("status" => "error", "error" => string(e))
        end
    end
    nothing
end

"""
    get_context() -> LeverageContext

Get the current Leverage system context.
"""
function get_context()
    if !GLOBAL_CONTEXT.initialized
        initialize()
    end
    return GLOBAL_CONTEXT
end

"""
    cleanup_context(ctx::LeverageContext) -> Nothing

Clean up resources associated with a specific context.
"""
function cleanup_context(ctx::LeverageContext)
    empty!(ctx.active_features)
    ctx.health_status = Dict{String,Any}()
    nothing
end

"""
    cleanup() -> Nothing

Clean up all Leverage system resources.
"""
function cleanup()
    if GLOBAL_CONTEXT.initialized
        cleanup_context(GLOBAL_CONTEXT)
        GLOBAL_CONTEXT.initialized = false
    end
    nothing
end

# Export main functions
export run_intelligent_induction,
       quick_induction_analysis,
       get_induction_recommendations,
       health_check,
       scan_my_app,
       leverage_my_app,
       auto_leverage_everything,
       generate_leverage_report,
       initialize,
       get_context,
       cleanup_context,
       cleanup,
       LeverageContext

end # module