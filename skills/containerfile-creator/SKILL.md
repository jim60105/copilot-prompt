---
name: containerfile-creator
license: GPL-3.0-or-later
description: "Create high-quality, secure, and performance-optimized Containerfiles (Dockerfiles) following best practices for multi-architecture builds, OpenShift/Kubernetes compatibility, and BuildKit cache optimization. Use when the user wants to: (1) create a new Containerfile or Dockerfile for any project (Python, Rust, Go, Node.js, .NET, or any language), (2) containerize an application with multi-stage builds, (3) optimize an existing Containerfile for security, performance, or image size, (4) review or improve container image build practices, (5) set up BuildKit cache mounts for package managers, (6) create OpenShift-compatible container images with non-root users and arbitrary UID support, (7) write a .dockerignore file, or (8) apply OCI LABEL standards."
---

# Containerfile Creator

Create secure, efficient, and maintainable container images following open source best practices.

## Workflow

1. Determine the project language/framework
2. Load the appropriate reference file for examples (see Language-Specific References below)
3. Apply the core structure and patterns from this document
4. Write the Containerfile following the Final Stage Instruction Ordering

## File Naming

- Prefer `Containerfile` over `Dockerfile`
- Use descriptive names for variants: `alpine.Containerfile`, `distroless.Containerfile`, `ubi.Containerfile`

## Required Syntax Declaration

Every file MUST start with:

```containerfile
# syntax=docker/dockerfile:1
```

## ARG Definition Block

Only `UID`, `VERSION`, and `RELEASE` go at the top level:

```containerfile
# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=EDGE
ARG RELEASE=0
```

`TARGETARCH` and `TARGETVARIANT` MUST be declared inside each stage that uses them, not globally.

## Multi-stage Build Structure

```containerfile
########################################
# Build stage
########################################
FROM python:3.13-alpine AS build

########################################
# Final stage
########################################
FROM python:3.13-alpine AS final
```

- Always name the last stage `final`
- Use 40 `#` characters for stage separators
- Only use a separate `base` stage when it requires non-trivial setup (e.g., installing system packages on UBI/Debian)

## Cache Optimization

Declare multi-arch variables inside each stage that uses cache mounts:

```containerfile
ARG TARGETARCH
ARG TARGETVARIANT
```

### Package Manager Cache Patterns

```containerfile
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

# DNF (Fedora/RHEL)
RUN --mount=type=cache,id=dnf-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/dnf \
    dnf -y install package-name
```

## Security and Permissions

### Create Non-root User

```containerfile
# Alpine
ARG UID
RUN adduser -g "" -D $UID -u $UID -G root

# Debian/Ubuntu
ARG UID
RUN groupadd -g $UID $UID && \
    useradd -l -u $UID -g $UID -m -s /bin/sh -N $UID
```

### OpenShift Compatibility (Arbitrary UID)

```containerfile
# Create directories
RUN install -d -m 775 -o $UID -g 0 /app && \
    install -d -m 775 -o $UID -g 0 /licenses

# Copy files with proper ownership
COPY --link --chown=$UID:0 --chmod=775 source dest
```

### License Files (Required)

```containerfile
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/Containerfile.LICENSE
COPY --link --chown=$UID:0 --chmod=775 project/LICENSE /licenses/project.LICENSE
```

## Secure dumb-init Usage

Use dumb-init as PID 1 for proper signal handling. Download in a separate stage with SHA256 verification:

```containerfile
########################################
# Download stage
########################################
FROM docker.io/library/debian:bookworm-slim AS download

ARG TARGETARCH
ARG TARGETVARIANT

RUN --mount=type=cache,id=apt-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=aptlists-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends curl ca-certificates

# Download dumb-init static binary (arch-aware) with SHA256 verification
RUN case "${TARGETARCH}" in \
      amd64) DUMBINIT_ARCH="x86_64"; DUMBINIT_SHA256="e874b55f3279ca41415d290c512a7ba9d08f98041b28ae7c2acb19a545f1c4df" ;; \
      arm64) DUMBINIT_ARCH="aarch64"; DUMBINIT_SHA256="b7d648f97154a99c539b63c55979cd29f005f88430fb383007fe3458340b795e" ;; \
      *) echo "unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_${DUMBINIT_ARCH}" \
    -o /dumb-init && \
    echo "${DUMBINIT_SHA256}  /dumb-init" | sha256sum -c -
```

Then copy in the final stage:

```containerfile
COPY --link --chown=$UID:0 --chmod=775 --from=download /dumb-init /usr/local/bin/dumb-init
```

### OpenShift umask Pattern

When the application creates directories at runtime, use `umask 0002` to preserve GID-0 group-write:

```containerfile
ENTRYPOINT ["dumb-init", "--"]
CMD ["sh", "-c", "umask 0002 && exec my-app"]
```

The `exec` replaces the shell so dumb-init's signal forwarding reaches the app directly.

## COPY --link Optimization

Always use `--link` flag for COPY instructions to enable layer reuse across builds:

```containerfile
COPY --link --chown=$UID:0 --chmod=775 source dest
```

Do NOT use `--link` when destination path contains symlinks that need to be followed.

## Final Stage Instruction Ordering (CRITICAL)

Follow this exact order in the final stage:

1. System cleanup (remove pip/setuptools/wheel if applicable)
2. Create user (non-root)
3. Create directories (`install -d`)
4. COPY from build (`--link --chown=$UID:0 --chmod=775`)
5. ENV (PATH and other variables)
6. WORKDIR
7. VOLUME (if applicable)
8. EXPOSE (if applicable)
9. USER $UID
10. STOPSIGNAL SIGINT
11. ENTRYPOINT / CMD
12. **ARG VERSION + ARG RELEASE + LABEL — ALWAYS LAST**

> **LABEL MUST be the very last instruction.** VERSION/RELEASE ARGs bust the cache for all subsequent instructions. Placing them last ensures maximum cache reuse.

## LABEL Standards

```containerfile
ARG VERSION
ARG RELEASE
LABEL name="project-name" \
    vendor="original-author" \
    maintainer="user-id" \
    url="https://github.com/user-id/project" \
    version=${VERSION} \
    release=${RELEASE} \
    io.k8s.display-name="Display Name" \
    summary="Brief summary" \
    description="Detailed description with website reference"
```

## Health Check

> HEALTHCHECK does not function in OCI/podman builds. Do NOT implement unless specifically requested.

When implementing:

```containerfile
COPY --link --from=ghcr.io/tarampampam/curl:8.7.1 /bin/curl /usr/local/bin/
HEALTHCHECK --interval=30s --timeout=2s --start-period=30s \
    CMD [ "curl", "--fail", "http://localhost:8080/" ]
```

## Test, Report, and Binary Stages (Optional)

### Test Stage

Run linting, type-checking, and tests inside the build. Use `--mount=type=bind` for test files to avoid caching them in layers:

```containerfile
########################################
# Test stage
########################################
FROM deps AS test

ARG TARGETARCH
ARG TARGETVARIANT

ENV PATH="/venv/bin${PATH:+:${PATH}}"

WORKDIR /app

# Install dev dependencies using separate cache to avoid conflicts
RUN --mount=type=cache,id=uv-test-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=/app/pyproject.toml \
    --mount=type=bind,source=uv.lock,target=/app/uv.lock \
    uv sync --frozen --no-install-project

COPY src/ src/

# Run quality checks and tests with bind-mounted test files
RUN --mount=type=bind,source=tests,target=/app/tests \
    --mount=type=bind,source=pyproject.toml,target=/app/pyproject.toml \
    pytest --junit-xml=/app/test-results.xml \
           --cov=src \
           --cov-report=xml:/app/coverage.xml \
           --cov-fail-under=70 \
           --verbose
```

### Report Stage

Extract test reports from the build without running the full image:

```containerfile
########################################
# Report stage
# How to: podman build --target report --output type=local,dest=./out .
########################################
FROM scratch AS report

ARG UID=1001
COPY --chown=$UID:0 --chmod=775 --from=test /app/test-results.xml /
COPY --chown=$UID:0 --chmod=775 --from=test /app/coverage.xml /
```

Extract reports locally:

```bash
podman build --target report --output type=local,dest=./out .
```

### Binary Stage

Export statically linked binaries from the build:

```containerfile
########################################
# Binary stage
# How to: podman build --output=. --target=binary .
########################################
FROM scratch AS binary
COPY --from=builder /app/binary /
```

Binary stage is only for statically linked binaries or self-contained outputs.

## Layer Cache Strategy

Install large, rarely changed packages first, then project-specific dependencies:

```containerfile
RUN uv pip install torch==2.7.0 tensorflow>=2.16.1
RUN uv pip install -r requirements.txt
```

## .containerignore/.dockerignore Template

```
**/node_modules
**/*.log
**/.git
**/.gitignore
**/.env
**/.github
**/.vscode
**/bin
**/obj
**/dist
**/tmp
```

## Language-Specific References

Load the appropriate reference file based on the project's language/pattern:

### Python

- [python--package-manager-patterns.md](references/python--package-manager-patterns.md) — UV/pip config snippets, environment setup
- [python--pip-cli-app.md](references/python--pip-cli-app.md) — pip-based CLI app + base image variants
- [python--nuitka-standalone.md](references/python--nuitka-standalone.md) — Nuitka binary compilation
- [python--ml-gpu-cuda.md](references/python--ml-gpu-cuda.md) — ML/CUDA with GPU support
- [python--grpc-service-with-test.md](references/python--grpc-service-with-test.md) — Web service with test/report/codegen stages

### Other Languages

- [golang--upx-busybox-ubi.md](references/golang--upx-busybox-ubi.md) — Go with UPX compression, busybox/UBI targets
- [rust--cargo-chef-static.md](references/rust--cargo-chef-static.md) — cargo-chef, static linking, binary export
- [nodejs--alpine.md](references/nodejs--alpine.md) — npm ci, Alpine
- [deno--vue-frontend.md](references/deno--vue-frontend.md) — Deno cache, Vue frontend, secure dumb-init

### Infrastructure / Patterns

- [dotnet--self-contained.md](references/dotnet--self-contained.md) — .NET self-contained deployment
- [scratch--static-binary.md](references/scratch--static-binary.md) — Minimal scratch image with ADD
- [nginx--frontend-spa.md](references/nginx--frontend-spa.md) — Frontend build → nginx serve
- [alpine--single-stage-apk.md](references/alpine--single-stage-apk.md) — Single-stage Alpine with apk
- [fedora-toolbox--devenv.md](references/fedora-toolbox--devenv.md) — Development environment container
