# Python: ML/CUDA

Key ML/CUDA patterns:

```containerfile
# CUDA environment
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# LD_LIBRARY_PATH for CUDA libraries
ENV LD_LIBRARY_PATH="/venv/lib/python3.11/site-packages/nvidia/cudnn/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
```

Full ML example with multi-arch support and model preloading:

```containerfile
# syntax=docker/dockerfile:1
ARG WHISPER_MODEL=base
ARG LANG=en
ARG UID=1001
ARG VERSION=EDGE
ARG RELEASE=0

ARG LOAD_WHISPER_STAGE=load_whisper
ARG NO_MODEL_STAGE=no_model

ARG CACHE_HOME=/.cache
ARG CONFIG_HOME=/.config
ARG TORCH_HOME=${CACHE_HOME}/torch
ARG HF_HOME=${CACHE_HOME}/huggingface

########################################
# Base stage for amd64
########################################
FROM docker.io/library/python:3.11-slim-bullseye AS prepare_base_amd64

ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /tmp

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

########################################
# Base stage for arm64
########################################
FROM docker.io/library/python:3.11-slim-bullseye AS prepare_base_arm64

ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /tmp

RUN --mount=type=cache,id=apt-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=aptlists-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 libsndfile1

# Select the base stage by target architecture
FROM prepare_base_$TARGETARCH$TARGETVARIANT AS base

########################################
# Build stage
########################################
FROM base AS build

ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /app

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_PROJECT_ENVIRONMENT=/venv
ENV VIRTUAL_ENV=/venv
ENV UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=0

# Install big dependencies separately for layer caching
RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    uv venv --system-site-packages /venv && \
    uv pip install --no-deps --index "https://download.pytorch.org/whl/cu128" \
    "torch==2.7.1+cu128" \
    "torchaudio" \
    "triton" \
    "pyannote.audio==3.3.2"

# Install project dependencies
RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    --mount=type=bind,source=app/pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=app/uv.lock,target=uv.lock \
    uv sync --frozen --no-dev --no-install-project --no-editable

# Install project
RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    --mount=source=app,target=.,rw \
    uv sync --frozen --no-dev --no-editable

########################################
# Final stage
########################################
FROM base AS final

RUN pip3.11 uninstall -y pip wheel && \
    rm -rf /root/.cache/pip

# Create user
ARG UID
RUN groupadd -g $UID $UID && \
    useradd -l -u $UID -g $UID -m -s /bin/sh -N $UID

ARG CACHE_HOME
ARG CONFIG_HOME
ARG TORCH_HOME
ARG HF_HOME
ENV XDG_CACHE_HOME=${CACHE_HOME}
ENV TORCH_HOME=${TORCH_HOME}
ENV HF_HOME=${HF_HOME}

RUN install -d -m 775 -o $UID -g 0 /licenses && \
    install -d -m 775 -o $UID -g 0 /root && \
    install -d -m 775 -o $UID -g 0 ${CACHE_HOME} && \
    install -d -m 775 -o $UID -g 0 ${CONFIG_HOME}

# Install dumb-init (see SKILL.md for secure download pattern)

# Copy licenses (OpenShift Policy)
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/LICENSE
COPY --link --chown=$UID:0 --chmod=775 app/LICENSE /licenses/my-ml-app.LICENSE

# Copy venv (and support arbitrary uid for OpenShift best practice)
COPY --link --chown=$UID:0 --chmod=775 --from=build /venv /venv

ENV PATH="/venv/bin${PATH:+:${PATH}}"
ENV PYTHONPATH="/venv/lib/python3.11/site-packages"
ENV LD_LIBRARY_PATH="/venv/lib/python3.11/site-packages/nvidia/cudnn/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

# Test my-ml-app
RUN python3 -c 'import my_ml_app;' && \
    my-ml-app -h

WORKDIR /app

VOLUME [ "/app" ]

USER $UID

STOPSIGNAL SIGINT

ENTRYPOINT [ "dumb-init", "--", "/bin/sh", "-c", "my-ml-app \"$@\"" ]

ARG VERSION
ARG RELEASE
LABEL name="your-username/docker-my-ml-app" \
    vendor="upstream-authors" \
    maintainer="your-username" \
    url="https://github.com/your-username/docker-my-ml-app" \
    version=${VERSION} \
    release=${RELEASE} \
    io.k8s.display-name="my-ml-app" \
    summary="My ML App: Speech Processing Application" \
    description="An ML/AI application with GPU acceleration. For more information: https://github.com/upstream-org/my-ml-app"
```
