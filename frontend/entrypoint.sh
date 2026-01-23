#!/bin/sh
set -e

echo "Starting Frontend Entrypoint (Non-Blocking Mode)..."

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

# --- 2. DETECT DNS RESOLVER ---
# Critical for Render: Use the system's DNS resolver from /etc/resolv.conf
DNS_RESOLVER=$(awk '/nameserver/ {print $2; exit}' /etc/resolv.conf)

if [ -z "$DNS_RESOLVER" ]; then
    echo "⚠️  WARNING: No DNS resolver found. Defaulting to Google DNS (8.8.8.8)."
    DNS_RESOLVER="8.8.8.8"
else
    echo "✅ Detected System DNS: $DNS_RESOLVER"
fi

# --- 3. GENERATE CONFIG FILE ---
# We use a runtime variable for proxy_pass to prevent Nginx from crashing 
# if the host is not resolvable at startup (Lazy Resolution).

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
        # 1. Use detected resolver
        resolver $DNS_RESOLVER valid=10s ipv6=off;
        
        # 2. Use a variable for the upstream target to force lazy resolution
        #    This prevents "host not found" startup errors.
        set \$upstream_target "$API_BASE_URL";
        
        # 3. Strip /api/ prefix
        rewrite ^/api/(.*) /\$1 break;
        
        # 4. Proxy to the variable
        proxy_pass \$upstream_target;
        
        # Headers
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        
        # Error handling for bad gateway (upstream down/booting)
        proxy_intercept_errors on;
        error_page 502 = @backend_down;
    }
    
    # Custom 502 page for JSON clients
    location @backend_down {
        default_type application/json;
        return 502 '{"error": "Bad Gateway", "message": "Backend service ($API_BASE_URL) is unavailable or starting up. Please retry in a moment."}';
    }
}
EOF

echo "✅ Nginx configuration generated."
echo "🚀 Starting Nginx..."
exec nginx -g "daemon off;"
