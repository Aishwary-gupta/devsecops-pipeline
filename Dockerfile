# ==============================================================================
# Multi-Stage Hardened Dockerfile for DevSecOps Pipeline
# Compliant with CIS Docker Benchmark, Checkov IaC Policies, and Trivy Scanners
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build & Dependencies
# ------------------------------------------------------------------------------
FROM node:20-alpine3.20 AS builder

LABEL stage="builder"

WORKDIR /app

# Install dependencies needed for compiling if any (keep minimal)
RUN apk update && apk upgrade --no-cache

# Copy package manifests first for efficient layer caching
COPY package.json package-lock.json* ./

# Install all dependencies including devDependencies for linting/tests
RUN npm ci --ignore-scripts

# Copy application source code
COPY src/ ./src/
COPY tests/ ./tests/

# Prune devDependencies to keep only production artifacts
RUN npm prune --production

# ------------------------------------------------------------------------------
# Stage 2: Hardened Runtime Container
# ------------------------------------------------------------------------------
FROM node:20-alpine3.20 AS runner

LABEL org.opencontainers.image.title="secure-devsecops-service" \
      org.opencontainers.image.description="End-to-End DevSecOps microservice" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.vendor="DevSecOps Platform Team" \
      org.opencontainers.image.licenses="MIT"

# Security hardening: upgrade OS packages to latest patch levels
RUN apk update && apk upgrade --no-cache && \
    rm -rf /var/cache/apk/* /tmp/*

WORKDIR /app

# Enforce Non-Root Execution (Requirement for Checkov, OPA, and CIS Benchmark)
RUN addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S appuser -G appgroup

# Copy production node_modules and app code from builder
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/src ./src
COPY --from=builder --chown=appuser:appgroup /app/package.json ./package.json

# Environment variables
ENV NODE_ENV=production \
    PORT=3000

# Container Healthcheck (Required by Checkov CKV_DOCKER_2)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Drop privileges to non-root user (Required by Checkov CKV_DOCKER_3 & CKV_DOCKER_8)
USER appuser:appgroup

EXPOSE 3000

# Standard entrypoint
CMD ["node", "src/server.js"]
