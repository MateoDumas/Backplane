#!/bin/sh
set -e

echo "Starting Frontend Entrypoint (Universal Mode)..."

# --- 1. ENV VAR SETUP ---

# Fix API_BASE_URL
if [ -z "$API_BASE_URL" ]; then
    echo "WARNING: API_BASE_URL is empty. Defaulting to internal service."
    export API_BASE_URL="http://api-gateway:10000"
fi

# Ensure protocol
case "$API_BASE_URL" in
  http://*|https://*)
    ;;
  *)
    echo "Adding http:// to API_BASE_URL"
    export API_BASE_URL="http://$API_BASE_URL"
    ;;
esac

# Strip trailing slash
API_BASE_URL=${API_BASE_URL%/}

echo "----------------------------------------"
echo "CONFIGURING NGINX WITH:"
echo "API_BASE_URL = $API_BASE_URL"
echo "----------------------------------------"

# --- 2. DETECT SYSTEM DNS ---
# We MUST use the system DNS (usually 127.0.0.11 in Docker) to resolve:
# a) Internal names (api-gateway)
# b) Public names (via upstream forwarding)
# Using Google DNS (8.8.8.8) breaks internal name resolution.

echo "Reading /etc/resolv.conf:"
cat /etc/resolv.conf

DNS_RESOLVER=$(awk '/nameserver/ {print $2; exit}' /etc/resolv.conf)

if [ -z "$DNS_RESOLVER" ]; then
    echo "⚠️  WARNING: No DNS resolver found. Defaulting to 127.0.0.11 (Docker DNS)."
    DNS_RESOLVER="127.0.0.11"
else
    echo "✅ Detected System DNS: $DNS_RESOLVER"
fi

# --- 3. GENERATE CONFIG FILE ---

cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen 80;
    server_name localhost;

    # Serve static frontend files
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
    }

    # Proxy API requests
    location /api/ {
        # 1. Use the DETECTED SYSTEM RESOLVER.
        #    This allows resolving both 'api-gateway' (internal) and public URLs.
        resolver $DNS_RESOLVER valid=5s ipv6=off;
        
        # 2. Lazy Resolution (Variable Trick)
        #    This prevents Nginx from crashing at startup if the host isn't ready yet.
        set \$upstream_target "$API_BASE_URL";
        
        # 3. Strip /api/ prefix
        rewrite ^/api/(.*) /\$1 break;
        
        # 4. Proxy to the variable
        proxy_pass \$upstream_target;
        
        # SSL Support (in case API_BASE_URL is https)
        proxy_ssl_server_name on;
        proxy_ssl_protocols TLSv1.2 TLSv1.3;
        
        # Headers
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        
        # Error handling
        proxy_intercept_errors on;
        error_page 502 = @backend_down;
    }
    
    # Custom 502 page for JSON clients
    location @backend_down {
        default_type application/json;
        return 502 '{"error": "Bad Gateway", "message": "Backend service ($API_BASE_URL) is not resolving. DNS: $DNS_RESOLVER. Check logs."}';
    }
}
EOF

echo "✅ Nginx configuration generated."
echo "🚀 Starting Nginx..."
exec nginx -g "daemon off;"
