# Python Common Patterns

## UV Configuration (Recommended)

```containerfile
# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# UV configuration
ENV UV_PROJECT_ENVIRONMENT=/venv
ENV VIRTUAL_ENV=/venv
ENV UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=0

# Step 1: Install dependencies ONLY (cached — deps change less often than source)
RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --frozen --no-dev --no-install-project --no-editable

# Step 2: Copy source, then install the project itself
COPY --link src/ src/
RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --frozen --no-dev --no-editable
```

> **The two-step uv sync pattern is critical for cache efficiency:**
> - Step 1 (`--no-install-project`): Installs only third-party dependencies. Cached as long as `pyproject.toml` and `uv.lock` don't change.
> - Step 2 (after `COPY src/`): Installs the project package. Rebuilt on source changes, but expensive dependency installation is cached.
> - **Do NOT combine into a single step.**

## Pip Configuration (Legacy)

```containerfile
ENV PIP_USER="true"
ARG PIP_NO_WARN_SCRIPT_LOCATION=0
ARG PIP_ROOT_USER_ACTION="ignore"
ARG PIP_NO_COMPILE="true"
ARG PIP_DISABLE_PIP_VERSION_CHECK="true"

# Install dependencies under /root/.local
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    pip install package-name

# Cleanup
RUN find "/root/.local" -name '*.pyc' -print0 | xargs -0 rm -f || true && \
    find "/root/.local" -type d -name '__pycache__' -print0 | xargs -0 rm -rf || true
```

### Environment Setup

```containerfile
# For uv projects
ENV PATH="/venv/bin:$PATH"
ENV PYTHONPATH="/venv/lib/python3.11/site-packages"

# For pip projects
ENV PATH="/home/$UID/.local/bin:$PATH"
```
