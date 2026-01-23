#!/bin/sh
set -e

echo "=== STARTING FRONTEND ENTRYPOINT ==="
echo "Mode: Robust DNS + Public/Private Fallback"

# --- 1. DEBUG ENV VARS ---
echo ">>> RAW API_BASE_URL: '$API_BASE_URL' <<<"

if [ -z "$API_BASE_URL" ]; then
    echo "⚠️  WARNING: API_BASE_URL is NOT set by Render!"
    echo "    This suggests 'fromService: property: url' failed or service is not ready."
    echo "    Falling back to internal default: http://api-gateway:10000"
    export API_BASE_URL="http://api-gateway:10000"
else
    echo "✅ API_BASE_URL provided by environment."
    
    # FORCE INTERNAL URL OVERRIDE
    # If Render provides the public URL (onrender.com), we override it to the internal one.
    # This avoids the Public Load Balancer 100s timeout limit.
    case "$API_BASE_URL" in
      *onrender.com*)
        echo "⚠️  DETECTED PUBLIC RENDER URL: '$API_BASE_URL'"
        echo "    Overriding to INTERNAL URL to bypass Load Balancer timeouts."
        export API_BASE_URL="http://api-gateway:10000"
        echo "    -> New API_BASE_URL: $API_BASE_URL"
        ;;
    esac
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

# --- PRE-RESOLVE HOSTNAME ---
# Skipped - Relying on System DNS at startup

# String Replace Logic only (No DNS)
TEMP_URL=${API_BASE_URL#*://}
TEMP_HOST=${TEMP_URL%%:*}
TEMP_HOST=${TEMP_HOST%%/*}

# If URL is NOT 'api-gateway', we assume it's the broken Render slug and force-switch it.
# This assumes we ALWAYS want to use 'api-gateway' for internal comms.
if [ "$TEMP_HOST" != "api-gateway" ]; then
    echo "🔄 Forcing switch from '$TEMP_HOST' to stable name 'api-gateway'"
    API_BASE_URL=$(echo "$API_BASE_URL" | sed "s/$TEMP_HOST/api-gateway/")
    echo "    -> New API_BASE_URL: $API_BASE_URL"
fi

echo ">>> FINAL API_BASE_URL: '$API_BASE_URL' <<<"

# --- 2. DETECT SYSTEM DNS ---
# Skipped - Using System DNS implicitly via static proxy_pass

# --- 3. GENERATE CONFIG FILE ---

# CRITICAL CHANGE: Use static proxy_pass to force Nginx to use System DNS (libc) at startup
# instead of internal resolver. This ensures Search Domains are respected.

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
        # 1. Strip /api/ prefix
        rewrite ^/api/(.*) /\$1 break;
        
        # 2. Proxy directly to the URL (Expanded at startup time)
        #    Nginx will resolve this ONCE at startup using system DNS.
        proxy_pass $API_BASE_URL;
        
        # SSL Support (Universal)
        proxy_ssl_server_name on;
        proxy_ssl_protocols TLSv1.2 TLSv1.3;
        
        # Headers
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        # proxy_set_header Host \$host; 
        proxy_cache_bypass \$http_upgrade;
        
        # Error handling
        proxy_intercept_errors on;
        error_page 502 504 = @backend_down;

        # Timeouts (Render Cold Start Fix)
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
    
    # Custom 502 page for JSON clients
    location @backend_down {
        default_type application/json;
        return 502 '{"error": "Bad Gateway", "message": "Backend ($API_BASE_URL) is unreachable. Check logs for DNS errors."}';
    }
}
EOF

echo "✅ Nginx configuration generated."
echo "🚀 Starting Nginx..."
exec nginx -g "daemon off;"
