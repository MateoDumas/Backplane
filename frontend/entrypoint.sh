#!/bin/sh
set -e

echo "Starting Frontend Entrypoint..."
echo "Environment check:"
echo "API_BASE_URL='$API_BASE_URL'"
echo "DNS_RESOLVER='$DNS_RESOLVER'"

if [ -z "$API_BASE_URL" ]; then
    echo "ERROR: API_BASE_URL is missing or empty!"
    exit 1
fi

echo "Generating Nginx configuration..."
# Usamos envsubst con lista explícita de variables para no romper $uri, $host, etc.
# IMPORTANTE: Usamos comillas simples para la lista de variables
envsubst '${API_BASE_URL} ${DNS_RESOLVER}' < /etc/nginx/default.conf.tpl > /etc/nginx/conf.d/default.conf

echo "Configuration generated. verification:"
grep "proxy_pass" /etc/nginx/conf.d/default.conf
grep "resolver" /etc/nginx/conf.d/default.conf

echo "Starting Nginx..."
exec nginx -g 'daemon off;'
