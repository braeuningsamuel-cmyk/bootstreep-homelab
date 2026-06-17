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

# Copy dependencies from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy application files
COPY . .

# Start application
CMD ["npm", "start"]
