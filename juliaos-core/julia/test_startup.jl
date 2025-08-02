#!/usr/bin/env julia

# Simple startup test to verify the backend loads without hanging
println("Testing JuliaOS startup...")

try
    println("Loading JuliaOS framework...")
    using JuliaOS
    println("✅ JuliaOS loaded successfully")
    
    println("Testing framework initialization...")
    JuliaOS.initialize_framework()
    println("✅ Framework initialized successfully")
    
    println("Testing API imports...")
    using .API.Routes
    println("✅ Routes loaded successfully")
    
    println("🎉 All startup tests passed!")
    println("Backend should deploy successfully on Render")
    
catch e
    println("❌ Startup test failed:")
    println(e)
    if isa(e, LoadError)
        println("Stack trace:")
        for (exc, bt) in Base.catch_stack()
            showerror(stdout, exc, bt)
            println()
        end
    end
    exit(1)
end