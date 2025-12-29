# Docker Deployment Guide

## Quick Start with Docker

### 1. Clone and Configure
```bash
# Copy environment file
cp .env.example .env

# Edit .env with your settings
nano .env
```

### 2. Build and Run
```bash
# Build and start all services
docker-compose up -d --build

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 3. Access Application
- **Frontend**: http://localhost
- **API Health**: http://localhost/api/health

---

## Docker Commands Reference

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Rebuild specific service
docker-compose up -d --build frontend

# View logs
docker-compose logs -f backend

# Shell into container
docker-compose exec backend sh

# Database shell
docker-compose exec database psql -U devops_admin -d devops_dashboard
```

---

## Production Deployment with Docker

### Option 1: Docker Compose on EC2

```bash
# On EC2 instance
sudo apt update
sudo apt install docker.io docker-compose -y

# Clone repo
git clone YOUR_REPO
cd YOUR_REPO

# Configure
cp .env.example .env
nano .env  # Set production values

# Deploy
docker-compose -f docker-compose.yml up -d
```

### Option 2: AWS ECS/Fargate

Use the GitHub Actions workflow `docker-build.yml` to push images to ECR, then deploy to ECS.

---

## CI/CD Setup

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `FRONTEND_EC2_HOST` | Elastic IP of Frontend EC2 |
| `BACKEND_EC2_PRIVATE_IP` | Private IP of Backend EC2 (e.g., 10.0.2.10) |
| `EC2_SSH_KEY` | Private SSH key for EC2 access |
| `DOMAIN` | Your domain name |
| `AWS_ACCESS_KEY_ID` | AWS credentials (for ECR) |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials (for ECR) |

### Setting Up Secrets in GitHub

1. Go to Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret listed above

---

## Pipelines Overview

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Pull Requests | Lint, typecheck, build, security audit |
| `deploy.yml` | Push to main | Deploy to EC2 instances |
| `docker-build.yml` | Push to main/tags | Build & push Docker images to ECR |

---

## Troubleshooting

### Container won't start
```bash
docker-compose logs backend
docker-compose exec backend cat /app/.env
```

### Database connection issues
```bash
docker-compose exec backend ping database
docker-compose exec database psql -U devops_admin -d devops_dashboard -c "SELECT 1"
```

### Rebuild from scratch
```bash
docker-compose down -v  # Removes volumes too!
docker-compose up -d --build
```