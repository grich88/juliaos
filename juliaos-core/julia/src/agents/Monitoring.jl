# src/agents/Monitoring.jl

"""
Monitoring module for Agents.
"""
module Monitoring

using Dates
using UUIDs

# Alert types and events
struct AlertEvent
    id::String
    type::String
    message::String
    severity::String
    timestamp::DateTime
    metadata::Dict{String, Any}
end

# Alert subscriber
struct AlertSubscriber
    id::String
    callback::Function
    cleanup::Function
end

# Export types and functions
export AlertEvent, AlertSubscriber

end # module