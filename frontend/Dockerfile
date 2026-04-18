# Build stage — Debian (glibc): @swc/core postinstall hay SIGBUS trên node:*-alpine (musl)
FROM node:18-bookworm-slim AS builder

WORKDIR /app

# Build-time Vite env (must be available during `vite build`)
ARG VITE_API_BASE_URL=/api
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the app
RUN npm run build

# Production stage - use nginx to serve static files
FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built files from builder
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
