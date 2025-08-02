# src/agents/AgentLoop.jl

"""
Core agent execution loop and task processing.
"""
module AgentLoop

using Base.Threads
using Dates
using ..AgentTypes
using ..AgentCore
using ..AgentMetrics

# Process a skill for an agent
function process_skill!(ag::Agent, sstate::SkillState)
    sstate.xp *= Config.get_config("agent.xp_decay_rate", 0.999)
    sk = sstate.skill

    if sk.schedule !== nothing
        should_run = false
        current_time = now()

        if sk.schedule.type == :periodic
            diff = current_time - sstate.last_exec
            if diff >= Millisecond(round(Int, sk.schedule.value * 1000)) - Millisecond(10)
                should_run = true
            end
        elseif sk.schedule.type == :once
            if sstate.last_exec == DateTime(0) && current_time >= sk.schedule.value
                should_run = true
            end
        elseif sk.schedule.type == :cron
            if isa(sk.schedule.value, String)
                try
                    if Cron.isdue(sk.schedule.value, sstate.last_exec)
                        should_run = true
                    end
                catch e
                    @error "Error in cron schedule for skill '$(sk.name)'" exception=e
                    should_run = false
                end
            else
                @warn "Invalid cron schedule for skill '$(sk.name)'"
                should_run = false
            end
        end

        if should_run
            try
                @debug "Running scheduled skill '$(sk.name)' for agent $(ag.name)"
                sk.fn(ag)
                sstate.xp += 1
                ag.last_activity = now()
                AgentMetrics.record_metric(ag.id, "skills_executed", 1,
                    type=AgentMetrics.COUNTER,
                    tags=Dict("skill_name" => sk.name))
            catch e
                sstate.xp -= 2
                @error "Skill $(sk.name) error in agent $(ag.name)" exception=e
                AgentMetrics.record_metric(ag.id, "skill_errors", 1,
                    type=AgentMetrics.COUNTER,
                    tags=Dict("skill_name" => sk.name))
            end
            sstate.last_exec = current_time
        end
    end
end

# Main agent execution loop
function run_agent_loop(ag::Agent)
    @info "Agent loop started for $(ag.name) ($(ag.id))"
    try
        while true
            lock(ag.lock)
            try
                if ag.status == STOPPED || ag.status == ERROR
                    break
                end
            finally
                unlock(ag.lock)
            end

            work_done = false

            lock(ag.lock) do
                if ag.status == PAUSED
                    @debug "Agent $(ag.name) is paused. Waiting..."
                    ag.last_activity = now()
                    unlock(ag.lock)
                    wait(ag.condition)
                    lock(ag.lock)
                    @debug "Agent $(ag.name) woke up."
                    return
                end

                # Process scheduled skills
                for skill_name in collect(keys(ag.skills))
                    sstate = get(ag.skills, skill_name, nothing)
                    sstate === nothing && continue
                    process_skill!(ag, sstate)
                end

                # Process queued tasks
                if !isempty(ag.queue)
                    work_done = true
                    @debug "Processing queue for agent $(ag.name). Size: $(length(ag.queue))"
                    
                    task_id = dequeue!(ag.queue)
                    task_result = get(ag.task_results, task_id, nothing)
                    
                    if task_result === nothing
                        @warn "Missing task result for ID $task_id"
                        AgentMetrics.record_metric(ag.id, "queue_invalid_items", 1,
                            type=AgentMetrics.COUNTER)
                        return
                    end

                    if task_result.status == TASK_CANCELLED
                        @debug "Task $task_id was cancelled"
                        AgentMetrics.record_metric(ag.id, "tasks_cancelled", 1,
                            type=AgentMetrics.COUNTER)
                        return
                    end

                    task_result.status = TASK_RUNNING
                    task_result.start_time = now()
                    task = task_result.input_task

                    ability_name = get(task, "ability", "")
                    if !isempty(ability_name)
                        f = get(ABILITY_REGISTRY, ability_name, nothing)
                        if f !== nothing
                            try
                                @debug "Executing queued ability '$ability_name'"
                                output = f(ag, task)
                                task_result.status = TASK_COMPLETED
                                task_result.end_time = now()
                                task_result.output_result = output
                                ag.last_activity = now()

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

                                AgentMetrics.record_metric(ag.id, "tasks_executed_queued", 1,
                                    type=AgentMetrics.COUNTER,
                                    tags=Dict("ability_name" => ability_name))

                            catch e
                                @error "Error executing queued ability" exception=e
                                task_result.status = TASK_FAILED
                                task_result.end_time = now()
                                task_result.error_details = e

                                ag.status = ERROR
                                ag.updated = now()
                                ag.last_error = e
                                ag.last_error_timestamp = now()

                                AgentMetrics.record_metric(ag.id, "task_errors_queued", 1,
                                    type=AgentMetrics.COUNTER,
                                    tags=Dict("ability_name" => ability_name))
                            end
                        else
                            @warn "Unknown ability '$ability_name' in task $task_id"
                            task_result.status = TASK_FAILED
                            task_result.end_time = now()
                            task_result.error_details = ErrorException("Unknown ability")
                            AgentMetrics.record_metric(ag.id, "task_errors_queued", 1,
                                type=AgentMetrics.COUNTER,
                                tags=Dict("error_type" => "unknown_ability"))
                        end
                    else
                        @warn "Task $task_id has no ability specified"
                        task_result.status = TASK_FAILED
                        task_result.end_time = now()
                        task_result.error_details = ErrorException("No ability specified")
                        AgentMetrics.record_metric(ag.id, "task_errors_queued", 1,
                            type=AgentMetrics.COUNTER,
                            tags=Dict("error_type" => "missing_ability"))
                    end
                end

                if !work_done
                    @debug "Agent $(ag.name) idle. Waiting..."
                    ag.last_activity = now()
                    unlock(ag.lock)
                    wait(ag.condition)
                    lock(ag.lock)
                    @debug "Agent $(ag.name) woke up."
                else
                    yield()
                end
            end
        end

    catch e
        lock(ag.lock) do
            ag.status = ERROR
            ag.updated = now()
            ag.last_error = e
            ag.last_error_timestamp = now()
            @error "Agent $(ag.name) loop crashed!" exception=e
        end
    finally
        lock(ag.lock) do
            if ag.status != STOPPED && ag.status != ERROR
                ag.status = STOPPED
                ag.updated = now()
                @info "Agent loop finished for $(ag.name). Setting status to STOPPED."
            else
                @info "Agent loop finished for $(ag.name). Final status: $(ag.status)."
            end
            ag.last_activity = now()
        end

        lock(AGENTS_LOCK) do
            haskey(AGENT_THREADS, ag.id) && delete!(AGENT_THREADS, ag.id)
            Persistence._save_state()
        end

        handle_auto_restart(ag)
    end
end

# Handle auto-restart of failed agents
function handle_auto_restart(ag::Agent)
    should_restart = false
    lock(ag.lock) do
        if Config.get_config("agent.auto_restart", false) && ag.status == ERROR
            should_restart = true
        end
    end

    if should_restart
        @warn "Agent $(ag.name) ended in ERROR state. Attempting auto-restart..."
        sleep(Config.get_config("agent.auto_restart_delay_seconds", 5))

        lock(ag.lock) do
            ag.last_error = nothing
            ag.last_error_timestamp = nothing
        end

        @async begin
            try
                success = startAgent(ag.id)
                if success
                    @info "Agent $(ag.name) auto-restarted successfully."
                else
                    @error "Agent $(ag.name) auto-restart failed."
                end
            catch e
                @error "Error during auto-restart" exception=e
                lock(ag.lock) do
                    ag.status = ERROR
                    ag.last_error = e
                    ag.last_error_timestamp = now()
                end
                lock(AGENTS_LOCK) do
                    Persistence._save_state()
                end
            end
        end
    end
end

# Export functions
export run_agent_loop, process_skill!, handle_auto_restart

end # module