#!/bin/bash
# Frontend EC2 Setup Script
# Run as: sudo bash setup-frontend.sh

set -e

echo "=========================================="
echo "  Frontend EC2 Setup - DevOps Dashboard"
echo "=========================================="

# Variables (customize these)
DOMAIN="your-domain.com"
BACKEND_PRIVATE_IP="10.0.2.10"  # Private IP of Backend EC2

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Node.js (for building React app)
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Nginx
echo "Installing Nginx..."
sudo apt install -y nginx

# Install Certbot for SSL
echo "Installing Certbot..."
sudo apt install -y certbot python3-certbot-nginx

# Create web directory
sudo mkdir -p /var/www/devops-dashboard
sudo mkdir -p /var/www/certbot

# Set permissions
sudo chown -R $USER:$USER /var/www/devops-dashboard
sudo chmod -R 755 /var/www/devops-dashboard

echo "=========================================="
echo "  Building React Application"
echo "=========================================="

# Clone and build (or copy your built files)
# Option 1: If you have the source code
# cd /tmp
# git clone YOUR_REPO_URL devops-dashboard
# cd devops-dashboard
# npm install
# npm run build
# cp -r dist/* /var/www/devops-dashboard/

# Option 2: Copy pre-built files
echo "Copy your React build files to /var/www/devops-dashboard/"
echo "  scp -r dist/* ec2-user@YOUR_EC2_IP:/var/www/devops-dashboard/"

# Configure Nginx
echo "Configuring Nginx..."
sudo cp nginx.conf /etc/nginx/sites-available/devops-dashboard

# Update Backend IP in Nginx config
sudo sed -i "s/BACKEND_PRIVATE_IP/${BACKEND_PRIVATE_IP}/g" /etc/nginx/sites-available/devops-dashboard
sudo sed -i "s/your-domain.com/${DOMAIN}/g" /etc/nginx/sites-available/devops-dashboard

# Enable site
sudo ln -sf /etc/nginx/sites-available/devops-dashboard /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Get SSL certificate
echo "Obtaining SSL certificate..."
sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --email your-email@example.com

# Restart Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx

# Set up auto-renewal for SSL
(crontab -l 2>/dev/null; echo "0 0 * * * /usr/bin/certbot renew --quiet") | crontab -

echo "=========================================="
echo "  Frontend EC2 Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Copy your React build files to /var/www/devops-dashboard/"
echo "2. Update DNS records to point to this EC2's Elastic IP"
echo "3. Ensure Security Group allows ports 80 and 443"
echo ""
echo "To build React app locally and deploy:"
echo "  npm run build"
echo "  scp -r dist/* ubuntu@${DOMAIN}:/var/www/devops-dashboard/"