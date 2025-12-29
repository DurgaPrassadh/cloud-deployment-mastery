# DevOps Dashboard - 3-Tier Architecture Deployment Guide

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              AWS VPC                                     │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                        Public Subnet                                │ │
│  │  ┌──────────────────────────────────────────────────────────────┐  │ │
│  │  │  FRONTEND EC2 (Public)                                        │  │ │
│  │  │  • React + Vite (Static Build)                               │  │ │
│  │  │  • Nginx (Reverse Proxy + SSL)                               │  │ │
│  │  │  • Elastic IP                                                 │  │ │
│  │  │  • Route53 + Domain                                          │  │ │
│  │  └──────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                    │                                     │
│                                    ▼ (Port 3000 - Private)              │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                        Private Subnet 1                             │ │
│  │  ┌──────────────────────────────────────────────────────────────┐  │ │
│  │  │  BACKEND EC2 (Private API)                                    │  │ │
│  │  │  • Node.js + Express                                         │  │ │
│  │  │  • PM2 (Process Manager)                                     │  │ │
│  │  │  • Port 3000 (Internal Only)                                 │  │ │
│  │  └──────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                    │                                     │
│                                    ▼ (Port 5432 - Private)              │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                        Private Subnet 2                             │ │
│  │  ┌──────────────────────────────────────────────────────────────┐  │ │
│  │  │  DATABASE EC2 (Private)                                       │  │ │
│  │  │  • PostgreSQL 15                                             │  │ │
│  │  │  • No Public IP                                              │  │ │
│  │  │  • Locked to Backend EC2 Only                                │  │ │
│  │  └──────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

- AWS Account with VPC configured
- 3 EC2 instances (Ubuntu 22.04 LTS recommended)
- Domain name (optional, for Route53)
- SSH access to all instances

---

## Step 1: VPC & Network Setup

### 1.1 Create VPC
```
VPC CIDR: 10.0.0.0/16
```

### 1.2 Create Subnets
```
Public Subnet:    10.0.1.0/24  (Frontend EC2)
Private Subnet 1: 10.0.2.0/24  (Backend EC2)
Private Subnet 2: 10.0.3.0/24  (Database EC2)
```

### 1.3 Create Internet Gateway
- Attach to VPC
- Add route to Public Subnet route table: `0.0.0.0/0 → IGW`

### 1.4 Create NAT Gateway (for private subnets to access internet)
- Place in Public Subnet
- Allocate Elastic IP
- Add route to Private Subnet route tables: `0.0.0.0/0 → NAT-GW`

---

## Step 2: Security Groups

### 2.1 Frontend Security Group (`sg-frontend`)
| Type  | Port | Source        | Description           |
|-------|------|---------------|-----------------------|
| HTTP  | 80   | 0.0.0.0/0     | Public web access     |
| HTTPS | 443  | 0.0.0.0/0     | Public SSL access     |
| SSH   | 22   | Your IP       | Admin access          |

### 2.2 Backend Security Group (`sg-backend`)
| Type   | Port | Source        | Description           |
|--------|------|---------------|-----------------------|
| Custom | 3000 | sg-frontend   | API from frontend     |
| SSH    | 22   | sg-frontend   | Admin via bastion     |

### 2.3 Database Security Group (`sg-database`)
| Type       | Port | Source      | Description           |
|------------|------|-------------|-----------------------|
| PostgreSQL | 5432 | sg-backend  | DB from backend only  |
| SSH        | 22   | sg-backend  | Admin via bastion     |

---

## Step 3: Launch EC2 Instances

### 3.1 Frontend EC2
- **AMI**: Ubuntu 22.04 LTS
- **Instance Type**: t3.small (or larger)
- **Subnet**: Public Subnet
- **Auto-assign Public IP**: Yes
- **Security Group**: sg-frontend
- **Elastic IP**: Allocate and associate

### 3.2 Backend EC2
- **AMI**: Ubuntu 22.04 LTS
- **Instance Type**: t3.small (or larger)
- **Subnet**: Private Subnet 1
- **Auto-assign Public IP**: No
- **Security Group**: sg-backend

### 3.3 Database EC2
- **AMI**: Ubuntu 22.04 LTS
- **Instance Type**: t3.medium (for PostgreSQL)
- **Subnet**: Private Subnet 2
- **Auto-assign Public IP**: No
- **Security Group**: sg-database
- **Storage**: 50GB+ gp3

---

## Step 4: Deploy Database (Database EC2)

SSH to Database EC2 (via Backend EC2 as bastion):
```bash
# From Backend EC2
ssh -i key.pem ubuntu@10.0.3.10
```

Copy and run setup:
```bash
# Copy files
scp -i key.pem deployment/database/* ubuntu@10.0.3.10:~/

# SSH and run
ssh -i key.pem ubuntu@10.0.3.10
sudo bash setup-database.sh
```

---

## Step 5: Deploy Backend (Backend EC2)

SSH to Backend EC2 (via Frontend EC2):
```bash
# From Frontend EC2
ssh -i key.pem ubuntu@10.0.2.10
```

Copy and run setup:
```bash
# Copy files
scp -r -i key.pem deployment/backend/* ubuntu@10.0.2.10:~/

# SSH and run
ssh -i key.pem ubuntu@10.0.2.10
cd ~
sudo bash setup-backend.sh
```

Verify:
```bash
pm2 status
curl http://localhost:3000/api/health
```

---

## Step 6: Deploy Frontend (Frontend EC2)

SSH to Frontend EC2:
```bash
ssh -i key.pem ubuntu@YOUR_ELASTIC_IP
```

### 6.1 Build React App Locally
```bash
# On your local machine
cd your-project
npm run build

# Upload to EC2
scp -r -i key.pem dist/* ubuntu@YOUR_ELASTIC_IP:/var/www/devops-dashboard/
```

### 6.2 Run Frontend Setup
```bash
# Copy nginx config
scp -i key.pem deployment/frontend/* ubuntu@YOUR_ELASTIC_IP:~/

# SSH and run
ssh -i key.pem ubuntu@YOUR_ELASTIC_IP
sudo bash setup-frontend.sh
```

---

## Step 7: DNS Configuration (Route53)

### 7.1 Create Hosted Zone
- Domain: your-domain.com

### 7.2 Create Records
| Name              | Type | Value              |
|-------------------|------|--------------------|
| your-domain.com   | A    | Elastic IP         |
| www.your-domain.com | A  | Elastic IP         |

### 7.3 Update Nameservers at Registrar
Copy NS records from Route53 to your domain registrar (Hostinger, GoDaddy, etc.)

---

## Step 8: Verify Deployment

1. **Health Check**: `https://your-domain.com/api/health`
2. **Frontend**: `https://your-domain.com`
3. **PM2 Status**: `pm2 status` on Backend EC2
4. **Database**: `psql -h 10.0.3.10 -U devops_admin -d devops_dashboard`

---

## Monitoring & Maintenance

### PM2 Commands (Backend)
```bash
pm2 status        # Check status
pm2 logs          # View logs
pm2 restart all   # Restart
pm2 monit         # Real-time monitor
```

### Nginx Commands (Frontend)
```bash
sudo nginx -t                    # Test config
sudo systemctl restart nginx     # Restart
sudo tail -f /var/log/nginx/access.log
```

### PostgreSQL Commands (Database)
```bash
sudo -u postgres psql            # Access PostgreSQL
sudo systemctl status postgresql # Check status
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Can't connect to API | Check Backend SG allows 3000 from Frontend |
| Database connection failed | Check Database SG allows 5432 from Backend |
| SSL not working | Run `sudo certbot renew` |
| PM2 not starting on reboot | Run `pm2 save && pm2 startup` |

---

## Security Checklist

- [ ] All passwords changed from defaults
- [ ] SSH key-based auth only (disable password auth)
- [ ] Security groups properly configured
- [ ] Database has no public IP
- [ ] SSL/TLS enabled on frontend
- [ ] Regular backups configured
- [ ] CloudWatch monitoring enabled