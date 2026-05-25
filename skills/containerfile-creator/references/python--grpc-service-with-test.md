# Python: Web Service with Test and Report Stages

Full example with dependency caching, protobuf codegen, quality checks (linting/type-checking/testing), report extraction, and OpenAPI export:

```containerfile
# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=EDGE
ARG RELEASE=0

########################################
# Dependencies stage
########################################
FROM python:3.13-slim AS deps

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /app

# Install uv (pinned version to avoid non-deterministic builds)
COPY --from=ghcr.io/astral-sh/uv:0.11.7 /uv /uvx /bin/

ENV UV_PROJECT_ENVIRONMENT=/venv
ENV VIRTUAL_ENV=/venv
ENV UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=0

# Install dependencies first (cached layer, changes less often than source)
RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --frozen --no-dev --no-install-project --no-editable

########################################
# Codegen stage — generate protobuf Python stubs
########################################
FROM deps AS codegen

ARG TARGETARCH
ARG TARGETVARIANT

ENV PATH="/venv/bin${PATH:+:${PATH}}"

# Install dev dependencies (includes grpcio-tools for codegen)
RUN --mount=type=cache,id=uv-codegen-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=/app/pyproject.toml \
    --mount=type=bind,source=uv.lock,target=/app/uv.lock \
    uv sync --frozen --no-install-project

# Generate proto stubs
COPY protos/ protos/
COPY scripts/generate_proto.py scripts/generate_proto.py
RUN python scripts/generate_proto.py

########################################
# Build stage
########################################
FROM deps AS build

ARG TARGETARCH
ARG TARGETVARIANT

# Copy source and generated proto stubs
COPY src/ src/
COPY --from=codegen /app/src/generated/ src/generated/

RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --frozen --no-dev --no-editable

########################################
# OpenAPI export stage
########################################
FROM build AS openapi-export

ENV PATH="/venv/bin${PATH:+:${PATH}}"
ENV PYTHONPATH="/app/src:/venv/lib/python3.13/site-packages"

WORKDIR /app

RUN --mount=type=bind,source=scripts/export_openapi.py,target=/app/scripts/export_openapi.py \
    python scripts/export_openapi.py --output /app/openapi.yaml

########################################
# OpenAPI output stage
# How to: podman build --target openapi-output --output type=local,dest=./out .
########################################
FROM scratch AS openapi-output

ARG UID=1001
COPY --chown=$UID:0 --chmod=775 --from=openapi-export /app/openapi.yaml /

########################################
# Test stage
########################################
FROM deps AS test

ARG TARGETARCH
ARG TARGETVARIANT

ENV PATH="/venv/bin${PATH:+:${PATH}}"
ENV PYTHONPATH="/app/src:/venv/lib/python3.13/site-packages"

WORKDIR /app

# Install dev dependencies using separate cache to avoid conflicts
RUN --mount=type=cache,id=uv-test-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=/app/pyproject.toml \
    --mount=type=bind,source=uv.lock,target=/app/uv.lock \
    uv sync --frozen --no-install-project

# Copy source and generated proto stubs
COPY src/ src/
COPY --from=codegen /app/src/generated/ src/generated/

# Run quality checks and tests with bind-mounted test files
RUN --mount=type=bind,source=tests,target=/app/tests \
    --mount=type=bind,source=.flake8,target=/app/.flake8 \
    --mount=type=bind,source=pyproject.toml,target=/app/pyproject.toml \
    --mount=type=bind,source=.coveragerc,target=/app/.coveragerc \
    black --check --line-length=100 --skip-string-normalization src/ tests/ && \
    flake8 src/ && \
    mypy src/ --no-incremental && \
    pytest --junit-xml=/app/test-results.xml \
           --cov=src \
           --cov-report=xml:/app/coverage.xml \
           --cov-fail-under=70 \
           --verbose

########################################
# Report stage
# How to: podman build --target report --output type=local,dest=./out .
########################################
FROM scratch AS report

ARG UID=1001
COPY --chown=$UID:0 --chmod=775 --from=test /app/test-results.xml /
COPY --chown=$UID:0 --chmod=775 --from=test /app/coverage.xml /

########################################
# Final stage
########################################
FROM python:3.13-slim AS final

RUN pip uninstall -y setuptools pip wheel && \
    rm -rf /root/.cache/pip

# Create user
ARG UID
RUN useradd --badname -l -u $UID -g 0 -s /usr/sbin/nologin -N $UID

# Create directories with correct permissions
RUN install -d -m 775 -o $UID -g 0 /app && \
    install -d -m 775 -o $UID -g 0 /licenses

# Copy dist and support arbitrary user ids (OpenShift best practice)
COPY --link --chown=$UID:0 --chmod=775 --from=build /venv /venv

# Environment setup
ENV PATH="/venv/bin${PATH:+:${PATH}}"
ENV PYTHONPATH="/venv/lib/python3.13/site-packages"

WORKDIR /app

EXPOSE 8080

USER $UID

STOPSIGNAL SIGINT

CMD ["uvicorn", "my_project.my_module:app", "--host", "0.0.0.0", "--port", "8080"]

ARG VERSION
ARG RELEASE
LABEL name="my-python-service" \
    vendor="upstream-author" \
    maintainer="your-username" \
    url="https://github.com/your-username/my-python-service" \
    version=${VERSION} \
    release=${RELEASE} \
    io.k8s.display-name="My Python Service" \
    summary="A Python gRPC/REST service" \
    description="A Python service with gRPC and REST API. For more information: https://github.com/your-username/my-python-service"
```

Key patterns demonstrated:
- **Shared `deps` stage**: Both build and test inherit from the same dependency base
- **Separate cache IDs for test**: `uv-test-$TARGETARCH$TARGETVARIANT` avoids conflicts with production deps
- **Bind mounts for test files**: Test code is not cached in layers
- **Report extraction**: `podman build --target report --output type=local,dest=./out .`
- **OpenAPI export**: Generate and extract API specs during build
- **Codegen stage**: Generate protobuf stubs before build and test
