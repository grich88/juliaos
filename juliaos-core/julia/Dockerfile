# Use Julia 1.11.6 as base image
FROM julia:1.11.6

# Set working directory
WORKDIR /app/juliaos-core/julia

# Copy Project.toml and Manifest.toml first for better caching
COPY juliaos-core/julia/Project.toml .
COPY juliaos-core/julia/Manifest.toml* .

# Install Python dependencies
RUN apt-get update && apt-get install -y python3 python3-pip python3-venv python3-full

# Set up Python virtual environment
ENV VIRTUAL_ENV=/app/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Configure PyCall to use our virtual environment Python
ENV PYTHON=/app/venv/bin/python3
RUN julia -e 'using Pkg; Pkg.add("PyCall"); Pkg.build("PyCall")'

# Copy Python package files first
COPY leverage /app/leverage/

# Install Python package in virtual environment
RUN cd /app/leverage && \
    pip install --upgrade pip setuptools wheel && \
    pip install -e . && \
    python3 -c "import juliaos.leverage; print('juliaos.leverage module installed successfully')"

# Install Julia dependencies
RUN julia --project=. -e "import Pkg; Pkg.instantiate()"

# Copy the rest of the application
COPY juliaos-core/julia .

# Set environment variables
ENV JULIA_NUM_THREADS=3,1
ENV PORT=8080
ENV HOST=0.0.0.0

# Expose port
EXPOSE 8080

# Set entrypoint for production
CMD ["julia", "--project=.", "src/server.jl"]