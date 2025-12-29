#!/bin/bash
# Backend EC2 Setup Script
# Run as: sudo bash setup-backend.sh

set -e

echo "=========================================="
echo "  Backend EC2 Setup - DevOps Dashboard"
echo "=========================================="

# Variables (customize these)
DB_HOST="10.0.3.10"  # Private IP of Database EC2
FRONTEND_URL="https://your-domain.com"

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Node.js
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install PM2 globally
echo "Installing PM2..."
sudo npm install -g pm2

# Create application directory
sudo mkdir -p /var/www/devops-api
sudo mkdir -p /var/log/pm2
sudo chown -R $USER:$USER /var/www/devops-api
sudo chown -R $USER:$USER /var/log/pm2

# Copy application files
echo "Copy application files to /var/www/devops-api/"
cd /var/www/devops-api

# Create .env file
cat > .env << EOF
NODE_ENV=production
PORT=3000
DB_HOST=${DB_HOST}
DB_PORT=5432
DB_NAME=devops_dashboard
DB_USER=devops_admin
DB_PASSWORD=your_secure_password_here
FRONTEND_URL=${FRONTEND_URL}
EOF

echo "IMPORTANT: Update the .env file with your actual database password!"

# Install dependencies
npm install --production

# Start with PM2
pm2 start ecosystem.config.js --env production

# Save PM2 process list
pm2 save

# Setup PM2 startup script
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp /home/$USER

echo "=========================================="
echo "  Backend EC2 Setup Complete!"
echo "=========================================="
echo ""
echo "PM2 Commands:"
echo "  pm2 status          - Check status"
echo "  pm2 logs            - View logs"
echo "  pm2 restart all     - Restart all"
echo "  pm2 monit           - Monitor dashboard"
echo ""
echo "IMPORTANT:"
echo "1. Update .env file with actual database password"
echo "2. Ensure Security Group allows port 3000 from Frontend EC2"
echo "3. Ensure Security Group allows outbound to Database EC2:5432"