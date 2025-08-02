module WebSocketManager

using HTTP.WebSockets
using Base.Threads: SpinLock, @spawn
using DataStructures: CircularBuffer
using Dates
using JSON3
using Logging

# Connection states
@enum ConnectionState begin
    CONNECTING
    CONNECTED
    RECONNECTING
    DISCONNECTED
    FAILED
end

"""
    WebSocketConnection

Represents a managed WebSocket connection with reconnection logic.
"""
mutable struct WebSocketConnection
    id::String
    url::String
    ws::Union{WebSocket, Nothing}
    state::ConnectionState
    last_ping::DateTime
    reconnect_attempts::Int
    message_buffer::CircularBuffer{String}
    error_count::Int
    lock::SpinLock
    on_message::Function
    on_error::Function
    on_state_change::Function

    WebSocketConnection(
        id::String,
        url::String;
        buffer_size::Int=100,
        on_message::Function=(msg)->nothing,
        on_error::Function=(err)->nothing,
        on_state_change::Function=(state)->nothing
    ) = new(
        id,
        url,
        nothing,
        DISCONNECTED,
        now(),
        0,
        CircularBuffer{String}(buffer_size),
        0,
        SpinLock(),
        on_message,
        on_error,
        on_state_change
    )
end

# Connection configuration
const MAX_RECONNECT_ATTEMPTS = 5
const INITIAL_RECONNECT_DELAY = 1.0  # seconds
const MAX_RECONNECT_DELAY = 30.0     # seconds
const PING_INTERVAL = 30.0           # seconds
const ERROR_THRESHOLD = 3            # errors before circuit breaker
const CIRCUIT_BREAKER_TIMEOUT = 60.0 # seconds

# Connection management
const connections = Dict{String, WebSocketConnection}()
const connections_lock = SpinLock()

"""
    connect(conn::WebSocketConnection)

Establish a WebSocket connection with error handling and reconnection logic.
"""
function connect(conn::WebSocketConnection)
    lock(conn.lock) do
        if conn.state in [CONNECTING, CONNECTED]
            return
        end
        
        update_connection_state(conn, CONNECTING)
        
        try
            ws = WebSockets.open(conn.url)
            
            # Set up message handler
            @async handle_messages(conn, ws)
            
            # Set up ping/pong
            @async handle_heartbeat(conn)
            
            conn.ws = ws
            conn.last_ping = now()
            conn.reconnect_attempts = 0
            conn.error_count = 0
            
            update_connection_state(conn, CONNECTED)
            
        catch e
            handle_connection_error(conn, e)
        end
    end
end

"""
    reconnect(conn::WebSocketConnection)

Attempt to reconnect with exponential backoff.
"""
function reconnect(conn::WebSocketConnection)
    lock(conn.lock) do
        if conn.state == CONNECTED
            return
        end
        
        if conn.reconnect_attempts >= MAX_RECONNECT_ATTEMPTS
            update_connection_state(conn, FAILED)
            @error "Max reconnection attempts reached" connection_id=conn.id
            return
        end
        
        update_connection_state(conn, RECONNECTING)
        
        # Calculate backoff delay
        delay = min(
            INITIAL_RECONNECT_DELAY * (2 ^ conn.reconnect_attempts),
            MAX_RECONNECT_DELAY
        )
        
        conn.reconnect_attempts += 1
        
        # Attempt reconnection after delay
        @async begin
            sleep(delay)
            connect(conn)
        end
    end
end

"""
    handle_messages(conn::WebSocketConnection, ws::WebSocket)

Handle incoming WebSocket messages.
"""
function handle_messages(conn::WebSocketConnection, ws::WebSocket)
    try
        while !eof(ws)
            data = readavailable(ws)
            if !isempty(data)
                message = String(data)
                
                # Store in buffer
                lock(conn.lock) do
                    push!(conn.message_buffer, message)
                end
                
                # Process message
                try
                    conn.on_message(message)
                catch e
                    @error "Error processing message" exception=(e, catch_backtrace())
                    conn.on_error(e)
                end
            end
        end
    catch e
        handle_connection_error(conn, e)
    end
end

"""
    handle_heartbeat(conn::WebSocketConnection)

Send periodic ping messages to keep connection alive.
"""
function handle_heartbeat(conn::WebSocketConnection)
    while true
        try
            lock(conn.lock) do
                if conn.state != CONNECTED || conn.ws === nothing
                    return
                end
                
                # Check last ping time
                if now() - conn.last_ping > Second(PING_INTERVAL)
                    write(conn.ws, JSON3.write(Dict("type" => "ping")))
                    conn.last_ping = now()
                end
            end
        catch e
            handle_connection_error(conn, e)
        end
        
        sleep(1)
    end
end

"""
    handle_connection_error(conn::WebSocketConnection, error::Exception)

Handle connection errors with circuit breaker pattern.
"""
function handle_connection_error(conn::WebSocketConnection, error::Exception)
    lock(conn.lock) do
        conn.error_count += 1
        conn.on_error(error)
        
        if conn.error_count >= ERROR_THRESHOLD
            # Circuit breaker triggered
            update_connection_state(conn, FAILED)
            @error "Circuit breaker triggered" connection_id=conn.id error_count=conn.error_count
            
            # Schedule circuit breaker reset
            @async begin
                sleep(CIRCUIT_BREAKER_TIMEOUT)
                lock(conn.lock) do
                    if conn.state == FAILED
                        conn.error_count = 0
                        reconnect(conn)
                    end
                end
            end
        else
            # Attempt immediate reconnection
            reconnect(conn)
        end
    end
end

"""
    update_connection_state(conn::WebSocketConnection, state::ConnectionState)

Update connection state and notify listeners.
"""
function update_connection_state(conn::WebSocketConnection, state::ConnectionState)
    old_state = conn.state
    conn.state = state
    
    if old_state != state
        @info "WebSocket state change" connection_id=conn.id old_state=old_state new_state=state
        conn.on_state_change(state)
    end
end

"""
    send_message(conn::WebSocketConnection, message::String)

Send a message with automatic reconnection.
"""
function send_message(conn::WebSocketConnection, message::String)
    lock(conn.lock) do
        if conn.state != CONNECTED || conn.ws === nothing
            # Store message in buffer
            push!(conn.message_buffer, message)
            
            # Attempt reconnection if needed
            if conn.state == DISCONNECTED
                reconnect(conn)
            end
            return false
        end
        
        try
            write(conn.ws, message)
            return true
        catch e
            handle_connection_error(conn, e)
            push!(conn.message_buffer, message)
            return false
        end
    end
end

"""
    create_connection(id::String, url::String; kwargs...)

Create and initialize a new WebSocket connection.
"""
function create_connection(
    id::String,
    url::String;
    buffer_size::Int=100,
    on_message::Function=(msg)->nothing,
    on_error::Function=(err)->nothing,
    on_state_change::Function=(state)->nothing
)
    conn = WebSocketConnection(
        id,
        url,
        buffer_size=buffer_size,
        on_message=on_message,
        on_error=on_error,
        on_state_change=on_state_change
    )
    
    lock(connections_lock) do
        connections[id] = conn
    end
    
    connect(conn)
    return conn
end

"""
    close_connection(conn::WebSocketConnection)

Close a WebSocket connection and clean up resources.
"""
function close_connection(conn::WebSocketConnection)
    lock(conn.lock) do
        if conn.ws !== nothing
            try
                close(conn.ws)
            catch
            end
            conn.ws = nothing
        end
        
        update_connection_state(conn, DISCONNECTED)
    end
    
    lock(connections_lock) do
        delete!(connections, conn.id)
    end
end

"""
    get_connection_stats()

Get statistics about all managed connections.
"""
function get_connection_stats()
    stats = Dict{String, Any}()
    
    lock(connections_lock) do
        for (id, conn) in connections
            lock(conn.lock) do
                stats[id] = Dict(
                    "state" => string(conn.state),
                    "reconnect_attempts" => conn.reconnect_attempts,
                    "error_count" => conn.error_count,
                    "buffered_messages" => length(conn.message_buffer),
                    "last_ping" => conn.last_ping
                )
            end
        end
    end
    
    return stats
end

end # module