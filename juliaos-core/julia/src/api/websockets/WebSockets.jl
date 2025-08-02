# src/api/websockets/WebSockets.jl

"""
WebSockets module for JuliaOS API.
"""
module WebSockets

include("AlertsWebSocket.jl")
include("WebSocketManager.jl")

using .AlertsWebSocket
using .WebSocketManager

export AlertsWebSocket, WebSocketManager

end # module