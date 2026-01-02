# Stage 1: Builder
FROM node:22-alpine AS builder

# Install git ONLY for build
RUN apk add --no-cache git

WORKDIR /juice-shop

# Copy dependency definition first
COPY package*.json ./

# Install production dependencies
RUN npm install --omit=dev \
    && npm cache clean --force

# Copy source code
COPY . .

# Build application
RUN npm run build \
    && rm -rf frontend/node_modules \
    frontend/.angular \
    frontend/src/assets


# Stage 2: Runtime (Hardened)
FROM gcr.io/distroless/nodejs22-debian12

# Metadata
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.title="OWASP Juice Shop (Hardened)" \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF

# Non-root user
USER 65532

WORKDIR /juice-shop

# Copy only required runtime files
COPY --from=builder --chown=65532:0 /juice-shop/build ./build
COPY --from=builder --chown=65532:0 /juice-shop/node_modules ./node_modules
COPY --from=builder --chown=65532:0 /juice-shop/config ./config
COPY --from=builder --chown=65532:0 /juice-shop/data ./data
COPY --from=builder --chown=65532:0 /juice-shop/i18n ./i18n

EXPOSE 3000

CMD ["build/app.js"]
