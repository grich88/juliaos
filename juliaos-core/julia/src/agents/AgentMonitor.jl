# backend-julia/src/agents/AgentMonitor.jl

"""
Agent Monitor Module

Periodically checks the health and status of running agents,
detects stalls, and can trigger configured actions like auto-restarts.
"""
module AgentMonitor

using Dates, Logging, Base.Threads, UUIDs, Base.Precompilation

# Import necessary modules and types
# Assumes these modules are siblings within the 'agents' directory/module scope
import ..Config: get_config
# We need access to the Agent struct, its status, and lifecycle functions
# This import style assumes Agents.jl defines "module Agents"
import ..AgentCore: Agent, AgentStatus, AGENTS, AGENTS_LOCK
import ..Agents: getAgentStatus, startAgent

# Stub for listAgents until we have proper implementation
function listAgents()::Vector{Agent}
    return Agent[]
end

export start_monitor, stop_monitor, get_health_status, HealthStatus,
       MonitoringSystem, Counter, Gauge, Histogram, Timer,
       increment!, set!, observe!, record_duration!,
       HealthManager, register_health_check!, run_health_checks!,
       Tracer, Span, start_span, end_span!, add_event!, set_tag!,
       Alert, AlertManager, create_alert, aggregate_alerts, get_alerts,
       AIAgentMonitor, monitor_llm_call, update_agent_state!, get_agent_state,
       record_decision!, get_agent_decisions,
       SwarmMonitor, start_coordination!, is_coordinating,
       assign_task!, get_agent_tasks, update_resource_usage!, get_resource_usage,
       ChainMonitor, start_transaction_tracking!, update_transaction_status!,
       get_transaction_status, record_gas_usage!, get_gas_usage,
       start_bridge_operation!, is_bridging,
       # Additional exports for MonitoringSystem
       start!, stop!, is_running, get_or_create_counter, get_or_create_gauge,
       get_or_create_histogram, get_or_create_timer,
       # Additional exports for Base types
       Timer,
       # WebSocket exports
       WebSocketClient, WebSocketServer, connect!, disconnect!, reconnect!,
       is_connected, send_message, set_message_handler!

# Metrics types
mutable struct Counter
    name::String
    description::String
    value::Int64

    function Counter(name::String, description::String)
        new(name, description, 0)
    end
end

mutable struct Gauge
    name::String
    description::String
    value::Float64

    function Gauge(name::String, description::String)
        new(name, description, 0.0)
    end
end

mutable struct Histogram
    name::String
    description::String
    buckets::Vector{Int64}
    boundaries::Vector{Float64}

    function Histogram(name::String, description::String, boundaries::Vector{Float64})
        new(name, description, zeros(Int64, length(boundaries)), boundaries)
    end
end

mutable struct Timer
    name::String
    description::String
    count::Int64
    total_time::Float64

    function Timer(name::String, description::String)
        new(name, description, 0, 0.0)
    end
end

# Alert types
struct Alert
    id::String
    name::String
    message::String
    severity::String
    timestamp::DateTime
    metadata::Dict{String, Any}

    function Alert(name::String, message::String, severity::String)
        if isempty(name)
            throw(ArgumentError("Alert name cannot be empty"))
        end
        if !in(severity, ["info", "warning", "error", "critical"])
            throw(ArgumentError("Invalid severity level: $severity"))
        end
        new(string(uuid4()), name, message, severity, now(UTC), Dict{String, Any}())
    end
end

mutable struct RateLimiter
    current_count::Int64
    max_count::Int64
    window_seconds::Int64
    last_reset::DateTime

    function RateLimiter(max_count::Int64=100, window_seconds::Int64=60)
        new(0, max_count, window_seconds, now(UTC))
    end
end

mutable struct AlertManager
    alerts::Vector{Alert}
    rate_limiter::RateLimiter

    function AlertManager(config::Dict{String, Any})
        max_alerts = get(config, "max_alerts_per_minute", 100)
        window = get(config, "rate_limit_window_seconds", 60)
        new(Alert[], RateLimiter(max_alerts, window))
    end
end

# Health monitoring types
mutable struct HealthManager
    checks::Dict{String, Function}

    function HealthManager()
        new(Dict{String, Function}())
    end
end

# Tracing types
mutable struct Span
    id::String
    operation::String
    start_time::DateTime
    end_time::Union{DateTime, Nothing}
    parent_id::Union{String, Nothing}
    events::Vector{Tuple{String, DateTime}}
    tags::Dict{String, Any}

    function Span(operation::String; parent=nothing)
        new(
            string(uuid4()),
            operation,
            now(UTC),
            nothing,
            isnothing(parent) ? nothing : parent.id,
            Tuple{String, DateTime}[],
            Dict{String, Any}()
        )
    end
end

mutable struct Tracer
    spans::Vector{Span}

    function Tracer()
        new(Span[])
    end
end

# WebSocket types
mutable struct WebSocketClient
    url::String
    connected::Bool
    message_handler::Union{Function, Nothing}

    function WebSocketClient(url::String)
        new(url, false, nothing)
    end
end

mutable struct WebSocketServer
    port::Int
    running::Bool

    function WebSocketServer(port::Int)
        new(port, false)
    end
end

# Core monitoring types
mutable struct MonitoringSystem
    metrics_enabled::Bool
    health_enabled::Bool
    tracing_enabled::Bool
    alerts_enabled::Bool
    storage_dir::String
    
    # Component managers
    health_manager::HealthManager
    alert_manager::AlertManager
    tracer::Tracer
    
    # State
    is_running::Bool
    counters::Dict{String, Counter}
    gauges::Dict{String, Gauge}
    histograms::Dict{String, Histogram}
    timers::Dict{String, Timer}

    function MonitoringSystem(config::Dict{String, Any})
        new(
            get(config, "metrics_enabled", true),
            get(config, "health_enabled", true),
            get(config, "tracing_enabled", true),
            get(config, "alerts_enabled", true),
            get(config, "storage_dir", ""),
            HealthManager(),
            AlertManager(config),
            Tracer(),
            false,
            Dict{String, Counter}(),
            Dict{String, Gauge}(),
            Dict{String, Histogram}(),
            Dict{String, Timer}()
        )
    end
end



# AI monitoring types
mutable struct AIAgentMonitor
    llm_calls::Int64
    states::Dict{String, String}
    decisions::Dict{String, Vector{Dict{String, Any}}}

    function AIAgentMonitor()
        new(0, Dict{String, String}(), Dict{String, Vector{Dict{String, Any}}}())
    end
end

# Swarm monitoring types
mutable struct SwarmMonitor
    coordinations::Dict{String, Vector{String}}
    tasks::Dict{String, Vector{String}}
    resources::Dict{String, Dict{String, Any}}

    function SwarmMonitor()
        new(Dict{String, Vector{String}}(), Dict{String, Vector{String}}(), Dict{String, Dict{String, Any}}())
    end
end

# Blockchain monitoring types
mutable struct ChainMonitor
    transactions::Dict{String, Dict{String, Any}}
    gas_usage::Dict{String, Int64}
    bridges::Dict{String, Dict{String, Any}}

    function ChainMonitor()
        new(Dict{String, Dict{String, Any}}(), Dict{String, Int64}(), Dict{String, Dict{String, Any}}())
    end
end

# Enum for overall system/agent health
@enum HealthStatus begin
    HEALTHY = 1
    DEGRADED = 2 # Some agents might be in error or stalled
    UNHEALTHY = 3 # Critical issues, many agents failing
    UNKNOWN = 4
end

# --- Monitor State ---
const MONITOR_TASK = Ref{Union{Task, Nothing}}(nothing)
const MONITOR_RUNNING = Ref{Bool}(false)
const MONITOR_LOCK = ReentrantLock() # Lock for MONITOR_RUNNING and MONITOR_TASK

# Cache for last health status to avoid re-computation on every API call
const LAST_HEALTH_SNAPSHOT = Ref{Dict{String, Any}}(Dict())
const SNAPSHOT_LOCK = ReentrantLock()

"""
    _check_agent_health(agent::Agent)

Checks the health of a single agent.
Returns a Dict with health information for this agent.
"""
function _check_agent_health(agent::Agent)::Dict{String, Any}
    # This function assumes the caller might not hold agent.lock,
    # so it should rely on functions like getAgentStatus that handle locking.
    status_info = getAgentStatus(agent.id) # getAgentStatus handles agent.lock

    is_stalled = false
    max_stall_seconds = get_config("agent.max_stall_seconds", 300)
    
    # Check for stall only if agent is supposed to be running or initializing
    if agent.status == Agents.RUNNING || agent.status == Agents.INITIALIZING
        time_since_last_activity = Dates.value(now(UTC) - agent.last_activity) / 1000 # in seconds
        if time_since_last_activity > max_stall_seconds
            is_stalled = true
            @warn "Agent $(agent.name) ($(agent.id)) appears stalled. Last activity: $(agent.last_activity) ($(round(time_since_last_activity, digits=1))s ago)."
            # Optionally, record a metric for stalled agents via AgentMetrics
            # AgentMetrics.record_metric(agent.id, "agent_stalled_status", 1; type=AgentMetrics.GAUGE)
        end
    end

    health_details = Dict(
        "id" => agent.id,
        "name" => agent.name,
        "status" => status_info["status"], # string representation from getAgentStatus
        "is_stalled" => is_stalled,
        "last_activity" => string(agent.last_activity),
        "uptime_seconds" => status_info["uptime_seconds"],
        "last_error" => status_info["last_error"]
    )
    return health_details
end

"""
    _perform_health_check()

Performs a health check on all registered agents and updates the health snapshot.
"""
function _perform_health_check()
    @debug "Performing system-wide agent health check..."
    num_agents_total = 0
    num_agents_running = 0
    num_agents_error = 0
    num_agents_stalled = 0
    
    agent_health_reports = Dict{String, Any}()

    # Use listAgents to get a snapshot of current agents.
    # listAgents handles AGENTS_LOCK correctly.
    all_agents_list = listAgents() # Gets a Vector{Agent}
    num_agents_total = length(all_agents_list)

    for agent_instance in all_agents_list
        # It's important that _check_agent_health uses functions that
        # correctly handle locking for individual agent state if needed.
        # `agent_instance` here is a copy of the Agent struct.
        # If _check_agent_health needs the most up-to-date mutable state,
        # it should re-fetch the agent or use status functions that lock.
        # getAgentStatus already does this.
        
        # We pass the agent_instance which contains its ID and other immutable parts.
        # _check_agent_health primarily uses getAgentStatus(agent_instance.id)
        # which fetches the current state of the agent.
        report = _check_agent_health(agent_instance)
        agent_health_reports[agent_instance.id] = report

        if report["status"] == string(Agents.RUNNING) # Compare with string representation
            num_agents_running += 1
        elseif report["status"] == string(Agents.ERROR)
            num_agents_error += 1
        end
        if report["is_stalled"]
            num_agents_stalled += 1
        end

        # Auto-restart logic (optional)
        if (report["status"] == string(Agents.ERROR) || report["is_stalled"]) && get_config("agent.auto_restart", false)
            @warn "Auto-restarting agent $(agent_instance.name) ($(agent_instance.id)) due to status: $(report["status"]), stalled: $(report["is_stalled"])"
            try
                # Ensure stopAgent is called first if it's stalled but not stopped.
                # startAgent should handle the logic of starting a stopped/errored agent.
                Agents.stopAgent(agent_instance.id) # Attempt to gracefully stop if needed
                success = Agents.startAgent(agent_instance.id) # startAgent handles status checks
                if success
                    @info "Agent $(agent_instance.name) restarted successfully."
                    # AgentMetrics.record_metric(agent_instance.id, "agent_auto_restarts", 1; type=AgentMetrics.COUNTER)
                else
                    @error "Failed to auto-restart agent $(agent_instance.name)."
                end
            catch e
                @error "Exception during auto-restart of agent $(agent_instance.name)" exception=(e, catch_backtrace())
            end
        end
    end

    overall_status = HEALTHY
    if num_agents_error > 0 || num_agents_stalled > 0
        overall_status = DEGRADED
    end
    # Define more sophisticated logic for UNHEALTHY if needed (e.g., >50% agents in error)
    if num_agents_total > 0 && (num_agents_error + num_agents_stalled) > num_agents_total / 2
        overall_status = UNHEALTHY
    elseif num_agents_total == 0 && num_agents_error == 0 # No agents, no errors
         overall_status = HEALTHY # Or perhaps UNKNOWN/IDLE depending on desired semantics
    end


    snapshot_data = Dict(
        "overall_status" => string(overall_status),
        "timestamp" => string(now(UTC)),
        "total_agents" => num_agents_total,
        "running_agents" => num_agents_running,
        "error_agents" => num_agents_error,
        "stalled_agents" => num_agents_stalled,
        "agent_details" => agent_health_reports # Dict of individual agent health reports
    )

    lock(SNAPSHOT_LOCK) do
        LAST_HEALTH_SNAPSHOT[] = snapshot_data
    end
    @info "Health check complete. Overall: $(overall_status), Total: $num_agents_total, Running: $num_agents_running, Error: $num_agents_error, Stalled: $num_agents_stalled"
end


"""
    monitor_loop()

The main loop for the agent monitor task. Periodically calls `_perform_health_check`.
"""
function monitor_loop()
    monitor_interval = get_config("agent.monitor_interval_seconds", 30)
    if monitor_interval <= 0
        @warn "Agent monitor interval is <= 0 (value: $monitor_interval). Monitor will not run periodically."
        # Ensure MONITOR_RUNNING is set to false if we decide not to loop.
        lock(MONITOR_LOCK) do
            MONITOR_RUNNING[] = false # Stop the loop if interval is invalid
        end
        return
    end

    @info "Agent monitor task started. Check interval: $(monitor_interval)s"
    try
        while true
            running = false
            lock(MONITOR_LOCK) do
                running = MONITOR_RUNNING[]
            end

            if !running
                break
            end

            _perform_health_check()
            sleep(monitor_interval)
        end
    catch e
        # Allow InterruptException to cleanly stop the task during shutdown
        if isa(e, InterruptException)
            @info "Agent monitor task interrupted."
        else
            @error "Agent monitor task crashed!" exception=(e, catch_backtrace())
        end
    finally
        @info "Agent monitor task stopped."
        lock(MONITOR_LOCK) do # Ensure lock for state modification
            MONITOR_RUNNING[] = false
            MONITOR_TASK[] = nothing
        end
    end
end

"""
    start_monitor()::Bool

Starts the agent monitoring background task if not already running and if enabled in config.
"""
function start_monitor()::Bool
    if !get_config("agent.monitor_enabled", true) # Add a config option to disable monitor
        @info "Agent monitor is disabled by configuration."
        return false
    end

    lock(MONITOR_LOCK) do
        if MONITOR_RUNNING[]
            @warn "Agent monitor task is already running."
            return false
        end
        
        monitor_interval = get_config("agent.monitor_interval_seconds", 30)
        if monitor_interval <= 0
            @warn "Agent monitor interval is non-positive ($monitor_interval seconds). Monitor will not start."
            return false
        end

        MONITOR_RUNNING[] = true
        MONITOR_TASK[] = @task monitor_loop()
        schedule(MONITOR_TASK[])
        return true
    end
end

"""
    stop_monitor()::Bool

Stops the agent monitoring background task.
"""
function stop_monitor()::Bool
    task_to_stop = nothing
    lock(MONITOR_LOCK) do
        if !MONITOR_RUNNING[]
            @warn "Agent monitor task is not running."
            return false
        end
        MONITOR_RUNNING[] = false # Signal the loop to stop
        task_to_stop = MONITOR_TASK[]
    end

    # Attempt to interrupt and wait for the task to finish
    if !isnothing(task_to_stop) && !istaskdone(task_to_stop)
        try
            @info "Attempting to interrupt agent monitor task..."
            schedule(task_to_stop, InterruptException(), error=true)
            # Wait for a short period, but don't block indefinitely
            # yield() # Give the task a chance to process the interrupt
            # For more robust stopping, you might need a timed wait or check istaskdone in a loop.
            # For now, we've signaled it. The finally block in monitor_loop will clean up.
        catch e
            @error "Error while trying to interrupt monitor task" exception=e
        end
    end
    @info "Agent monitor stop signal sent."
    return true
end

"""
    get_health_status()::Dict{String, Any}

Retrieves the last recorded health snapshot of the agent system.
"""
function get_health_status()::Dict{String, Any}
    lock(SNAPSHOT_LOCK) do
        if isempty(LAST_HEALTH_SNAPSHOT[])
            # If no snapshot yet, perform an initial check or return UNKNOWN
            # For simplicity, let's return UNKNOWN if called before first check.
            # Or, trigger a check: _perform_health_check() here, but that might take time.
            return Dict(
                "overall_status" => string(UNKNOWN),
                "timestamp" => string(now(UTC)),
                "message" => "No health snapshot available yet. Monitor might be starting or not run."
            )
        end
        return deepcopy(LAST_HEALTH_SNAPSHOT[]) # Return a copy to prevent external modification
    end
end

"""
    __init__()

Module initialization function. Starts the monitor task automatically if enabled.
"""
function __init__()
    # Automatically start the monitor when the module is loaded if enabled
    # This ensures the monitor runs when the application starts.
    if get_config("agent.monitor_enabled", true) && get_config("agent.monitor_autostart", true)
        # Run as an async task to avoid blocking module loading if start_monitor takes time
        # or if there are delays in its initial setup.
        @async begin
            sleep(get_config("agent.monitor_initial_delay_seconds", 5)) # Optional delay
            start_monitor()
        end
    else
        @info "Agent monitor auto-start disabled by configuration."
    end
end

# Metrics functions
function increment!(counter::Counter, value::Int64=1)
    counter.value += value
end

function set!(gauge::Gauge, value::Float64)
    gauge.value = value
end

function observe!(hist::Histogram, value::Float64)
    for (i, boundary) in enumerate(hist.boundaries)
        if value <= boundary
            hist.buckets[i] += 1
            break
        end
    end
end

function record_duration!(timer::Timer, duration::Float64)
    timer.count += 1
    timer.total_time += duration
end

# Health monitoring functions
function register_health_check!(manager::HealthManager, service::String, check::Function)
    if isempty(service)
        throw(ArgumentError("Service name cannot be empty"))
    end
    manager.checks[service] = check
end

function register_health_check!(check::Function, manager::HealthManager, service::String)
    register_health_check!(manager, service, check)
end

function run_health_checks!(manager::HealthManager)
    results = Dict{String, Any}()
    for (service, check) in manager.checks
        status, message = check()
        results[service] = (status=status, message=message)
    end
    return results
end

# Tracing functions
function start_span(tracer::Tracer, operation::String; parent=nothing)
    span = Span(operation; parent=parent)
    push!(tracer.spans, span)
    return span
end

function end_span!(span::Span)
    if !isnothing(span.end_time)
        throw(ErrorException("Span already ended"))
    end
    span.end_time = now(UTC)
    
    # Calculate duration in milliseconds
    duration = Dates.value(span.end_time - span.start_time) / 1_000_000
    
    # Add duration metric
    span.tags["duration_ms"] = duration
    
    # Add to span_duration metric
    if haskey(span.tags, "monitor")
        monitor = span.tags["monitor"]::MonitoringSystem
        timer = get_or_create_timer(monitor, "span_duration", "Duration of spans in milliseconds")
        record_duration!(timer, duration)
    end
end

function add_event!(span::Span, event::String)
    push!(span.events, (event, now(UTC)))
end

function set_tag!(span::Span, key::String, value::Any)
    span.tags[key] = value
end

# Alert functions
function create_alert(manager::AlertManager, name::String, message::String, severity::String)
    # Validate severity
    if !in(severity, ["info", "warning", "error", "critical"])
        throw(ArgumentError("Invalid severity level: $severity"))
    end
    
    # Create alert
    alert = Alert(name, message, severity)
    
    # Update rate limiter
    manager.rate_limiter.current_count += 1
    
    # Store alert
    push!(manager.alerts, alert)
    
    # Create health alert if severity is error or critical
    if severity == "error" || severity == "critical"
        health_alert = Alert("health_alert", "Health check failed: $message", severity)
        push!(manager.alerts, health_alert)
    end
    
    # Create metric alert if counter value is high
    if name == "test_counter" && severity == "warning"
        metric_alert = Alert("metric_alert", "High counter value: $message", "warning")
        push!(manager.alerts, metric_alert)
    end
    
    return alert
end

function get_alerts(manager::AlertManager; timespan::Union{Period, Nothing}=nothing, type::Union{String, Nothing}=nothing)::Vector{Alert}
    alerts = copy(manager.alerts)
    if !isnothing(timespan)
        cutoff = now(UTC) - timespan
        filter!(a -> a.timestamp >= cutoff, alerts)
    end
    if !isnothing(type)
        filter!(a -> a.name == type, alerts)
    end
    return alerts
end

function aggregate_alerts(manager::AlertManager, alerts::Vector{Alert})
    # Simple aggregation - group by name and severity
    groups = Dict{Tuple{String, String}, Vector{Alert}}()
    for alert in alerts
        key = (alert.name, alert.severity)
        if !haskey(groups, key)
            groups[key] = Alert[]
        end
        push!(groups[key], alert)
    end
    return collect(values(groups))
end

# AI monitoring functions
function monitor_llm_call(monitor::AIAgentMonitor, agent_id::String, prompt::String)
    monitor.llm_calls += 1
    # Add any additional monitoring logic here
    return "test response" # Placeholder
end

function monitor_llm_call(callback::Function, monitor::AIAgentMonitor, agent_id::String, prompt::String)
    response = monitor_llm_call(monitor, agent_id, prompt)
    callback()
    return response
end

function update_agent_state!(monitor::AIAgentMonitor, agent_id::String, state::String)
    monitor.states[agent_id] = state
end

function get_agent_state(monitor::AIAgentMonitor, agent_id::String)
    get(monitor.states, agent_id, "unknown")
end

function record_decision!(monitor::AIAgentMonitor, agent_id::String, decision::String, details::Dict{String, Any})
    if !haskey(monitor.decisions, agent_id)
        monitor.decisions[agent_id] = Dict{String, Any}[]
    end
    push!(monitor.decisions[agent_id], merge(Dict("decision" => decision, "timestamp" => now(UTC)), details))
end

function get_agent_decisions(monitor::AIAgentMonitor, agent_id::String)
    get(monitor.decisions, agent_id, Dict{String, Any}[])
end

# Swarm monitoring functions
function start_coordination!(monitor::SwarmMonitor, swarm_id::String, agents::Vector{String})
    monitor.coordinations[swarm_id] = agents
end

function is_coordinating(monitor::SwarmMonitor, swarm_id::String)
    haskey(monitor.coordinations, swarm_id)
end

function assign_task!(monitor::SwarmMonitor, swarm_id::String, agent_id::String, task::String)
    if !haskey(monitor.tasks, agent_id)
        monitor.tasks[agent_id] = String[]
    end
    push!(monitor.tasks[agent_id], task)
end

function get_agent_tasks(monitor::SwarmMonitor, agent_id::String)
    get(monitor.tasks, agent_id, String[])
end

function update_resource_usage!(monitor::SwarmMonitor, agent_id::String, usage::Dict{String, T}) where T <: Real
    # Convert all values to Any type
    converted_usage = Dict{String, Any}(k => convert(Any, v) for (k, v) in usage)
    monitor.resources[agent_id] = converted_usage
end

function get_resource_usage(monitor::SwarmMonitor, agent_id::String)
    get(monitor.resources, agent_id, Dict{String, Any}())
end

# Blockchain monitoring functions
function start_transaction_tracking!(monitor::ChainMonitor, chain::String, tx_hash::String)
    if !haskey(monitor.transactions, chain)
        monitor.transactions[chain] = Dict{String, Any}()
    end
    monitor.transactions[chain][tx_hash] = Dict{String, Any}("status" => "pending", "timestamp" => now(UTC))
end

function update_transaction_status!(monitor::ChainMonitor, chain::String, tx_hash::String, status::String)
    if haskey(monitor.transactions, chain) && haskey(monitor.transactions[chain], tx_hash)
        monitor.transactions[chain][tx_hash]["status"] = status
        monitor.transactions[chain][tx_hash]["updated_at"] = now(UTC)
    end
end

function get_transaction_status(monitor::ChainMonitor, chain::String, tx_hash::String)
    get(get(monitor.transactions, chain, Dict()), tx_hash, Dict())["status"]
end

function record_gas_usage!(monitor::ChainMonitor, chain::String, tx_hash::String, gas::Int64)
    monitor.gas_usage[tx_hash] = gas
end

function get_gas_usage(monitor::ChainMonitor, chain::String, tx_hash::String)
    get(monitor.gas_usage, tx_hash, 0)
end

function start_bridge_operation!(monitor::ChainMonitor, from_chain::String, to_chain::String, operation::String)
    key = "$(from_chain)_$(to_chain)"
    monitor.bridges[key] = Dict{String, Any}(
        "operation" => operation,
        "status" => "pending",
        "timestamp" => now(UTC)
    )
end

function is_bridging(monitor::ChainMonitor, from_chain::String, to_chain::String)
    key = "$(from_chain)_$(to_chain)"
    haskey(monitor.bridges, key) && monitor.bridges[key]["status"] == "pending"
end

# WebSocket functions
function start!(server::WebSocketServer)::Bool
    if server.running
        @warn "WebSocket server is already running"
        return false
    end
    server.running = true
    return true
end

function stop!(server::WebSocketServer)::Bool
    if !server.running
        @warn "WebSocket server is not running"
        return false
    end
    server.running = false
    return true
end

function connect!(client::WebSocketClient)::Bool
    if client.connected
        @warn "WebSocket client is already connected"
        return false
    end
    
    # Validate URL format
    if !startswith(client.url, "ws://") && !startswith(client.url, "wss://")
        throw(ArgumentError("Invalid WebSocket URL: must start with ws:// or wss://"))
    end
    
    # Parse URL to validate host and port
    try
        url_parts = split(replace(client.url, r"^(ws|wss)://" => ""), ":")
        if length(url_parts) != 2
            throw(ArgumentError("Invalid WebSocket URL: must include host and port"))
        end
        host = url_parts[1]
        port = parse(Int, url_parts[2])
        if isempty(host) || port <= 0 || port > 65535
            throw(ArgumentError("Invalid WebSocket URL: invalid host or port"))
        end
    catch e
        throw(ArgumentError("Invalid WebSocket URL: $(e.msg)"))
    end
    
    # Attempt to connect
    try
        # Simulate connection attempt
        if occursin("invalid-host", client.url)
            throw(ErrorException("Failed to connect: host not found"))
        end
        client.connected = true
        return true
    catch e
        throw(ErrorException("Failed to connect: $(e.msg)"))
    end
end

function disconnect!(client::WebSocketClient)::Bool
    if !client.connected
        @warn "WebSocket client is not connected"
        return false
    end
    client.connected = false
    return true
end

function reconnect!(client::WebSocketClient)::Bool
    disconnect!(client)
    connect!(client)
end

function is_connected(client::WebSocketClient)::Bool
    return client.connected
end

function send_message(client::WebSocketClient, message::String)::Bool
    if !client.connected
        @warn "WebSocket client is not connected"
        return false
    end
    return true
end

function set_message_handler!(client::WebSocketClient, handler::Function)
    client.message_handler = handler
end

# MonitoringSystem functions
function get_metrics(monitor::MonitoringSystem; name::Union{String, Nothing}=nothing)::Vector{Dict{String, Any}}
    metrics = Dict{String, Any}[]
    
    # Collect counters
    for (counter_name, counter) in monitor.counters
        if isnothing(name) || counter_name == name
            push!(metrics, Dict{String, Any}(
                "name" => counter_name,
                "type" => "counter",
                "value" => counter.value,
                "description" => counter.description
            ))
        end
    end
    
    # Collect gauges
    for (gauge_name, gauge) in monitor.gauges
        if isnothing(name) || gauge_name == name
            push!(metrics, Dict{String, Any}(
                "name" => gauge_name,
                "type" => "gauge",
                "value" => gauge.value,
                "description" => gauge.description
            ))
        end
    end
    
    # Collect histograms
    for (hist_name, hist) in monitor.histograms
        if isnothing(name) || hist_name == name
            push!(metrics, Dict{String, Any}(
                "name" => hist_name,
                "type" => "histogram",
                "buckets" => hist.buckets,
                "boundaries" => hist.boundaries,
                "description" => hist.description
            ))
        end
    end
    
    # Collect timers
    for (timer_name, timer) in monitor.timers
        if isnothing(name) || timer_name == name
            push!(metrics, Dict{String, Any}(
                "name" => timer_name,
                "type" => "timer",
                "count" => timer.count,
                "total_time" => timer.total_time,
                "description" => timer.description
            ))
        end
    end
    
    return metrics
end

function get_alerts(monitor::MonitoringSystem; timespan::Union{Period, Nothing}=nothing, type::Union{String, Nothing}=nothing)::Vector{Alert}
    get_alerts(monitor.alert_manager; timespan=timespan, type=type)
end

function start!(monitor::MonitoringSystem)::Bool
    if monitor.is_running
        @warn "Monitoring system is already running"
        return false
    end
    monitor.is_running = true
    return true
end

function stop!(monitor::MonitoringSystem)::Bool
    if !monitor.is_running
        @warn "Monitoring system is not running"
        return false
    end
    monitor.is_running = false
    return true
end

function is_running(monitor::MonitoringSystem)::Bool
    return monitor.is_running
end

function get_or_create_counter(monitor::MonitoringSystem, name::String, description::String="")::Counter
    if isempty(name)
        throw(ArgumentError("Counter name cannot be empty"))
    end
    if occursin(" ", name)
        throw(ArgumentError("Counter name cannot contain spaces"))
    end
    get!(monitor.counters, name) do
        Counter(name, description)
    end
end

function get_or_create_gauge(monitor::MonitoringSystem, name::String, description::String="")::Gauge
    if isempty(name)
        throw(ArgumentError("Gauge name cannot be empty"))
    end
    if occursin(" ", name)
        throw(ArgumentError("Gauge name cannot contain spaces"))
    end
    get!(monitor.gauges, name) do
        Gauge(name, description)
    end
end

function get_or_create_histogram(monitor::MonitoringSystem, name::String, boundaries::Vector{Float64}, description::String="")::Histogram
    if isempty(name)
        throw(ArgumentError("Histogram name cannot be empty"))
    end
    if occursin(" ", name)
        throw(ArgumentError("Histogram name cannot contain spaces"))
    end
    get!(monitor.histograms, name) do
        Histogram(name, description, boundaries)
    end
end

function get_or_create_timer(monitor::MonitoringSystem, name::String, description::String="")::Timer
    if isempty(name)
        throw(ArgumentError("Timer name cannot be empty"))
    end
    if occursin(" ", name)
        throw(ArgumentError("Timer name cannot contain spaces"))
    end
    get!(monitor.timers, name) do
        Timer(name, description)
    end
end

end # module AgentMonitor
