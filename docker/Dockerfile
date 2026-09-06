# ============================================================
# STAGE 1: dependencias de build
# ============================================================
FROM node:20-alpine AS builder
WORKDIR /app

# Copiamos solo los manifiestos para aprovechar la cache de capas
COPY app/package*.json ./
RUN npm ci

# Copiamos el codigo y ejecutamos tests durante el build
COPY app/ ./
RUN npm test

# ============================================================
# STAGE 2: dependencias de produccion (sin devDependencies)
# ============================================================
FROM node:20-alpine AS deps
WORKDIR /app
COPY app/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# ============================================================
# STAGE 3: imagen final minima
# ============================================================
FROM node:20-alpine AS runner
WORKDIR /app

# Usuario no-root por seguridad
RUN addgroup -S nodejs && adduser -S nodeuser -G nodejs

ENV NODE_ENV=production
ENV PORT=3000

# Copiamos solo lo necesario desde stages anteriores
COPY --from=deps  /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY app/package.json ./

USER nodeuser
EXPOSE 3000

# Healthcheck integrado
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/healthz || exit 1

CMD ["node", "src/server.js"]
