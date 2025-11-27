# ---------- STAGE 1: Build ----------
FROM node:22 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ---------- STAGE 2: Runtime ----------
FROM node:22-slim

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY package*.json ./

RUN npm ci --omit=dev

EXPOSE 3000

CMD ["node", "dist/main.js"]
