# Terraform Main Configuration
# File: deployment/terraform/main.tf
# Complete 3-Tier AWS Infrastructure

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Uncomment for remote state storage
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "devops-dashboard/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "devops-dashboard"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ============================================
# DATA SOURCES
# ============================================

# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================
# VPC & NETWORKING
# ============================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Subnet (Frontend)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Tier = "public"
  }
}

# Private Subnet (Backend)
resource "aws_subnet" "private_backend" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_backend_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-private-backend"
    Tier = "backend"
  }
}

# Private Subnet (Database)
resource "aws_subnet" "private_database" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_database_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-private-database"
    Tier = "database"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_backend" {
  subnet_id      = aws_subnet.private_backend.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_database" {
  subnet_id      = aws_subnet.private_database.id
  route_table_id = aws_route_table.private.id
}

# ============================================
# SECURITY GROUPS
# ============================================

# Frontend Security Group
resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-frontend-sg"
  description = "Security group for frontend EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-frontend-sg"
  }
}

# Backend Security Group
resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-sg"
  description = "Security group for backend EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "API from Frontend"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  ingress {
    description     = "SSH from Frontend (bastion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-sg"
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  name        = "${var.project_name}-database-sg"
  description = "Security group for database EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from Backend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  ingress {
    description     = "SSH from Backend (bastion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-database-sg"
  }
}

# ============================================
# EC2 INSTANCES
# ============================================

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key
}

# Elastic IP for Frontend
resource "aws_eip" "frontend" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-frontend-eip"
  }
}

# Frontend EC2
resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.frontend_instance_type
  key_name                    = aws_key_pair.deployer.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.frontend.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              systemctl enable nginx
              systemctl start nginx
              EOF

  tags = {
    Name = "${var.project_name}-frontend"
    Tier = "frontend"
  }
}

# Associate Elastic IP with Frontend
resource "aws_eip_association" "frontend" {
  instance_id   = aws_instance.frontend.id
  allocation_id = aws_eip.frontend.id
}

# Backend EC2
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.backend_instance_type
  key_name               = aws_key_pair.deployer.key_name
  subnet_id              = aws_subnet.private_backend.id
  vpc_security_group_ids = [aws_security_group.backend.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
              apt-get install -y nodejs
              npm install -g pm2
              EOF

  tags = {
    Name = "${var.project_name}-backend"
    Tier = "backend"
  }
}

# Database EC2
resource "aws_instance" "database" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.database_instance_type
  key_name               = aws_key_pair.deployer.key_name
  subnet_id              = aws_subnet.private_database.id
  vpc_security_group_ids = [aws_security_group.database.id]

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y postgresql postgresql-contrib
              systemctl enable postgresql
              systemctl start postgresql
              EOF

  tags = {
    Name = "${var.project_name}-database"
    Tier = "database"
  }
}

# ============================================
# ROUTE53 (Optional)
# ============================================

# Uncomment if using Route53
# resource "aws_route53_zone" "main" {
#   name = var.domain_name
# }

# resource "aws_route53_record" "root" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = var.domain_name
#   type    = "A"
#   ttl     = "300"
#   records = [aws_eip.frontend.public_ip]
# }

# resource "aws_route53_record" "www" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "www.${var.domain_name}"
#   type    = "A"
#   ttl     = "300"
#   records = [aws_eip.frontend.public_ip]
# }

# ============================================
# CLOUDWATCH MONITORING
# ============================================

resource "aws_cloudwatch_metric_alarm" "cpu_high_frontend" {
  alarm_name          = "${var.project_name}-frontend-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors frontend EC2 CPU utilization"
  
  dimensions = {
    InstanceId = aws_instance.frontend.id
  }

  alarm_actions = [] # Add SNS topic ARN for notifications
}

resource "aws_cloudwatch_metric_alarm" "cpu_high_backend" {
  alarm_name          = "${var.project_name}-backend-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors backend EC2 CPU utilization"
  
  dimensions = {
    InstanceId = aws_instance.backend.id
  }

  alarm_actions = []
}

resource "aws_cloudwatch_metric_alarm" "cpu_high_database" {
  alarm_name          = "${var.project_name}-database-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors database EC2 CPU utilization"
  
  dimensions = {
    InstanceId = aws_instance.database.id
  }

  alarm_actions = []
}
