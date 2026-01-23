#!/bin/sh
set -e

echo "Starting Frontend Entrypoint (Public URL Mode)..."

# --- 1. ENV VAR SETUP ---

# Fix API_BASE_URL
if [ -z "$API_BASE_URL" ]; then
    echo "WARNING: API_BASE_URL is empty. Defaulting to internal service."
    # Fallback to internal if missing, but likely won't work if public is expected
    export API_BASE_URL="http://api-gateway:10000"
fi

# Ensure protocol
case "$API_BASE_URL" in
  http://*|https://*)
    ;;
  *)
    echo "Adding https:// to API_BASE_URL (Assuming Public)"
    export API_BASE_URL="https://$API_BASE_URL"
    ;;
esac

# Strip trailing slash
API_BASE_URL=${API_BASE_URL%/}

echo "----------------------------------------"
echo "CONFIGURING NGINX WITH:"
echo "API_BASE_URL = $API_BASE_URL"
echo "----------------------------------------"

# --- 2. GENERATE CONFIG FILE ---
# We use the Public URL to guarantee resolution via Google DNS (8.8.8.8).
# We use the Variable Trick to prevent startup crashes.

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
        # 1. Use Google DNS to resolve public Render URLs
        resolver 8.8.8.8 8.8.4.4 valid=300s;
        
        # 2. Use a variable to force runtime resolution (Prevent startup crash)
        set \$upstream_target "$API_BASE_URL";
        
        # 3. Strip /api/ prefix
        rewrite ^/api/(.*) /\$1 break;
        
        # 4. Proxy to the variable
        proxy_pass \$upstream_target;
        
        # SSL Support (Required for Public HTTPS URLs)
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
        return 502 '{"error": "Bad Gateway", "message": "Backend service ($API_BASE_URL) is unavailable. Please check the logs."}';
    }
}
EOF

echo "✅ Nginx configuration generated."
echo "🚀 Starting Nginx..."
exec nginx -g "daemon off;"
