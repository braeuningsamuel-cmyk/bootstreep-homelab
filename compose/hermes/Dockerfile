# Hermes – Optimized Build (precompiled Node dependencies)
FROM node:22-alpine AS builder

WORKDIR /app

# Copy only package files if they exist
COPY package*.json ./

# Install dependencies (only if package.json exists)
RUN if [ -f package.json ]; then npm ci --only=production; fi

# Final stage
FROM node:22-alpine

WORKDIR /app

# Drop root - run as the unprivileged "node" user that ships with the base image.
# Bind-mounts already restrict the host filesystem; this protects the in-container
# filesystem from any node-process exploit.
USER node

# Copy dependencies from builder
COPY --from=builder --chown=node:node /app/node_modules ./node_modules

# Copy application files (read-only at runtime; runtime writes go to bind-mounts)
COPY --chown=node:node . .

# Health probe for Docker / Traefik
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1

# Start application
CMD ["npm", "start"]
