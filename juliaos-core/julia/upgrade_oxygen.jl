#!/usr/bin/env julia

println("Starting Oxygen.jl upgrade process...")

using Pkg

# Print current status
println("\n=== Current Package Status ===")
Pkg.status()

println("\n=== Updating Package Registry ===")
Pkg.update()

println("\n=== Upgrading Oxygen.jl ===")
# Try to get the latest version - the repo showed releases up to v1.7.2
# Let's first just upgrade without specifying a version to get the latest compatible one
try
    Pkg.add("Oxygen")
    println("✓ Oxygen.jl upgrade completed successfully!")
catch e
    println("❌ Error upgrading Oxygen.jl: $e")
    println("Trying to force reinstall...")
    try
        Pkg.rm("Oxygen")
        Pkg.add("Oxygen")
        println("✓ Oxygen.jl reinstall completed successfully!")
    catch e2
        println("❌ Error reinstalling Oxygen.jl: $e2")
    end
end

println("\n=== Final Package Status ===")
Pkg.status()

println("\n=== Oxygen.jl Version Information ===")
try
    using Oxygen
    println("Oxygen.jl loaded successfully!")
catch e
    println("❌ Error loading Oxygen.jl: $e")
end

println("\nUpgrade process completed!")
println("Please restart the Julia process to ensure all changes take effect.")