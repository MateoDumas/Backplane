FROM nginx:alpine

COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY index.html /usr/share/nginx/html/index.html

# Valores por defecto para desarrollo local
ENV API_BASE_URL=http://api-gateway:8080
ENV DNS_RESOLVER=127.0.0.11

EXPOSE 80
