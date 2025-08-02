# Use Julia 1.11.6 as base image
FROM julia:1.11.6

# Set working directory
WORKDIR /app/juliaos-core/julia

# Copy Project.toml and Manifest.toml first for better caching
COPY juliaos-core/julia/Project.toml .
COPY juliaos-core/julia/Manifest.toml* .

# Install Python and pip
RUN apt-get update && apt-get install -y python3 python3-pip

# Copy Python package files first
COPY leverage/setup.py /app/leverage/
COPY leverage/pyproject.toml /app/leverage/
COPY leverage/*.py /app/leverage/

# Install Python package
RUN cd /app/leverage && pip3 install -e .

# Install Julia dependencies
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