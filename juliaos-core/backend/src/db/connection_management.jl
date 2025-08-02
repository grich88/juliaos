using LibPQ
using Base.Threads

# Connection pool configuration
const POOL_SIZE = Threads.nthreads()
const CONNECTION_POOL = Vector{Union{Nothing, LibPQ.Connection}}(nothing, POOL_SIZE)
const POOL_LOCKS = [ReentrantLock() for _ in 1:POOL_SIZE]
const POOL_LAST_USED = Vector{Float64}(0.0, POOL_SIZE)
const CONNECTION_TIMEOUT = 300.0  # 5 minutes
const HEALTH_CHECK_INTERVAL = 60.0  # 1 minute

# Health check task
const HEALTH_CHECK_RUNNING = Ref{Bool}(false)

"""
Initialize the connection pool with the given connection string.
"""
function initialize_connection_pool(conn_string::String)
    for i in 1:POOL_SIZE
        lock(POOL_LOCKS[i]) do
            if CONNECTION_POOL[i] !== nothing
                close(CONNECTION_POOL[i])
            end
            CONNECTION_POOL[i] = LibPQ.Connection(conn_string)
            POOL_LAST_USED[i] = time()
        end
    end
    
    # Start health check task if not running
    if !HEALTH_CHECK_RUNNING[]
        HEALTH_CHECK_RUNNING[] = true
        @async health_check_task(conn_string)
    end
end

"""
Get a connection from the pool. Creates new connection if needed.
"""
function get_connection()::LibPQ.Connection
    # Try to find an available connection
    for i in 1:POOL_SIZE
        if trylock(POOL_LOCKS[i])
            try
                conn = CONNECTION_POOL[i]
                if conn !== nothing && LibPQ.status(conn) == LibPQ.CONNECTION_OK
                    POOL_LAST_USED[i] = time()
                    return conn
                else
                    # Connection is dead, create new one
                    conn_string = get_connection_string()
                    CONNECTION_POOL[i] = LibPQ.Connection(conn_string)
                    POOL_LAST_USED[i] = time()
                    return CONNECTION_POOL[i]
                end
            finally
                unlock(POOL_LOCKS[i])
            end
        end
    end
    
    # All connections are busy, wait for one to become available
    while true
        for i in 1:POOL_SIZE
            if trylock(POOL_LOCKS[i])
                try
                    conn = CONNECTION_POOL[i]
                    if conn !== nothing && LibPQ.status(conn) == LibPQ.CONNECTION_OK
                        POOL_LAST_USED[i] = time()
                        return conn
                    else
                        # Connection is dead, create new one
                        conn_string = get_connection_string()
                        CONNECTION_POOL[i] = LibPQ.Connection(conn_string)
                        POOL_LAST_USED[i] = time()
                        return CONNECTION_POOL[i]
                    end
                finally
                    unlock(POOL_LOCKS[i])
                end
            end
        end
        sleep(0.1)  # Wait before trying again
    end
end

"""
Release a connection back to the pool.
"""
function release_connection(conn::LibPQ.Connection)
    for i in 1:POOL_SIZE
        if CONNECTION_POOL[i] === conn
            POOL_LAST_USED[i] = time()
            break
        end
    end
end

"""
Health check task that monitors and maintains the connection pool.
"""
function health_check_task(conn_string::String)
    while HEALTH_CHECK_RUNNING[]
        current_time = time()
        
        # Check each connection
        for i in 1:POOL_SIZE
            if trylock(POOL_LOCKS[i])
                try
                    conn = CONNECTION_POOL[i]
                    if conn !== nothing
                        # Check if connection is idle for too long
                        if current_time - POOL_LAST_USED[i] > CONNECTION_TIMEOUT
                            close(conn)
                            CONNECTION_POOL[i] = nothing
                        # Check if connection is dead
                        elseif LibPQ.status(conn) != LibPQ.CONNECTION_OK
                            close(conn)
                            CONNECTION_POOL[i] = LibPQ.Connection(conn_string)
                            POOL_LAST_USED[i] = current_time
                        end
                    end
                catch e
                    @warn "Error in health check for connection $i" exception=e
                finally
                    unlock(POOL_LOCKS[i])
                end
            end
        end
        
        sleep(HEALTH_CHECK_INTERVAL)
    end
end

"""
Clean up the connection pool.
"""
function cleanup_connection_pool()
    HEALTH_CHECK_RUNNING[] = false
    for i in 1:POOL_SIZE
        lock(POOL_LOCKS[i]) do
            if CONNECTION_POOL[i] !== nothing
                close(CONNECTION_POOL[i])
                CONNECTION_POOL[i] = nothing
            end
        end
    end
end

"""
Get the connection string from environment or configuration.
"""
function get_connection_string()::String
    # Implement your connection string logic here
    get(ENV, "DATABASE_URL", "postgresql://localhost:5432/juliaos")
end