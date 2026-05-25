# Node.js Containerfile Examples

## Table of Contents

- [Key Patterns](#key-patterns)
- [Example: Node.js with Alpine](#example-nodejs-with-alpine)

## Key Patterns

```containerfile
# Use Alpine base image
FROM node:lts-alpine AS build

# Mount package files for install (avoid COPY for cache efficiency)
RUN --mount=source=package.json,target=package.json \
    --mount=source=package-lock.json,target=package-lock.json \
    npm ci && npm cache clean --force
```

## Example: Node.js with Alpine

```containerfile
# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=EDGE
ARG RELEASE=0

FROM node:lts-alpine AS build

WORKDIR /app

RUN --mount=source=app/package.json,target=package.json \
    --mount=source=app/package-lock.json,target=package-lock.json \
    --mount=source=app/post-install.js,target=post-install.js \
    npm ci && npm cache clean --force

COPY app/. /app/.

FROM node:lts-alpine AS final

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

ARG UID

# Create directories with correct permissions
RUN install -d -m 775 -o $UID -g 0 /licenses && \
    install -d -m 775 -o $UID -g 0 /app && \
    install -d -m 775 -o $UID -g 0 /app/data

# Runtime dependencies
RUN --mount=type=cache,id=apk-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apk \
    apk update && apk add -u \
    dumb-init=1.2.5-r3 \
    git=2.45.2-r0

# Copy licenses (OpenShift Policy)
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/Dockerfile.LICENSE
COPY --link --chown=$UID:0 --chmod=775 app/LICENSE /licenses/LICENSE

# Copy dist
COPY --from=build --chown=$UID:0 --chmod=775 /app /app

# Copy default config
COPY --from=build --chown=$UID:0 --chmod=775 /app/default/config.yaml /app/

RUN \
    # Listen for connections on all interfaces
    sed -i 's/listen: false/listen: true/' /app/config.yaml && \
    # Disable whitelist mode
    sed -i 's/whitelistMode: true/whitelistMode: false/' /app/config.yaml && \
    # Enable multi-user mode
    sed -i 's/enableUserAccounts: false/enableUserAccounts: true/' /app/config.yaml

WORKDIR /app

EXPOSE 8000

VOLUME [ "/app/data" ]

# Use dumb-init as PID 1 to handle signals properly
ENTRYPOINT [ "dumb-init", "--", "node", "server.js" ]

ARG VERSION
ARG RELEASE
LABEL name="your-username/docker-my-node-app" \
    vendor="upstream-author" \
    maintainer="your-username" \
    url="https://github.com/your-username/docker-my-node-app" \
    version=${VERSION} \
    release=${RELEASE} \
    io.k8s.display-name="my-node-app" \
    summary="my-node-app: A Node.js application." \
    description="A Node.js web application. For more information: https://github.com/upstream-org/my-node-app"
```
