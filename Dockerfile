# ---------- STAGE 1: Build ----------
FROM node:22 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

# Generamos build (dist/)
RUN npm run build

# ---------- STAGE 2: Runtime ----------
FROM node:22-slim

WORKDIR /app

# Copiamos solo lo necesario de producción
COPY package*.json ./
RUN npm ci --omit=dev

# Copiamos el artefacto compilado desde el builder
COPY --from=builder /app/dist ./dist

# Comando de ejecución
CMD ["node", "dist/main.js"]
