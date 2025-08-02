# src/agents/tasks/monitored_tasks.jl

"""
Task execution with integrated monitoring.
"""
module MonitoredTasks

using Base.Threads
using Dates
using UUIDs
using ..Core
using ..Monitoring

# Execute a task with monitoring
function execute_monitored_task(id::String, task::Dict{String,Any})::Dict{String, Any}
    task_id = string(uuid4())
    span = start_span("execute_task",
        attributes=Dict(
            "agent_id" => id,
            "task_id" => task_id,
            "ability" => get(task, "ability", "unknown")
        ))
    
    start_time = now()
    
    try
        ag = Core.getAgent(id)
        if ag === nothing
            add_span_event(span, "agent_not_found")
            return Dict(
                "success" => false,
                "error" => "Agent not found",
                "task_id" => task_id
            )
        end

        # Record task metrics
        record_metric(id, "tasks_received", 1,
            type=COUNTER,
            tags=Dict("ability" => get(task, "ability", "unknown")))

        # Record queue metrics if queued mode
        if get(task, "mode", "direct") == "queue"
            record_metric(id, "queue_size",
                length(ag.queue),
                type=GAUGE)
        end

        # Execute task
        result = Core.executeAgentTask(id, task)
        
        # Record execution time
        execution_time = (now() - start_time).value / 1000.0
        record_metric(id, "task_execution_time",
            execution_time,
            type=TIMER,
            tags=Dict("ability" => get(task, "ability", "unknown")))

        # Record success/failure metrics
        if get(result, "success", false)
            add_span_event(span, "task_completed")
            record_metric(id, "tasks_completed", 1,
                type=COUNTER,
                tags=Dict("ability" => get(task, "ability", "unknown")))
        else
            add_span_event(span, "task_failed",
                attributes=Dict("error" => get(result, "error", "unknown error")))
            record_metric(id, "tasks_failed", 1,
                type=COUNTER,
                tags=Dict("ability" => get(task, "ability", "unknown")))
        end

        return result
    catch e
        add_span_event(span, "execution_error",
            attributes=Dict("error" => string(e)))
        record_metric(id, "task_errors", 1,
            type=COUNTER,
            tags=Dict("ability" => get(task, "ability", "unknown")))
        return Dict(
            "success" => false,
            "error" => string(e),
            "task_id" => task_id
        )
    finally
        end_span(span)
    end
end

# Get task status with monitoring
function get_monitored_task_status(id::String, task_id::String)::Dict{String, Any}
    span = start_span("get_task_status",
        attributes=Dict(
            "agent_id" => id,
            "task_id" => task_id
        ))
    
    try
        result = Core.getTaskStatus(id, task_id)
        
        if haskey(result, "error")
            add_span_event(span, "status_error",
                attributes=Dict("error" => result["error"]))
        else
            add_span_event(span, "status_retrieved",
                attributes=Dict("status" => get(result, "status", "unknown")))
        end

        return result
    catch e
        add_span_event(span, "retrieval_error",
            attributes=Dict("error" => string(e)))
        return Dict(
            "status" => "error",
            "error" => string(e)
        )
    finally
        end_span(span)
    end
end

# Cancel task with monitoring
function cancel_monitored_task(id::String, task_id::String)::Dict{String, Any}
    span = start_span("cancel_task",
        attributes=Dict(
            "agent_id" => id,
            "task_id" => task_id
        ))
    
    try
        result = Core.cancelTask(id, task_id)
        
        if get(result, "success", false)
            add_span_event(span, "task_cancelled")
            record_metric(id, "tasks_cancelled", 1, type=COUNTER)
        else
            add_span_event(span, "cancel_failed",
                attributes=Dict("error" => get(result, "error", "unknown error")))
            record_metric(id, "task_cancel_failures", 1, type=COUNTER)
        end

        return result
    catch e
        add_span_event(span, "cancel_error",
            attributes=Dict("error" => string(e)))
        record_metric(id, "task_errors", 1, type=COUNTER)
        return Dict(
            "success" => false,
            "error" => string(e)
        )
    finally
        end_span(span)
    end
end

# List tasks with monitoring
function list_monitored_tasks(id::String;
                            status_filter::Union{TaskStatus, Nothing}=nothing,
                            limit::Int=100)::Dict{String, Any}
    span = start_span("list_tasks",
        attributes=Dict(
            "agent_id" => id,
            "status_filter" => status_filter === nothing ? "none" : string(status_filter),
            "limit" => limit
        ))
    
    try
        result = Core.listAgentTasks(id, status_filter=status_filter, limit=limit)
        
        if haskey(result, "error")
            add_span_event(span, "list_error",
                attributes=Dict("error" => result["error"]))
        else
            add_span_event(span, "tasks_listed",
                attributes=Dict("count" => get(result, "count", 0)))
        end

        return result
    catch e
        add_span_event(span, "list_error",
            attributes=Dict("error" => string(e)))
        return Dict(
            "status" => "error",
            "error" => string(e)
        )
    finally
        end_span(span)
    end
end

# Export monitored functions
export execute_monitored_task, get_monitored_task_status,
       cancel_monitored_task, list_monitored_tasks

end # module