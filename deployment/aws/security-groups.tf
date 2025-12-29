# AWS Security Group Terraform Configuration
# File: security-groups.tf

# Frontend Security Group
resource "aws_security_group" "frontend" {
  name        = "devops-frontend-sg"
  description = "Security group for Frontend EC2"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # SSH (restrict to your IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_IP/32"]
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-frontend-sg"
  }
}

# Backend Security Group
resource "aws_security_group" "backend" {
  name        = "devops-backend-sg"
  description = "Security group for Backend EC2"
  vpc_id      = aws_vpc.main.id

  # API from Frontend
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
    description     = "API access from frontend"
  }

  # SSH from Frontend (bastion)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
    description     = "SSH via bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-backend-sg"
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  name        = "devops-database-sg"
  description = "Security group for Database EC2"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL from Backend only
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
    description     = "PostgreSQL from backend"
  }

  # SSH from Backend (bastion)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
    description     = "SSH via bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-database-sg"
  }
}