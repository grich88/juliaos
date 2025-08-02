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
    copy!(leverage, pyimport("juliaos.leverage"))
end

"""
    run_intelligent_induction(project_path::String=".") -> Dict

Run complete intelligent induction process on the project.
Analyzes codebase and generates optimization strategy.
"""
function run_intelligent_induction(project_path::String=".")
    return leverage.run_intelligent_induction(project_path)
end

"""
    quick_induction_analysis(project_path::String=".") -> Dict

Run quick automated analysis without developer consultation.
Good for CI/CD pipelines or automated checks.
"""
function quick_induction_analysis(project_path::String=".")
    return leverage.quick_induction_analysis(project_path)
end

"""
    get_induction_recommendations(project_path::String=".") -> Vector{String}

Get quick actionable recommendations based on project analysis.
"""
function get_induction_recommendations(project_path::String=".")
    return leverage.get_induction_recommendations(project_path)
end

"""
    health_check(project_path::String=".") -> Dict

Check system health and readiness for leverage operations.
"""
function health_check(project_path::String=".")
    return leverage.health_check(project_path)
end

"""
    scan_my_app(project_path::String=".") -> Dict

Scan application for services and leverage opportunities.
"""
function scan_my_app(project_path::String=".")
    return leverage.scan_my_app(project_path)
end

"""
    leverage_my_app(feature_name::String, project_path::String=".") -> Dict

Apply leverage to a specific feature with intelligent targeting.
"""
function leverage_my_app(feature_name::String, project_path::String=".")
    return leverage.leverage_my_app(feature_name, project_path)
end

"""
    auto_leverage_everything(project_path::String=".") -> Dict

Automatically discover and leverage all opportunities.
"""
function auto_leverage_everything(project_path::String=".")
    return leverage.auto_leverage_everything(project_path)
end

"""
    generate_leverage_report(project_path::String=".") -> String

Generate comprehensive leverage report with analysis and recommendations.
"""
function generate_leverage_report(project_path::String=".")
    return leverage.generate_leverage_report(project_path)
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
        # Run health check
        GLOBAL_CONTEXT.health_status = health_check(project_path)
        
        # Store project path
        GLOBAL_CONTEXT.project_path = project_path
        
        # Mark as initialized
        GLOBAL_CONTEXT.initialized = true
        
        @info "[LEVERAGE] 🚀 Universal Leverage System initialized"
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