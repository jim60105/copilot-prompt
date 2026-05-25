# Scratch (Minimal Image) Containerfile Example

Using scratch base with static binaries and ADD for downloading:

```containerfile
# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=2026.08.22
ARG RELEASE=0

########################################
# folder stage
########################################
FROM alpine:3 AS folder

# Create directories with correct permissions
ARG UID
RUN install -d -m 775 -o $UID -g 0 /newdir

########################################
# Final stage
########################################
FROM scratch AS final

# Copy CA trust store
COPY --from=alpine:3 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy dynamic linker and required shared libraries for the musllinux binary
COPY --from=alpine:3 /lib/ld-musl-x86_64.so.1 /lib/
COPY --from=alpine:3 /usr/lib/libz.so.1 /usr/lib/

ARG UID

# Create directories with correct permissions
COPY --chown=$UID:0 --chmod=775 --from=folder /newdir /licenses
COPY --chown=$UID:0 --chmod=775 --from=folder /newdir /etc/my-app-plugins/my-plugin
COPY --link --chown=$UID:0 --chmod=775 --from=folder /newdir /download
COPY --link --chown=$UID:0 --chmod=775 --from=folder /newdir /tmp

# Copy licenses (OpenShift Policy)
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/Dockerfile.LICENSE
COPY --link --chown=$UID:0 --chmod=775 app/LICENSE /licenses/my-app.LICENSE

# Install dumb-init (see SKILL.md for secure download pattern)

# External tool
COPY --link --chown=$UID:0 --chmod=775 --from=ghcr.io/your-username/my-tool:latest /my-tool /usr/bin/

# External plugin
COPY --link --chown=$UID:0 --chmod=775 --from=ghcr.io/your-username/my-tool:latest /client /etc/my-app-plugins/my-plugin

# Ensure the cache is not reused when installing the application
ARG RELEASE
ARG VERSION

# Application binary (using musllinux build for musl libc compatibility)
ADD --link --chown=$UID:0 --chmod=775 https://github.com/upstream-org/my-app/releases/download/${VERSION}/my-app_musllinux /usr/bin/my-app

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
