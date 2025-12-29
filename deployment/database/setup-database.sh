#!/bin/bash
# PostgreSQL Database Setup Script for Database EC2
# Run as: sudo bash setup-database.sh

set -e

echo "=========================================="
echo "  PostgreSQL Setup for DevOps Dashboard"
echo "=========================================="

# Variables (customize these)
DB_NAME="devops_dashboard"
DB_USER="devops_admin"
DB_PASSWORD="your_secure_password_here"  # CHANGE THIS!
BACKEND_EC2_IP="10.0.2.10"  # Private IP of Backend EC2

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install PostgreSQL
echo "Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Configure PostgreSQL
echo "Configuring PostgreSQL..."

# Switch to postgres user and create database/user
sudo -u postgres psql << EOF
-- Create database
CREATE DATABASE ${DB_NAME};

-- Create user with password
CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
ALTER DATABASE ${DB_NAME} OWNER TO ${DB_USER};

-- Connect to the database and grant schema privileges
\c ${DB_NAME}
GRANT ALL ON SCHEMA public TO ${DB_USER};
EOF

echo "Database and user created successfully!"

# Configure PostgreSQL to accept connections from Backend EC2
echo "Configuring network access..."

# Find PostgreSQL config directory
PG_VERSION=$(ls /etc/postgresql/)
PG_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"

# Allow connections from Backend EC2
echo "host    ${DB_NAME}    ${DB_USER}    ${BACKEND_EC2_IP}/32    scram-sha-256" | sudo tee -a ${PG_HBA}

# Listen on all interfaces (but firewall will restrict)
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" ${PG_CONF}

# Restart PostgreSQL
sudo systemctl restart postgresql

echo "PostgreSQL configured to accept connections from ${BACKEND_EC2_IP}"

# Apply schema
echo "Applying database schema..."
sudo -u postgres psql -d ${DB_NAME} -f schema.sql

echo "=========================================="
echo "  PostgreSQL Setup Complete!"
echo "=========================================="
echo ""
echo "Connection details:"
echo "  Host: $(hostname -I | awk '{print $1}')"
echo "  Port: 5432"
echo "  Database: ${DB_NAME}"
echo "  User: ${DB_USER}"
echo ""
echo "IMPORTANT: Update the DB_PASSWORD variable before running!"
echo "IMPORTANT: Configure AWS Security Groups to only allow"
echo "           port 5432 from Backend EC2 (${BACKEND_EC2_IP})"