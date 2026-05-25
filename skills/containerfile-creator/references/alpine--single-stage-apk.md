# Alpine Single-Stage Containerfile Example

Using Alpine package manager for the application directly:

```containerfile
# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=EDGE
ARG RELEASE=0

########################################
# Final stage
########################################
FROM alpine:3 as final

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

# Create user
ARG UID
RUN adduser -g "" -D $UID -u $UID -G root

# Create directories with correct permissions
RUN install -d -m 775 -o $UID -g 0 /download && \
    install -d -m 775 -o $UID -g 0 /licenses

# Copy licenses (OpenShift Policy)
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/Dockerfile.LICENSE
COPY --link --chown=$UID:0 --chmod=775 app/LICENSE /licenses/my-app.LICENSE

RUN --mount=type=cache,id=apk-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apk \
    apk update && apk add -u \
    -X "https://dl-cdn.alpinelinux.org/alpine/edge/main" \
    -X "https://dl-cdn.alpinelinux.org/alpine/edge/community" \
    my-app dumb-init

WORKDIR /download

VOLUME [ "/download" ]

USER $UID

STOPSIGNAL SIGINT

# Use dumb-init as PID 1 to handle signals properly
ENTRYPOINT [ "dumb-init", "--", "my-app", "--no-cache-dir" ]
CMD ["--help"]

ARG VERSION
ARG RELEASE
LABEL name="your-username/docker-my-app" \
    vendor="upstream-author" \
    maintainer="your-username" \
    url="https://github.com/your-username/docker-my-app" \
    version=${VERSION} \
    release=${RELEASE} \
    io.k8s.display-name="my-app" \
    summary="my-app: A command-line application." \
    description="A command-line application. For more information: https://github.com/upstream-org/my-app"
```
