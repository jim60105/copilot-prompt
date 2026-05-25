# Nginx Containerfile Example

Minimal nginx pattern for frontend apps:

```containerfile
# syntax=docker/dockerfile:1
ARG NG_APP_VERSION=0.0.0

FROM node:lts-alpine as build

WORKDIR /app

ARG NG_APP_VERSION
ENV NG_APP_VERSION=$NG_APP_VERSION

RUN --mount=source=package.json,target=package.json \
  --mount=source=package-lock.json,target=package-lock.json \
  npm ci

COPY . .
RUN npm run-script build:production

FROM nginxinc/nginx-unprivileged:stable-alpine-slim as final

COPY --chown=101:101 --chmod=444 \
  nginx.conf /etc/nginx/nginx.conf
COPY --from=build --chown=101:101 --chmod=444 \
  /app/dist /usr/share/nginx/html
```
