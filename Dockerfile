# Stage 1: Builder
FROM node:22-alpine AS builder

WORKDIR /juice-shop

# Copy package files only (reduce cache invalidation)
COPY package*.json ./

# Install production dependencies only
RUN npm install --omit=dev \
    && npm cache clean --force

# Copy application source
COPY . .

# Build application
RUN npm run build \
    && rm -rf frontend/node_modules frontend/.angular frontend/src/assets

# Stage 2: Runtime (Hardened)
FROM gcr.io/distroless/nodejs22-debian12

# Metadata
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.title="OWASP Juice Shop (Hardened)" \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF

# Set non-root user
USER 65532

# Create working directory
WORKDIR /juice-shop

# Copy only required build output
COPY --from=builder --chown=65532:0 /juice-shop/build ./build
COPY --from=builder --chown=65532:0 /juice-shop/node_modules ./node_modules
COPY --from=builder --chown=65532:0 /juice-shop/config ./config
COPY --from=builder --chown=65532:0 /juice-shop/data ./data
COPY --from=builder --chown=65532:0 /juice-shop/i18n ./i18n

# Expose application port
EXPOSE 3000

# Run application
CMD ["build/app.js"]
