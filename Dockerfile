# Ants Worker - Distributed Compute
#
# Build:
#   docker build -t antsatwork/worker .
#
# Run (CPU):
#   docker run -d antsatwork/worker
#
# Run (GPU):
#   docker run -d --gpus all antsatwork/worker

FROM python:3.11-slim AS base

# Metadata
LABEL org.opencontainers.image.title="Ants Worker"
LABEL org.opencontainers.image.description="Distributed compute worker for Ants at Work colony"
LABEL org.opencontainers.image.source="https://github.com/antsatwork/worker"

# Create non-root user
RUN useradd --create-home --shell /bin/bash worker

# Set working directory
WORKDIR /app

# Install dependencies first (caching)
COPY pyproject.toml .
RUN pip install --no-cache-dir build && \
    pip install --no-cache-dir . && \
    rm -rf /root/.cache

# Copy source
COPY ants_worker/ ants_worker/

# Switch to non-root user
USER worker

# Create config directory
RUN mkdir -p ~/.ants

# Default command
CMD ["ants-worker", "start"]

# Health check
HEALTHCHECK --interval=60s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "print('ok')" || exit 1


# GPU variant
FROM nvidia/cuda:12.2-runtime-ubuntu22.04 AS gpu

LABEL org.opencontainers.image.title="Ants Worker (GPU)"

# Install Python
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash worker

WORKDIR /app

# Install with GPU support
COPY pyproject.toml .
RUN pip3 install --no-cache-dir ".[gpu]" && \
    rm -rf /root/.cache

COPY ants_worker/ ants_worker/

USER worker
RUN mkdir -p ~/.ants

CMD ["ants-worker", "start", "--gpu"]

HEALTHCHECK --interval=60s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "print('ok')" || exit 1
