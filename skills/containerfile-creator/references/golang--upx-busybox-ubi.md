# Golang Containerfile Examples

## Table of Contents

- [Key Patterns](#key-patterns)
- [Example: Standard (busybox final)](#example-standard-busybox-final)
- [Example: UBI Micro](#example-ubi-micro)

## Key Patterns

```containerfile
# Disable CGO to produce static binaries
ENV CGO_ENABLED=0

# Use UPX for binary compression
RUN upx --best --lzma /go/bin/binary || true
```

## Example: Standard (busybox final)

```containerfile
# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=master
ARG RELEASE=0

########################################
# Compress stage
########################################
FROM golang:1.19 as compress

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

ARG VERSION
RUN --mount=type=cache,id=apt-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=aptlists-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/lib/apt/lists \
    # Install my-go-app
    CGO_ENABLED=0 go install github.com/upstream-org/my-go-app@$VERSION && \
    # Install upx
    echo 'deb http://deb.debian.org/debian bookworm-backports main' > /etc/apt/sources.list.d/backports.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    upx-ucl && \
    # Compress my-go-app
    upx --best --lzma /go/bin/my-go-app || true; \
    # Remove upx
    apt-get purge -y upx-ucl && \
    # Make an empty directory for final stage
    mkdir -p /newdir

########################################
# Final stage
########################################
FROM busybox:1 as final

ARG UID

# Create directories with correct permissions
COPY --link --chown=$UID:0 --chmod=775 --from=compress /newdir /download
COPY --link --chown=$UID:0 --chmod=775 --from=compress /newdir /licenses

# Install dumb-init (see SKILL.md for secure download pattern)

# Copy licenses (OpenShift Policy)
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/Dockerfile.LICENSE
COPY --link --chown=$UID:0 --chmod=775 app/LICENSE /licenses/my-go-app.LICENSE

# scratch image doesn't contain CA trust store
COPY --link --from=compress /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy dist and support arbitrary user ids (OpenShift best practice)
COPY --link --chown=$UID:0 --chmod=775 --from=compress /go/bin/my-go-app /

ENV PATH="/:$PATH"

WORKDIR /download

VOLUME [ "/download" ]

USER $UID

STOPSIGNAL SIGINT

# Use dumb-init as PID 1 to handle signals properly
ENTRYPOINT [ "dumb-init", "--", "my-go-app" ]
CMD [ "-h" ]

ARG VERSION
ARG RELEASE
LABEL name="your-username/docker-my-go-app" \
    vendor="upstream-author" \
    maintainer="your-username" \
    url="https://github.com/your-username/docker-my-go-app" \
    version=${VERSION} \
    release=${RELEASE} \
    io.k8s.display-name="my-go-app" \
    summary="my-go-app: A Go application" \
    description="A Go application. For more information: https://github.com/upstream-org/my-go-app"
```

## Example: UBI Micro

```containerfile
# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=master
ARG RELEASE=0

### Build
FROM registry.access.redhat.com/ubi9/go-toolset:1.19 as compress

ARG VERSION
ARG TARGETARCH
RUN CGO_ENABLED=0 go install github.com/upstream-org/my-go-app@$VERSION && \
    # Get upx
    wget -qO - https://github.com/upx/upx/releases/download/v4.2.3/upx-4.2.3-${TARGETARCH}_linux.tar.xz | tar -Jx upx-4.2.3-${TARGETARCH}_linux/upx && \
    # Compress my-go-app
    upx-4.2.3-${TARGETARCH}_linux/upx --best --lzma go/bin/my-go-app || true; \
    rm -rf upx-4.2.3-${TARGETARCH}_linux && \
    # Make an empty directory for final stage
    mkdir -p newdir

### Final
FROM registry.access.redhat.com/ubi9/ubi-micro as final

ARG UID

# Create directories with correct permissions
COPY --link --chown=$UID:0 --chmod=775 --from=compress /opt/app-root/src/newdir /download
COPY --link --chown=$UID:0 --chmod=775 --from=compress /opt/app-root/src/newdir /licenses

# Install dumb-init (see SKILL.md for secure download pattern)

# Copy licenses (OpenShift Policy)
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/Dockerfile.LICENSE
COPY --link --chown=$UID:0 --chmod=775 app/LICENSE /licenses/my-go-app.LICENSE

# UBI micro image doesn't contain CA trust store
COPY --link --from=compress /etc/pki/ca-trust /etc/pki/ca-trust

# Copy dist and support arbitrary user ids (OpenShift best practice)
COPY --link --chown=$UID:0 --chmod=775 --from=compress /opt/app-root/src/go/bin/my-go-app /my-go-app

ENV PATH="/"

WORKDIR /download

VOLUME [ "/download" ]

USER $UID

STOPSIGNAL SIGINT

# Use dumb-init as PID 1 to handle signals properly
ENTRYPOINT [ "dumb-init", "--", "my-go-app" ]
CMD [ "-h" ]

ARG VERSION
ARG RELEASE
LABEL name="your-username/docker-my-go-app" \
    vendor="upstream-author" \
    maintainer="your-username" \
    url="https://github.com/your-username/docker-my-go-app" \
    version=${VERSION} \
    release=${RELEASE} \
    io.k8s.display-name="my-go-app" \
    summary="my-go-app: A Go application" \
    description="A Go application. For more information: https://github.com/upstream-org/my-go-app"
```

## Base Image Alternatives

The build/compress stage is identical regardless of final base image. Swap only the final `FROM` line:

| Base Image | Use Case | Notes |
|---|---|---|
| `busybox:1` | Minimal with shell | Standard example above |
| `registry.access.redhat.com/ubi9/ubi-micro` | Red Hat certified | UBI Micro example above |
| `gcr.io/distroless/static-debian12:nonroot` | No shell, no package manager | Use `ARG UID=65532` (distroless nonroot default) |
| `scratch` | Absolute minimum | Requires static binary + CA certs copy |
