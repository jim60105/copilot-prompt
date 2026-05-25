# Python: pip-based CLI Application

```containerfile
# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=2024.04.09
ARG RELEASE=0

########################################
# Build stage
########################################
FROM python:3.12-alpine as build

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /app

# Install under /root/.local
ENV PIP_USER="true"
ARG PIP_NO_WARN_SCRIPT_LOCATION=0
ARG PIP_ROOT_USER_ACTION="ignore"
ARG PIP_NO_COMPILE="true"
ARG PIP_DISABLE_PIP_VERSION_CHECK="true"

ARG VERSION
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    pip3.12 install -U --force-reinstall pip setuptools wheel && \
    pip3.12 install my-app==$VERSION && \
    # Cleanup
    find "/root/.local" -name '*.pyc' -print0 | xargs -0 rm -f || true ; \
    find "/root/.local" -type d -name '__pycache__' -print0 | xargs -0 rm -rf || true ;

########################################
# Final stage
########################################
FROM python:3.12-alpine as final

RUN pip3.12 uninstall -y setuptools pip wheel && \
    rm -rf /root/.cache/pip

# Create user
ARG UID
RUN adduser -g "" -D $UID -u $UID -G root

# Create directories with correct permissions
RUN install -d -m 775 -o $UID -g 0 /download && \
    install -d -m 775 -o $UID -g 0 /licenses

# Install dumb-init (see SKILL.md for secure download pattern)

# Copy licenses (OpenShift Policy)
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/Dockerfile.LICENSE
COPY --link --chown=$UID:0 --chmod=775 app/LICENSE /licenses/my-app.LICENSE

# Copy dist and support arbitrary user ids (OpenShift best practice)
# https://docs.openshift.com/container-platform/4.14/openshift_images/create-images.html#use-uid_create-images
COPY --link --chown=$UID:0 --chmod=775 --from=build /root/.local /home/$UID/.local

ENV PATH="/home/$UID/.local/bin:$PATH"

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

### Base Image Variants

The build pattern is identical across base images. Key differences by target:

| Base Image | Final FROM | User Creation | Unique Patterns |
|---|---|---|---|
| **Alpine** (above) | `python:3.12-alpine` | `adduser -D` | Simplest; `apk` for runtime deps |
| **UBI Minimal** | `ubi9/ubi-minimal` | built-in numeric UID | `microdnf` for packages; add `rm /bin/sh /bin/bash` for shell hardening |
| **Distroless** | `al3xos/python-distroless:3.12-debian12` | uses `monty` (UID 1000) | Build in `python:3.12-bookworm`; copy to `/home/monty/.local`; no shell available |

**UBI-specific adaptations:**
- Install Python manually: `microdnf install python3.11`
- Use a shared `base` stage for both build and final
- Optional shell removal: `rm /bin/echo /bin/ln /bin/rm /bin/sh /bin/bash`

**Distroless-specific adaptations:**
- Build in full Debian image, copy artifacts to distroless final
- Use `/home/monty/.local` instead of `/home/$UID/.local`
- Default `ARG UID=1000` (distroless monty user)
