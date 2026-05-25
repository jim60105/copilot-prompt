# .NET Containerfile Example

Key .NET patterns:

- Use `runtime-deps` base image for self-contained deployments
- Enable `PublishTrimmed=true` and `PublishSingleFile=true` in `.csproj`
- Separate debug and production stages
- Use `--self-contained true` for deployment

```containerfile
#See https://aka.ms/containerfastmode
### Base image for my-app
FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine AS base
WORKDIR /app

RUN apk add --no-cache aria2 ffmpeg python3 && \
    apk add --no-cache --virtual build-deps musl-dev gcc g++ python3-dev py3-pip && \
    python3 -m venv /venv && \
    source /venv/bin/activate && \
    pip install --no-cache-dir my-app && \
    pip uninstall -y setuptools pip && \
    apk del build-deps

ENV PATH="/venv/bin:$PATH"

### Debug image
FROM mcr.microsoft.com/dotnet/runtime:8.0-alpine AS debug
WORKDIR /app

RUN apk add --no-cache aria2 ffmpeg python3 && \
    apk add --no-cache --virtual build-deps musl-dev gcc g++ python3-dev py3-pip && \
    python3 -m venv /venv && \
    source /venv/bin/activate && \
    pip install --no-cache-dir my-app && \
    pip uninstall -y setuptools pip && \
    apk del build-deps
ENV PATH="/venv/bin:$PATH"

### Build .NET
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
ARG BUILD_CONFIGURATION=Release
ARG TARGETARCH
WORKDIR /src

COPY ["my-dotnet-app.csproj", "."]
RUN dotnet restore -a $TARGETARCH "my-dotnet-app.csproj"

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
COPY . .
RUN dotnet publish "my-dotnet-app.csproj" -a $TARGETARCH -c $BUILD_CONFIGURATION -o /app/publish --self-contained true

### Final image
FROM base AS final

ENV PATH="/app:$PATH"

RUN mkdir -p /app && chown -R $APP_UID:$APP_UID /app && chmod u+rwx /app
COPY --from=publish --chown=$APP_UID:$APP_UID /app/publish/my-dotnet-app /app/my-dotnet-app

USER $APP_UID

ENTRYPOINT ["/app/my-dotnet-app"]
```
