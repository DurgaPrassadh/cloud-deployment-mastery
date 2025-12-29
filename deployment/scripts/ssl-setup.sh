#!/bin/bash
# SSL/TLS Certificate Setup Script using Let's Encrypt
# File: deployment/scripts/ssl-setup.sh
# Usage: ./ssl-setup.sh <domain>

set -e

DOMAIN="$1"
EMAIL="${SSL_EMAIL:-admin@example.com}"
NGINX_CONF="/etc/nginx/sites-available/default"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Validate input
if [ -z "$DOMAIN" ]; then
    error "Usage: $0 <domain>"
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root or with sudo"
fi

log "Setting up SSL for domain: $DOMAIN"

# Install Certbot
log "Installing Certbot..."
apt-get update
apt-get install -y certbot python3-certbot-nginx

# Check if Nginx is running
if ! systemctl is-active --quiet nginx; then
    error "Nginx is not running. Please start Nginx first."
fi

# Check DNS resolution
log "Checking DNS resolution..."
RESOLVED_IP=$(dig +short "$DOMAIN" | head -n1)
PUBLIC_IP=$(curl -s ifconfig.me)

if [ "$RESOLVED_IP" != "$PUBLIC_IP" ]; then
    echo -e "${YELLOW}[WARNING]${NC} DNS might not be pointing to this server"
    echo "  Domain resolves to: $RESOLVED_IP"
    echo "  Server public IP:   $PUBLIC_IP"
    read -p "Continue anyway? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
        exit 0
    fi
fi

# Obtain certificate
log "Obtaining SSL certificate from Let's Encrypt..."
certbot --nginx \
    -d "$DOMAIN" \
    -d "www.$DOMAIN" \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --redirect

# Verify certificate
log "Verifying certificate..."
if certbot certificates | grep -q "$DOMAIN"; then
    log "Certificate installed successfully!"
else
    error "Certificate installation failed"
fi

# Setup auto-renewal
log "Setting up auto-renewal..."
if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
    (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'") | crontab -
    log "Auto-renewal cron job added"
fi

# Test auto-renewal
log "Testing certificate renewal..."
certbot renew --dry-run

# Test SSL
log "Testing SSL configuration..."
if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" | grep -q "200\|301\|302"; then
    log "SSL is working correctly!"
else
    echo -e "${YELLOW}[WARNING]${NC} SSL might not be fully configured yet"
fi

echo ""
echo "=========================================="
echo "  SSL SETUP COMPLETED"
echo "=========================================="
echo "  Domain:      https://$DOMAIN"
echo "  WWW:         https://www.$DOMAIN"
echo "  Certificate: Let's Encrypt"
echo "  Auto-renew:  Enabled (daily at 3 AM)"
echo "=========================================="
echo ""
echo "To manually renew: sudo certbot renew"
echo "To check status:   sudo certbot certificates"
echo "=========================================="
