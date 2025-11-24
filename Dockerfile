FROM node:22

WORKDIR /app

# Copiamos package.json y package-lock.json
COPY package*.json ./

# Instalamos dependencias
RUN npm ci

# Copiamos el resto del código
COPY . .

# Ejecutamos build y tests al construir la imagen
RUN npm test
RUN npm run build

# Comando por defecto al iniciar el contenedor
CMD ["node", "dist/main.js"]

