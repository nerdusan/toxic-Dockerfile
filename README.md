# Toxic Dockerfile: Optimization and Security Baseline

This repository documents the transition of a Node.js application from a standard, unoptimized Docker configuration to a production-hardened, high-performance container. The project serves as a reference for implementing multi-stage builds, non-root security principles, and efficient layer caching.

---

## Performance Metrics

| Image Version | Strategy | Size | Security | Build Speed |
| :--- | :--- | :--- | :--- | :--- |
| toxic-app1 | Standard Node (Debian) | ~1.1GB | Root User | Slow |
| toxic-app2 | Alpine Base | ~150MB | Root User | Medium |
| toxic-app3 | Multi-Stage Build | ~50MB | Root User | Fast |
| toxic-app4 | Hardened Multi-Stage | 49MB | **Non-Root** | **Instant (Cached)** |

---

## Optimization Pillars

### 1. Multi-Stage Build Architecture
The Dockerfile utilizes a binary-stage approach. The `builder` stage handles dependency resolution and source compilation, while the final stage contains only the runtime and the minimum set of files required for execution. This eliminates build-time bloat and reduces the attack surface.

### 2. Dependency Layer Caching
By isolating the `package.json` and `package-lock.json` files and executing `npm install` before copying the remaining source code, the workflow leverages Docker’s layer caching mechanism. Subsequent builds only re-install dependencies if the package files have been modified, drastically reducing CI/CD execution time.

### 3. Principle of Least Privilege
Default Docker containers run as the `root` user, posing a significant security risk. This configuration explicitly creates and switches to a restricted `node` user. Permission management is handled via `--chown` flags during the `COPY` process to ensure the application retains necessary access without elevated privileges.

---

## Production Dockerfile

```dockerfile
# --- STAGE 1: Builder ---
FROM node:20-alpine AS builder
WORKDIR /app

# Install dependencies separately to optimize layer cache
COPY package*.json ./
RUN npm install
COPY . .

# --- STAGE 2: Runtime ---
FROM node:20-alpine
WORKDIR /app

# Security: Ensure directory ownership for the non-root user
RUN chown node:node /app

# Optimization: Only transfer necessary artifacts from builder
COPY --from=builder --chown=node:node /app/package*.json ./
COPY --from=builder --chown=node:node /app/app.js ./

# Production dependency pruning and cache cleanup
RUN npm install --omit=dev && npm cache clean --force

# Security: Switch to non-root execution
USER node

EXPOSE 8080
CMD ["node", "app.js"]