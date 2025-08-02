# Import JuliaOS module
using JuliaOS

# Import API related modules
include("api/Main.jl")
using .Main

# Initialize framework
@info "Initializing JuliaOS Framework..."
JuliaOS.initialize()
@info "JuliaOS Framework initialized successfully."

# Start server
main() 