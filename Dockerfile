# Etapa de compilación
FROM node:22 AS build

WORKDIR /usr/app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run lint
RUN npm run test:cov
RUN npm run build

# Etapa de ejecución
FROM node:22-alpine AS runner

WORKDIR /usr/app

COPY --from=build /usr/app/package*.json ./
RUN npm install --only=production

COPY --from=build /usr/app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main"]
