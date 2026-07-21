# syntax=docker/dockerfile:1
#
# Production image for Plumora's Flutter Web frontend.
#
# The resulting image only serves static files (build/web) via Nginx — it
# never talks to Postgres, holds no backend secret, and has no knowledge of
# GEMINI_API_KEY / JWT signing secrets / DB passwords, which all belong to
# the (separately deployed) Spring Boot backend.
#
# Build (values below are public: a base URL, not a secret):
#   docker build \
#     --build-arg API_BASE_URL=https://api.plumora-books.fr/api/v1 \
#     --build-arg WEB_BASE_URL=https://app.plumora-books.fr \
#     --build-arg APP_ENV=production \
#     -t plumora-frontend-web .
#
# Run:
#   docker run --rm -p 8080:8080 plumora-frontend-web
#
# The docker-compose stack that references this image via FRONTEND_IMAGE
# lives in the backend repo, not here — see docs/deployment-frontend.md for
# the expected contract (container name frontend-web, internal port 8080,
# Caddy reverse-proxying to it).

# ---------------------------------------------------------------------------
# Stage 1 — build the Flutter Web bundle
# ---------------------------------------------------------------------------
FROM debian:bookworm-slim AS build

# Keep in sync with the Flutter version this project is developed against
# (see `flutter --version`) so CI/local/prod all compile with the same SDK.
ARG FLUTTER_VERSION=3.44.0

# Public, non-secret build-time configuration — see lib/core/config/app_config.dart.
# Never pass GEMINI_API_KEY, JWT_SECRET, DB passwords or any server key here:
# this stage's output (build/web) ships to end-user browsers as plain text.
ARG APP_ENV=production
ARG API_BASE_URL=https://api.plumora-books.fr/api/v1
ARG WEB_BASE_URL=https://app.plumora-books.fr

RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
      curl \
      ca-certificates \
      unzip \
      xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${FLUTTER_VERSION}" \
      https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Pre-fetch the Flutter tool + web artifacts as their own layer so they're
# only re-downloaded when FLUTTER_VERSION changes, not on every source edit.
RUN git config --global --add safe.directory /opt/flutter \
    && flutter config --no-analytics --enable-web \
    && flutter precache --web \
    && flutter doctor -v

WORKDIR /app

# Dependencies as their own layer, cached as long as the lockfile is unchanged.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN flutter build web --release \
      --dart-define=APP_ENV="${APP_ENV}" \
      --dart-define=API_BASE_URL="${API_BASE_URL}" \
      --dart-define=WEB_BASE_URL="${WEB_BASE_URL}"

# ---------------------------------------------------------------------------
# Stage 2 — serve build/web with a minimal, non-root Nginx
# ---------------------------------------------------------------------------
# nginxinc/nginx-unprivileged is the stock nginx:alpine image repackaged to
# run as a non-root user (uid 101) and listen on an unprivileged port (8080)
# out of the box, which avoids re-permissioning nginx's cache/pid/log
# directories by hand.
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/security-headers.conf /etc/nginx/security-headers.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/ >/dev/null 2>&1 || exit 1

# Already the default user of this base image — explicit for clarity/auditability.
USER nginx

CMD ["nginx", "-g", "daemon off;"]
