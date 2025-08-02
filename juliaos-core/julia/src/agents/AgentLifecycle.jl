# src/agents/AgentLifecycle.jl

"""
Agent lifecycle management (start, stop, pause, resume).
"""
module AgentLifecycle

using Base.Threads
using Dates
using ..AgentTypes
using ..AgentCore
using ..AgentLoop

# Start an agent
function startAgent(id::String)::Bool
    ag = getAgent(id)
    ag === nothing && return false

    lock(ag.lock) do
        if ag.status == RUNNING
            @warn "Agent $id ($(ag.name)) is already running."
            return true
        elseif ag.status == PAUSED
            @warn "Agent $id ($(ag.name)) is paused. Use resumeAgent() to resume."
            return false
        elseif ag.status == INITIALIZING
            @warn "Agent $id ($(ag.name)) is already initializing."
            return true
        elseif ag.status == ERROR
            @warn "Agent $id ($(ag.name)) is in ERROR state. Cannot start directly."
            return false
        end

        @info "Starting agent $(ag.name) ($id)..."
        ag.status = INITIALIZING
        ag.updated = now()
        ag.last_activity = now()

        task = @task begin
            try
                lock(ag.lock) do
                    ag.status = RUNNING
                    ag.updated = now()
                    ag.last_activity = now()
                    @info "Agent $(ag.name) ($ag.id) status set to RUNNING."
                    notify(ag.condition)
                end

                AgentLoop.run_agent_loop(ag)

            catch task_err
                lock(ag.lock) do
                    ag.status = ERROR
                    ag.updated = now()
                    ag.last_error = task_err
                    ag.last_error_timestamp = now()
                    @error "Unhandled error in agent task for $id" exception=task_err
                end
            end
        end

        lock(AGENTS_LOCK) do
            AGENT_THREADS[id] = task
        end

        schedule(task)
        return true
    end
end

# Stop an agent
function stopAgent(id::String)::Bool
    ag = getAgent(id)
    ag === nothing && return true

    lock(ag.lock) do
        if ag.status == STOPPED || ag.status == ERROR
            @warn "Agent $id ($(ag.name)) is already in status $(ag.status)."
            return true
        end

        @info "Stopping agent $(ag.name) ($id)..."
        ag.status = STOPPED
        ag.updated = now()
        ag.last_activity = now()
        notify(ag.condition)

        current_task = lock(AGENTS_LOCK) do
            get(AGENT_THREADS, id, nothing)
        end

        if current_task === nothing || istaskdone(current_task)
            @warn "Agent $id status was $(ag.status), but no active task found."
            lock(AGENTS_LOCK) do
                haskey(AGENT_THREADS, id) && delete!(AGENT_THREADS, id)
            end
            return true
        end

        unlock(ag.lock)
        try
            wait(current_task)
            @info "Agent $(ag.name) ($id) task finished after stop signal."
            return true
        catch e
            @error "Error waiting for agent $id task to stop." exception=e
            lock(ag.lock) do
                ag.status = ERROR
                ag.updated = now()
                ag.last_error = e
                ag.last_error_timestamp = now()
            end
            return false
        finally
            islocked(ag.lock) || lock(ag.lock)
        end
    end
end

# Pause an agent
function pauseAgent(id::String)::Bool
    ag = getAgent(id)
    ag === nothing && return false

    lock(ag.lock) do
        if ag.status == RUNNING
            ag.status = PAUSED
            ag.updated = now()
            ag.last_activity = now()
            @info "Agent $(ag.name) ($id) paused."
            return true
        elseif ag.status == PAUSED
            @warn "Agent $(ag.name) ($id) is already paused."
            return true
        else
            @warn "Cannot pause agent $(ag.name) ($id). State: $(ag.status)."
            return false
        end
    end
end

# Resume an agent
function resumeAgent(id::String)::Bool
    ag = getAgent(id)
    ag === nothing && return false

    lock(ag.lock) do
        if ag.status == PAUSED
            ag.status = RUNNING
            ag.updated = now()
            ag.last_activity = now()
            @info "Agent $(ag.name) ($id) resumed."
            notify(ag.condition)
            return true
        elseif ag.status == RUNNING
            @warn "Agent $(ag.name) ($id) is already running."
            return true
        else
            @warn "Cannot resume agent $(ag.name) ($id). State: $(ag.status)."
            return false
        end
    end
end

# Export functions
export startAgent, stopAgent, pauseAgent, resumeAgent

end # module