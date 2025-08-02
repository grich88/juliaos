module AlertsWebSocket

using HTTP
using HTTP.WebSockets
using JSON3
using DataStructures: CircularBuffer
using Base.Threads: SpinLock
using Main.Monitoring: AlertEvent, AlertSubscriber

# Thread-safe alert buffer and client management
const ALERT_BUFFER_SIZE = 100
const alert_buffer = CircularBuffer{AlertEvent}(ALERT_BUFFER_SIZE)
const buffer_lock = SpinLock()

# Active WebSocket connections
const clients = Dict{String, WebSocket}()
const clients_lock = SpinLock()

# Alert subscription management
const subscribers = Dict{String, AlertSubscriber}()
const subscribers_lock = SpinLock()

"""
    handle_ws_connection(ws::WebSocket)

Handle a new WebSocket connection for real-time alerts.
"""
function handle_ws_connection(ws::WebSocket)
    client_id = string(UUIDs.uuid4())
    
    try
        # Register client
        lock(clients_lock) do
            clients[client_id] = ws
        end

        # Send initial alert buffer
        lock(buffer_lock) do
            for alert in alert_buffer
                send_alert(ws, alert)
            end
        end

        # Create alert subscriber
        subscriber = AlertSubscriber(
            client_id,
            (alert) -> send_alert(ws, alert),
            () -> remove_client(client_id)
        )

        # Register subscriber
        lock(subscribers_lock) do
            subscribers[client_id] = subscriber
        end

        # Keep connection alive and handle incoming messages
        while !eof(ws)
            data = readavailable(ws)
            if !isempty(data)
                handle_client_message(ws, data)
            end
        end

    catch e
        @error "WebSocket error" exception=(e, catch_backtrace())
    finally
        remove_client(client_id)
    end
end

"""
    send_alert(ws::WebSocket, alert::AlertEvent)

Send an alert to a specific WebSocket client.
"""
function send_alert(ws::WebSocket, alert::AlertEvent)
    try
        write(ws, JSON3.write(alert))
    catch e
        @error "Failed to send alert" exception=(e, catch_backtrace())
    end
end

"""
    broadcast_alert(alert::AlertEvent)

Broadcast an alert to all connected clients and store in buffer.
"""
function broadcast_alert(alert::AlertEvent)
    # Store in buffer
    lock(buffer_lock) do
        push!(alert_buffer, alert)
    end

    # Broadcast to all clients
    lock(clients_lock) do
        for (_, ws) in clients
            @async send_alert(ws, alert)
        end
    end
end

"""
    remove_client(client_id::String)

Remove a client and its associated subscriber.
"""
function remove_client(client_id::String)
    # Remove from clients
    lock(clients_lock) do
        if haskey(clients, client_id)
            try
                close(clients[client_id])
            catch
            end
            delete!(clients, client_id)
        end
    end

    # Remove from subscribers
    lock(subscribers_lock) do
        delete!(subscribers, client_id)
    end
end

"""
    handle_client_message(ws::WebSocket, data::Vector{UInt8})

Handle incoming messages from WebSocket clients.
"""
function handle_client_message(ws::WebSocket, data::Vector{UInt8})
    try
        message = JSON3.read(String(data))
        
        # Handle client-specific filtering
        if haskey(message, "filter")
            # TODO: Implement client-specific alert filtering
        end
        
    catch e
        @error "Failed to handle client message" exception=(e, catch_backtrace())
    end
end

"""
    get_connected_clients_count()

Get the number of currently connected WebSocket clients.
"""
function get_connected_clients_count()
    lock(clients_lock) do
        return length(clients)
    end
end

"""
    clear_alert_buffer()

Clear the alert buffer. Useful for testing and maintenance.
"""
function clear_alert_buffer()
    lock(buffer_lock) do
        empty!(alert_buffer)
    end
end

end # module