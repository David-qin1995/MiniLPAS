# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM node:18-alpine AS build
WORKDIR /app
COPY web-frontend/package*.json /app/
RUN npm ci --silent
COPY web-frontend /app
RUN npm run build

# ---------- Runtime stage ----------
FROM nginx:1.25-alpine
WORKDIR /usr/share/nginx/html
COPY --from=build /app/dist/ /usr/share/nginx/html/
COPY deploy/frontend.nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8081
ENTRYPOINT ["nginx","-g","daemon off;"]

