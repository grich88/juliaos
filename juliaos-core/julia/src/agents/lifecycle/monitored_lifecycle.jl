# src/agents/lifecycle/monitored_lifecycle.jl

"""
Agent lifecycle management with integrated monitoring.
"""
module MonitoredLifecycle

using Base.Threads
using Dates
using ..Core
using ..Monitoring

# Start an agent with monitoring
function start_monitored_agent(id::String)::Bool
    span = start_span("agent_start",
        attributes=Dict("agent_id" => id))
    
    try
        ag = Core.getAgent(id)
        if ag === nothing
            add_span_event(span, "agent_not_found")
            return false
        end

        # Record initial metrics
        record_metric(id, "agent_starts", 1, type=COUNTER)
        record_metric(id, "memory_usage", 0, type=GAUGE)
        record_metric(id, "queue_size", 0, type=GAUGE)

        # Initial health check
        health = check_agent_health(ag)
        if health.status == UNHEALTHY
            add_span_event(span, "agent_unhealthy",
                attributes=Dict("reason" => health.message))
            return false
        end

        success = Core.startAgent(id)
        if success
            add_span_event(span, "agent_started")
            record_metric(id, "agent_status", 1,
                type=GAUGE,
                tags=Dict("status" => "running"))
        else
            add_span_event(span, "start_failed")
            record_metric(id, "agent_start_failures", 1,
                type=COUNTER)
        end

        return success
    catch e
        add_span_event(span, "start_error",
            attributes=Dict("error" => string(e)))
        record_metric(id, "agent_errors", 1, type=COUNTER)
        rethrow(e)
    finally
        end_span(span)
    end
end

# Stop an agent with monitoring
function stop_monitored_agent(id::String)::Bool
    span = start_span("agent_stop",
        attributes=Dict("agent_id" => id))
    
    try
        ag = Core.getAgent(id)
        if ag === nothing
            add_span_event(span, "agent_not_found")
            return true
        end

        # Record metrics before stopping
        record_metric(id, "agent_stops", 1, type=COUNTER)
        record_metric(id, "uptime_seconds",
            (now() - ag.created).value / 1000,
            type=GAUGE)

        success = Core.stopAgent(id)
        if success
            add_span_event(span, "agent_stopped")
            record_metric(id, "agent_status", 0,
                type=GAUGE,
                tags=Dict("status" => "stopped"))
        else
            add_span_event(span, "stop_failed")
            record_metric(id, "agent_stop_failures", 1,
                type=COUNTER)
        end

        return success
    catch e
        add_span_event(span, "stop_error",
            attributes=Dict("error" => string(e)))
        record_metric(id, "agent_errors", 1, type=COUNTER)
        rethrow(e)
    finally
        end_span(span)
    end
end

# Pause an agent with monitoring
function pause_monitored_agent(id::String)::Bool
    span = start_span("agent_pause",
        attributes=Dict("agent_id" => id))
    
    try
        ag = Core.getAgent(id)
        if ag === nothing
            add_span_event(span, "agent_not_found")
            return false
        end

        record_metric(id, "agent_pauses", 1, type=COUNTER)

        success = Core.pauseAgent(id)
        if success
            add_span_event(span, "agent_paused")
            record_metric(id, "agent_status", 2,
                type=GAUGE,
                tags=Dict("status" => "paused"))
        else
            add_span_event(span, "pause_failed")
            record_metric(id, "agent_pause_failures", 1,
                type=COUNTER)
        end

        return success
    catch e
        add_span_event(span, "pause_error",
            attributes=Dict("error" => string(e)))
        record_metric(id, "agent_errors", 1, type=COUNTER)
        rethrow(e)
    finally
        end_span(span)
    end
end

# Resume an agent with monitoring
function resume_monitored_agent(id::String)::Bool
    span = start_span("agent_resume",
        attributes=Dict("agent_id" => id))
    
    try
        ag = Core.getAgent(id)
        if ag === nothing
            add_span_event(span, "agent_not_found")
            return false
        end

        record_metric(id, "agent_resumes", 1, type=COUNTER)

        success = Core.resumeAgent(id)
        if success
            add_span_event(span, "agent_resumed")
            record_metric(id, "agent_status", 1,
                type=GAUGE,
                tags=Dict("status" => "running"))
        else
            add_span_event(span, "resume_failed")
            record_metric(id, "agent_resume_failures", 1,
                type=COUNTER)
        end

        return success
    catch e
        add_span_event(span, "resume_error",
            attributes=Dict("error" => string(e)))
        record_metric(id, "agent_errors", 1, type=COUNTER)
        rethrow(e)
    finally
        end_span(span)
    end
end

# Export monitored functions
export start_monitored_agent, stop_monitored_agent,
       pause_monitored_agent, resume_monitored_agent

end # module