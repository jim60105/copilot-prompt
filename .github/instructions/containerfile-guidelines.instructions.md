---
applyTo: '**/*.Dockerfile,**/*.Containerfile'
---
# Dockerfile/Containerfile Authoring Guide

## Overview

This guidelines focuses on building high-quality, secure, and performance-optimized container images, supporting multi-architecture builds and following OpenShift and Kubernetes best practices. The author prefers using `Containerfile` to show support for open source technologies.

## File Structure and Naming Conventions

### File Naming

- Prefer `Containerfile` over `Dockerfile`
- Use descriptive names for different base images:
  - `alpine.Dockerfile` - Based on Alpine Linux
  - `distroless.Dockerfile` - Based on Google Distroless
  - `ubi.Dockerfile` - Based on Red Hat UBI
  - `nuitka.Dockerfile` - For special use cases (e.g., Nuitka compilation)

### Required Syntax Declaration

```dockerfile
# syntax=docker/dockerfile:1
```

## Dockerfile Structure Guidelines

### 1. ARG Definition Block

Define all ARGs at the top of the file, using standard variables:

```dockerfile
# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=EDGE
ARG RELEASE=0
ARG NAME=app  # For Rust projects
```

### 2. Multi-stage Build Structure

Use clear stage naming and comment separation:

```dockerfile
########################################
# Base stage
########################################
FROM alpine:3 AS base

########################################
# Build stage
########################################
FROM base AS build

########################################
# Final stage
########################################
FROM base AS final
```

> [!NOTE]  
> Always name the last stage as `final`, even if there is only one stage. This ensures consistency and clarity in multi-stage builds and CI usage.

### 3. Stage Comment Guidelines

- Use 40 `#` characters to separate stages
- Stage names in English, concise and clear
- Include a brief description of the stage's purpose

## Cache Optimization Strategies

### BuildKit Cache Mode

Use a unified cache strategy for different package managers:

```dockerfile
# Alpine APK
RUN --mount=type=cache,id=apk-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apk \
    apk update && apk add -u package-name

# Debian/Ubuntu APT
RUN --mount=type=cache,id=apt-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=aptlists-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends package-name

# Python PIP
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    pip install package-name

# Python UV
RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    uv pip install package-name
```

### Multi-architecture Support

Always define multi-arch variables:

```dockerfile
# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT
```

## Security and Permission Management

### Create Non-root User

```dockerfile
# Alpine
ARG UID
RUN adduser -g "" -D $UID -u $UID -G root

# Debian/Ubuntu
ARG UID
RUN groupadd -g $UID $UID && \
    useradd -l -u $UID -g $UID -m -s /bin/sh -N $UID
```

### OpenShift Compatibility

Support arbitrary UID permission settings:

```dockerfile
# Create directories
RUN install -d -m 775 -o $UID -g 0 /app && \
    install -d -m 775 -o $UID -g 0 /licenses

# Copy files
COPY --link --chown=$UID:0 --chmod=775 source dest
```

### License File Management

Always copy license files to the specified location:

```dockerfile
# Copy licenses (OpenShift Policy)
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/Dockerfile.LICENSE
COPY --link --chown=$UID:0 --chmod=775 project/LICENSE /licenses/project.LICENSE
```

## Tools and Dependency Management

### Use Static Binaries

Prefer pre-built static tools:

```dockerfile
# ffmpeg (statically compiled and UPX compressed)
COPY --link --from=ghcr.io/jim60105/static-ffmpeg-upx:7.0-1 /ffmpeg /usr/bin/
COPY --link --from=ghcr.io/jim60105/static-ffmpeg-upx:7.0-1 /ffprobe /usr/bin/

# dumb-init (signal handling)
COPY --link --from=ghcr.io/jim60105/static-ffmpeg-upx:7.0-1 /dumb-init /usr/bin/

# curl (health check)
COPY --link --from=ghcr.io/tarampampam/curl:8.7.1 /bin/curl /usr/local/bin/
```

### Package Installation Best Practices

```dockerfile
# APT installation
RUN apt-get update && apt-get install -y --no-install-recommends \
    package1 \
    package2 \
    package3

# Version pinning (Alpine)
RUN apk add -u \
    dumb-init=1.2.5-r3 \
    git=2.45.2-r0
```

## Language-specific Guidelines

### Python Projects

Choose between pip or uv based on your project needs:

#### Option A: Using UV (Recommended for new projects)

```dockerfile
# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# UV configuration
ENV UV_PROJECT_ENVIRONMENT=/venv
ENV VIRTUAL_ENV=/venv
ENV UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=0

# Create virtual environment and install dependencies
RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    uv venv /venv && \
    uv pip install package-name

# For projects with pyproject.toml and uv.lock
RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --frozen --no-dev
```

#### Option B: Using pip (For compatibility/legacy projects)

```dockerfile
# pip optimization
ENV PIP_USER="true"
ARG PIP_NO_WARN_SCRIPT_LOCATION=0
ARG PIP_ROOT_USER_ACTION="ignore"
ARG PIP_NO_COMPILE="true"
ARG PIP_DISABLE_PIP_VERSION_CHECK="true"

# Install dependencies under /root/.local
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    pip install package-name

# Cleanup strategy (for both pip and uv)
RUN find "/root/.local" -name '*.pyc' -print0 | xargs -0 rm -f || true && \
    find "/root/.local" -type d -name '__pycache__' -print0 | xargs -0 rm -rf || true
```

#### Environment Setup

```dockerfile
# For uv projects: Use virtual environment path
ENV PATH="/venv/bin:$PATH"
ENV PYTHONPATH="/venv/lib/python3.11/site-packages"

# For pip projects: Use user installation path
ENV PATH="/root/.local/bin:$PATH"
```

### Rust Projects

```dockerfile
# Use cargo-chef for build cache optimization
FROM lukemathwalker/cargo-chef:latest-rust-alpine AS chef

# Set static linking
ENV RUSTFLAGS="-C target-feature=+crt-static"

# Planner stage
FROM chef AS planner
RUN cargo chef prepare --recipe-path recipe.json

# Cook stage (build dependencies)
FROM chef AS cook
RUN cargo chef cook --release --target x86_64-unknown-linux-musl --recipe-path recipe.json
```

### Node.js Projects

```dockerfile
# Use Alpine base image
FROM node:lts-alpine AS build

# Clean cache
RUN npm ci && npm cache clean --force

# Runtime stage
FROM node:lts-alpine AS final
```

### .NET Projects

For .NET 8 applications (following Visual Studio patterns):

```dockerfile
# Base image with runtime dependencies (self-contained deployments usually use runtime-deps)
FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine AS base
WORKDIR /app

# Debug stage (separate from production)
FROM mcr.microsoft.com/dotnet/runtime:8.0-alpine AS debug
# Debug-specific dependencies
ENV PATH="/venv/bin:$PATH"

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
ARG BUILD_CONFIGURATION=Release
ARG TARGETARCH
WORKDIR /src

# Copy project file and restore dependencies
COPY ["app.csproj", "."]
RUN dotnet restore -a $TARGETARCH "app.csproj"

# Publish stage
FROM build AS publish
COPY . .
RUN dotnet publish "app.csproj" -a $TARGETARCH -c $BUILD_CONFIGURATION \
    -o /app/publish --self-contained true

# Final production image
FROM base AS final
ARG APP_UID=1001
ENV PATH="/app:$PATH"

RUN mkdir -p /app && chown -R $APP_UID:$APP_UID /app
COPY --from=publish --chown=$APP_UID:$APP_UID /app/publish/app /app/app

USER $APP_UID
ENTRYPOINT ["/app/app"]
```

Key .NET patterns:

- Use `runtime-deps` base image for self-contained deployments
- Enable `PublishTrimmed=true` and `PublishSingleFile=true` in `.csproj`
- Separate debug and production stages
- Use `--self-contained true` for deployment
- Include TrimmerRootAssembly directives for reflection-heavy libraries

### Golang Projects

```dockerfile
# Disable CGO to produce static binaries
ENV CGO_ENABLED=0

# Use UPX for compression
RUN upx --best --lzma /go/bin/binary || true
```

## Runtime Environment Settings

### Required Runtime Settings

```dockerfile
# Working directory
WORKDIR /app

# Persistent directories
VOLUME [ "/data", "/tmp" ]

# User switch
USER $UID

# Signal handling
STOPSIGNAL SIGINT

# Use dumb-init as PID 1
ENTRYPOINT [ "dumb-init", "--", "command" ]
CMD [ "--help" ]
```

### Health Check (if applicable)

> [!WARNING]  
> HEALTHCHECK does not function in OCI image builds and podman builds. Do not implement healthcheck in the Containerfile unless the user specifically asks for it.

When implementing health checks, you need to include the curl binary from the static curl image:

```dockerfile
# curl for healthcheck
COPY --link --from=ghcr.io/tarampampam/curl:8.7.1 /bin/curl /usr/local/bin/

HEALTHCHECK --interval=30s --timeout=2s --start-period=30s \
    CMD [ "curl", "--fail", "http://localhost:8080/" ]
```

## LABEL Standards

### Required Labels

```dockerfile
ARG VERSION
ARG RELEASE
LABEL name="project-name" \
    # Authors for the main application
    vendor="original-author" \
    # Maintainer for this container image
    maintainer="jim60105" \
    # Containerfile source repository
    url="https://github.com/jim60105/project" \
    version=${VERSION} \
    # This should be a number, incremented with each change
    release=${RELEASE} \
    io.k8s.display-name="Display Name" \
    summary="Brief summary of the application" \
    description="Detailed description with website reference: https://example.com"
```

## Commenting and Documentation

### Comment Style

- Write comments in English
- Include relevant GitHub issues or documentation links
- Explain the reason for special settings
- Provide useful reference information

```dockerfile
# This is needed for OpenShift compatibility
# https://docs.openshift.com/container-platform/4.14/openshift_images/create-images.html

#! UPX will skip small files and large files
# https://github.com/upx/upx/blob/5bef96806860382395d9681f3b0c69e0f7e853cf/src/p_unix.cpp#L80
upx --best --lzma /binary || true
```

## ML/AI Project Special Considerations

### CUDA Support

```dockerfile
# Partial CUDA toolkit installation instead of full installation
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Fix missing TensorRT link
RUN ln -s /usr/lib/x86_64-linux-gnu/libnvinfer.so /usr/lib/x86_64-linux-gnu/libnvinfer.so.7
```

## Build Parameters and Flexible Design

### Conditional Build

```dockerfile
# Allow skipping certain steps to reduce image size
ARG SKIP_REQUIREMENTS_INSTALL=
FROM prepare_build${SKIP_REQUIREMENTS_INSTALL:+_empty} AS build
```

### Multi-image Support

```dockerfile
# Support conditional selection of different base images
FROM prepare_base_$TARGETARCH$TARGETVARIANT AS base
```

## Performance Optimization

### COPY Optimization

```dockerfile
# Use --link to reuse already built layers in subsequent builds with --cache-from
# This allows layer reuse even if previous layers have changed, especially important 
# for multi-stage builds and when rebasing images on updated base images
COPY --link --chown=$UID:0 --chmod=775 source dest
```

> [!TIP]  
> Use `--link` when you want to optimize layer cache reuse in multi-stage builds or when frequently rebuilding images with changing base layers. This is particularly beneficial in CI/CD pipelines where base images are regularly updated.

> [!IMPORTANT]  
> Do NOT use `--link` when your destination path contains symlinks that need to be followed. With `--link`, COPY/ADD commands cannot read files from the previous state or follow symlinks in the destination directory. The final destination path will always contain only directories, not symlinks.

> [!NOTE]  
> If you don't rely on symlink-following behavior in destination paths, using `--link` is always recommended for better cache reuse and equivalent or better performance.

### Layer Cache Strategy

```dockerfile
# Install large, rarely changed packages first
RUN uv pip install \
    torch==2.7.0 \
    tensorflow>=2.16.1

# Then install project-specific dependencies
RUN uv pip install -r requirements.txt
```

## Debugging and Testing

### Binary Stage (optional)

```dockerfile
########################################
# Binary stage
# How to: docker build --output=. --target=binary .
########################################
FROM scratch AS binary

COPY --from=builder /app/binary /
```

> [!IMPORTANT]  
> The binary stage is only applicable when the output binary file is either fully statically linked or relies on runtime dependencies; otherwise, in many cases, the extracted content cannot run. When implementing this stage, a review must be conducted to ensure it meets the requirements and to warn users.

### Test Stage

```dockerfile
########################################
# Test stage
########################################
FROM builder AS test

RUN cargo test --release --all-targets --locked
```

## Summary

Remember, the goal of these guidelines is to build secure, efficient, and maintainable container images while following open source best practices and industry standards. Focus on:

- **Security**: Non-root users, principle of least privilege
- **Performance**: Multi-stage builds, BuildKit cache, UPX compression
- **Maintainability**: Clear comments, standardized structure
- **Compatibility**: OpenShift support, multi-arch builds
- **Best Practices**: Static tools, minimized image size

When writing new Dockerfile/Containerfile files, refer to the relevant templates in this project and follow these guidelines.
