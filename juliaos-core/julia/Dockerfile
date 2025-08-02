# Use Julia 1.11.6 as base image
FROM julia:1.11.6

# Set working directory
WORKDIR /app/juliaos-core/julia

# Copy Project.toml and Manifest.toml first for better caching
COPY juliaos-core/julia/Project.toml .
COPY juliaos-core/julia/Manifest.toml* .

# Install dependencies
RUN julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Copy the rest of the application
COPY juliaos-core/julia .

# Set environment variables
ENV JULIA_NUM_THREADS=3,1
ENV PORT=8080
ENV HOST=0.0.0.0

# Expose port
EXPOSE 8080

# Start the application
CMD ["julia", "--project=.", "--threads", "3,1", "src/server.jl"]