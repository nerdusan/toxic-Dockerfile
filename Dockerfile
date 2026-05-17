# --- STAGE 1: the builder ---
FROM node:20-alpine AS builder
WORKDIR /app

# Cache Optimization, prevents reinstalling dependencies when code is changed
COPY package*.json ./
RUN npm install
COPY . .

# --- STAGE 2: Run ---
FROM node:20-alpine
WORKDIR /app

# Security: Ensure non-root 'node' user owns the app directory
RUN chown node:node /app

# Optimization: Only pull the essential files from the builder stage
# Size & Security: --chown ensures permissions are set during the copy layer
COPY --from=builder --chown=node:node /app/package*.json ./
COPY --from=builder --chown=node:node /app/app.js ./

# Size: --omit=dev skips unnecessary testing/build tools
RUN npm install --omit=dev && npm cache clean --force

# Security: Switch from root to the limited 'node' user
USER node

EXPOSE 8080
CMD ["node", "app.js"]
