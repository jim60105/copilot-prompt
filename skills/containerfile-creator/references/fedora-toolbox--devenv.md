# Fedora Toolbox Containerfile Example

Development environment container pattern:

```containerfile
# syntax=docker/dockerfile:1
ARG UID=1000
ARG VERSION=EDGE
ARG RELEASE=0
ARG BASE_IMAGE=registry.fedoraproject.org/fedora-toolbox:42

########################################
# Base stage
########################################
FROM ${BASE_IMAGE} AS base

# Set dnf config
RUN cat <<-"EOF" > /etc/dnf/dnf.conf
[main]
install_weak_deps=False
tsflags=nodocs
EOF

########################################
# Font unpack stage
########################################
FROM base AS font-unpacker

WORKDIR /fonts

ADD https://github.com/font-author/iansui/releases/download/v1.000/iansui.zip /tmp/iansui.zip
ADD https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Hack.zip /tmp/hack.zip

RUN unzip -uo /tmp/iansui.zip -d /fonts/iansui && \
    unzip -uo /tmp/hack.zip -d /fonts/hack

########################################
# Host runner stage
########################################
FROM base AS host-runner

COPY --chown=$UID:0 --chmod=775 base/host-runner /host-runner

WORKDIR /host-runner

RUN bins=( \
    "flatpak" \
    "buildah" \
    "skopeo" \
    "docker" \
    "rpm-ostree" \
    "systemctl" \
    "xdg-open" \
    ); \
    for f in "${bins[@]}"; do \
    ln -s host-runner "/host-runner/$f";\
    done

########################################
# Final stage
########################################
FROM base AS final

# Create directories with correct permissions
ARG UID
RUN install -d -m 775 -o $UID -g 0 /licenses

# Copy licenses (OpenShift Policy)
COPY --chown=$UID:0 --chmod=775 LICENSE /licenses/Containerfile.LICENSE

# COPY host-runner
COPY --chown=$UID:0 --chmod=775 --from=host-runner /host-runner /usr/local/bin

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

# Make sure the cache is refreshed
ARG RELEASE

# Install utilities
RUN --mount=type=cache,id=dnf-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/dnf \
    dnf -y upgrade && \
    dnf -y install \
    xdg-utils \
    jq \
    zsh \
    vim

# Install gh-cli
RUN --mount=type=cache,id=dnf-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/dnf \
    dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo && \
    dnf -y install gh --repo gh-cli

# Fonts
COPY --chown=$UID:0 --chmod=775 --from=font-unpacker /fonts /usr/local/share/fonts
RUN --mount=type=cache,id=dnf-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/dnf \
    dnf -y install \
    google-noto-sans-cjk-fonts \
    google-noto-color-emoji-fonts \
    cascadia-fonts-all

# Install development tools
RUN --mount=type=cache,id=dnf-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/dnf \
    dnf -y install @development-tools @c-development openssl-devel cmake ninja-build pkg-config

# Install .NET
RUN --mount=type=cache,id=dnf-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/dnf \
    dnf -y install dotnet-sdk-8.0 dotnet-sdk-9.0

# Install nodejs
RUN --mount=type=cache,id=dnf-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/dnf \
    dnf -y install nodejs nodejs-npm yarnpkg

ARG VERSION
ARG RELEASE
LABEL name="your-username/my-toolbox" \
    org.opencontainers.image.name="your-username/my-toolbox" \
    vendor="Fedora Project" \
    maintainer="your-username" \
    url="https://github.com/your-username/my-toolbox" \
    version=${VERSION} \
    release=${RELEASE} \
    io.k8s.display-name="my-toolbox" \
    summary="my-toolbox: Personal Fedora Toolbox" \
    description="Personal Fedora Toolbox for development. For more information: https://github.com/your-username/my-toolbox"
```
