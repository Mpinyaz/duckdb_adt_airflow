# 1. Infer PYTHON_VERSION from .env (injected via Docker Compose build args)
ARG PYTHON_VERSION

# ==============================================================================
# Shared Base Image: Inferred Python + Astral uv + System Dependencies
# ==============================================================================
FROM python:${PYTHON_VERSION:-3.12}-slim AS base

# Re-declare ARG after FROM to persist it inside the container environment
ARG PYTHON_VERSION
ENV PYTHON_VERSION=${PYTHON_VERSION:-3.12}

# Install uv from official Astral image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Environment settings for optimal Docker & uv performance
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:$PATH"

WORKDIR /app

# Install common system packages needed across tools (ODBC, C++ tools, git, curl)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        git \
        build-essential \
        unixodbc-dev \
        curl \
 && rm -rf /var/lib/apt/lists/*

# Pre-cache project dependencies
COPY pyproject.toml uv.lock ./
COPY dbt/pyproject.toml dbt/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-project

# Default command to verify Python and uv
CMD ["python", "-c", "import sys, os; print(f'Base image running Python {sys.version.split()[0]} (inferred from .env: {os.getenv(\"PYTHON_VERSION\")}) and uv')"]
