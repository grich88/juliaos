#!/bin/bash
set -e
cd "$(dirname "$0")/juliaos-core/julia"
echo "Activating Julia environment..."
julia --project=. -e "import Pkg; Pkg.instantiate()"
echo "Starting JuliaOS backend..."
julia --project=. src/server.jl