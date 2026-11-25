# Етап 1: Збірка SPA застосунку
FROM node:22-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Етап 2: Легковаговий runtime від імені non-root користувача nginx (UID 101)
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime
WORKDIR /usr/share/nginx/html

COPY --from=builder --chown=101:101 /app/dist ./

EXPOSE 8080
USER 101

CMD ["nginx", "-g", "daemon off;"]
