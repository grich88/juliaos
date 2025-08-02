# src/agents/AgentTasks.jl

"""
Task management for Agents.
"""
module AgentTasks

using Base.Threads
using Dates
using UUIDs
using ..AgentTypes
using ..AgentCore
using ..AgentMetrics

# Execute a task for an agent
function executeAgentTask(id::String, task::Dict{String,Any})::Dict{String, Any}
    if !isa(id, AbstractString) || isempty(id)
        @warn "Invalid agent ID"
        return Dict("success"=>false, "error"=>"Invalid agent ID")
    end
    if !isa(task, Dict)
        @warn "Invalid task payload"
        return Dict("success"=>false, "error"=>"Invalid task format")
    end
    if !haskey(task, "ability") || !isa(task["ability"], AbstractString) || isempty(task["ability"])
        @warn "Missing ability in task"
        return Dict("success"=>false, "error"=>"Missing ability")
    end

    ag = getAgent(id)
    ag === nothing && return Dict("success"=>false, "error"=>"Agent not found")

    task_id = string(uuid4())
    submitted_time = now()

    task_result = TaskResult(task_id,
        status=TASK_PENDING,
        submitted_time=submitted_time)

    lock(ag.lock) do
        if ag.status != RUNNING && ag.status != PAUSED
            task_result.status = TASK_FAILED
            task_result.end_time = now()
            task_result.error_details = ErrorException("Agent not in RUNNING/PAUSED state")
            ag.task_results[task_id] = task_result
            return Dict("success"=>false, "error"=>"Agent not in correct state", "task_id"=>task_id)
        end

        ag.task_results[task_id] = task_result

        mode = get(task, "mode", "direct")
        if mode == "queue"
            prio = -float(get(task, "priority", 0.0))
            try
                enqueue!(ag.queue, task_id, prio)
                ag.last_activity = now()
                notify(ag.condition)
                AgentMetrics.record_metric(id, "tasks_queued", 1, type=AgentMetrics.COUNTER)
                return Dict("success"=>true, "queued"=>true, "task_id"=>task_id)
            catch e
                @error "Failed to enqueue task" exception=e
                task_result.status = TASK_FAILED
                task_result.end_time = now()
                task_result.error_details = e
                AgentMetrics.record_metric(id, "task_errors_enqueue", 1, type=AgentMetrics.COUNTER)
                return Dict("success"=>false, "error"=>"Failed to enqueue task", "task_id"=>task_id)
            end
        end

        if ag.status != RUNNING
            task_result.status = TASK_FAILED
            task_result.end_time = now()
            task_result.error_details = ErrorException("Agent is PAUSED")
            return Dict("success"=>false, "error"=>"Agent is PAUSED", "task_id"=>task_id)
        end

        ability_name = task["ability"]
        f = get(ABILITY_REGISTRY, ability_name, nothing)
        if f === nothing
            task_result.status = TASK_FAILED
            task_result.end_time = now()
            task_result.error_details = ErrorException("Unknown ability")
            return Dict("success"=>false, "error"=>"Unknown ability", "task_id"=>task_id)
        end

        try
            task_result.status = TASK_RUNNING
            task_result.start_time = now()

            output = f(ag, task)
            ag.last_activity = now()

            task_result.status = TASK_COMPLETED
            task_result.end_time = now()
            task_result.output_result = output

            if ag.config.max_task_history > 0
                history_entry = Dict(
                    "timestamp" => now(),
                    "task_id" => task_id,
                    "input" => task,
                    "output" => output
                )
                push!(ag.task_history, history_entry)
                while length(ag.task_history) > ag.config.max_task_history
                    popfirst!(ag.task_history)
                end
            end

            AgentMetrics.record_metric(id, "tasks_executed_direct", 1,
                type=AgentMetrics.COUNTER,
                tags=Dict("ability_name" => ability_name))

            result_data = isa(output, Dict) ? output : Dict("result" => output)
            return merge(Dict("success"=>true, "queued"=>false, "task_id"=>task_id), result_data)

        catch e
            @error "Error executing task" exception=e
            task_result.status = TASK_FAILED
            task_result.end_time = now()
            task_result.error_details = e

            ag.status = ERROR
            ag.updated = now()
            ag.last_error = e
            ag.last_error_timestamp = now()

            AgentMetrics.record_metric(id, "task_errors_direct", 1,
                type=AgentMetrics.COUNTER,
                tags=Dict("ability_name" => ability_name))

            return Dict("success"=>false, "error"=>"Execution error", "task_id"=>task_id)
        end
    end
end

# Get task status
function getTaskStatus(id::String, task_id::String)::Dict{String, Any}
    if !isa(id, AbstractString) || isempty(id)
        return Dict("status"=>"error", "error"=>"Invalid agent ID")
    end
    if !isa(task_id, AbstractString) || isempty(task_id)
        return Dict("status"=>"error", "error"=>"Invalid task ID")
    end

    ag = getAgent(id)
    ag === nothing && return Dict("status"=>"error", "error"=>"Agent not found")

    lock(ag.lock) do
        task_result = get(ag.task_results, task_id, nothing)
        if task_result === nothing
            return Dict("status"=>"error", "error"=>"Task not found")
        end

        return Dict(
            "task_id" => task_result.task_id,
            "status" => string(task_result.status),
            "submitted_time" => string(task_result.submitted_time),
            "start_time" => isnothing(task_result.start_time) ? nothing : string(task_result.start_time),
            "end_time" => isnothing(task_result.end_time) ? nothing : string(task_result.end_time),
            "ability" => get(task_result.input_task, "ability", "N/A")
        )
    end
end

# Get task result
function getTaskResult(id::String, task_id::String)::Dict{String, Any}
    if !isa(id, AbstractString) || isempty(id)
        return Dict("status"=>"error", "error"=>"Invalid agent ID")
    end
    if !isa(task_id, AbstractString) || isempty(task_id)
        return Dict("status"=>"error", "error"=>"Invalid task ID")
    end

    ag = getAgent(id)
    ag === nothing && return Dict("status"=>"error", "error"=>"Agent not found")

    lock(ag.lock) do
        task_result = get(ag.task_results, task_id, nothing)
        if task_result === nothing
            return Dict("status"=>"error", "error"=>"Task not found")
        end

        if task_result.status in (TASK_PENDING, TASK_RUNNING)
            return Dict("status"=>string(task_result.status), "message"=>"Task not completed")
        end

        result = Dict(
            "task_id" => task_result.task_id,
            "status" => string(task_result.status),
            "submitted_time" => string(task_result.submitted_time),
            "start_time" => isnothing(task_result.start_time) ? nothing : string(task_result.start_time),
            "end_time" => string(task_result.end_time),
            "input" => task_result.input_task
        )

        if task_result.status == TASK_COMPLETED
            result["result"] = task_result.output_result
        elseif task_result.status in (TASK_FAILED, TASK_CANCELLED)
            result["error"] = isnothing(task_result.error_details) ? "Unknown error" : string(task_result.error_details)
        end

        return result
    end
end

# List agent tasks
function listAgentTasks(id::String; status_filter::Union{TaskStatus, Nothing}=nothing, limit::Int=100)::Dict{String, Any}
    if !isa(id, AbstractString) || isempty(id)
        return Dict("status"=>"error", "error"=>"Invalid agent ID")
    end
    if !isa(limit, Integer) || limit < 0
        limit = 100
    end

    ag = getAgent(id)
    ag === nothing && return Dict("status"=>"error", "error"=>"Agent not found")

    lock(ag.lock) do
        tasks = collect(values(ag.task_results))
        sort!(tasks, by = t -> t.submitted_time, rev=true)

        if status_filter !== nothing
            filter!(t -> t.status == status_filter, tasks)
        end

        if length(tasks) > limit
            tasks = tasks[1:limit]
        end

        formatted_tasks = [Dict(
            "task_id" => t.task_id,
            "status" => string(t.status),
            "submitted_time" => string(t.submitted_time),
            "start_time" => isnothing(t.start_time) ? nothing : string(t.start_time),
            "end_time" => isnothing(t.end_time) ? nothing : string(t.end_time),
            "ability" => get(t.input_task, "ability", "N/A")
        ) for t in tasks]

        return Dict(
            "success" => true,
            "agent_id" => id,
            "tasks" => formatted_tasks,
            "count" => length(formatted_tasks)
        )
    end
end

# Cancel a task
function cancelTask(id::String, task_id::String)::Dict{String, Any}
    if !isa(id, AbstractString) || isempty(id)
        return Dict("success"=>false, "error"=>"Invalid agent ID")
    end
    if !isa(task_id, AbstractString) || isempty(task_id)
        return Dict("success"=>false, "error"=>"Invalid task ID")
    end

    ag = getAgent(id)
    ag === nothing && return Dict("success"=>false, "error"=>"Agent not found")

    lock(ag.lock) do
        task_result = get(ag.task_results, task_id, nothing)
        if task_result === nothing
            return Dict("success"=>false, "error"=>"Task not found")
        end

        if task_result.status in (TASK_PENDING, TASK_RUNNING)
            task_result.status = TASK_CANCELLED
            task_result.end_time = now()
            task_result.error_details = ErrorException("Task cancelled by user")
            ag.last_activity = now()
            notify(ag.condition)
            AgentMetrics.record_metric(id, "tasks_cancel_requested", 1, type=AgentMetrics.COUNTER)
            return Dict("success"=>true, "message"=>"Task cancelled")
        else
            return Dict("success"=>false, "error"=>"Task cannot be cancelled")
        end
    end
end

# Export functions
export executeAgentTask, getTaskStatus, getTaskResult, listAgentTasks, cancelTask

end # module