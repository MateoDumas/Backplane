FROM nginx:alpine

# No copiamos a /etc/nginx/templates/ para evitar el envsubst automático que rompe variables de nginx ($uri, $1)
COPY default.conf.template /etc/nginx/default.conf.tpl
COPY index.html /usr/share/nginx/html/index.html

# Valores por defecto para desarrollo local
ENV API_BASE_URL=http://api-gateway:8080
ENV DNS_RESOLVER=127.0.0.11

EXPOSE 80

# CMD personalizado:
# 1. Ejecuta envsubst EXPLICITAMENTE solo para nuestras variables de entorno.
#    Esto preserva las variables de Nginx como $uri, $host, $1, etc.
# 2. Inicia Nginx
CMD ["/bin/sh", "-c", "envsubst '${API_BASE_URL} ${DNS_RESOLVER}' < /etc/nginx/default.conf.tpl > /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'"]