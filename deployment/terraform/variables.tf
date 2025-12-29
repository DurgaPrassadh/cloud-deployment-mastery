# Terraform Variables
# File: deployment/terraform/variables.tf

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "devops-dashboard"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet (frontend)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_backend_cidr" {
  description = "CIDR block for private backend subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_database_cidr" {
  description = "CIDR block for private database subnet"
  type        = string
  default     = "10.0.3.0/24"
}

# EC2 Configuration
variable "frontend_instance_type" {
  description = "EC2 instance type for frontend"
  type        = string
  default     = "t3.small"
}

variable "backend_instance_type" {
  description = "EC2 instance type for backend"
  type        = string
  default     = "t3.small"
}

variable "database_instance_type" {
  description = "EC2 instance type for database"
  type        = string
  default     = "t3.medium"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production!
}

# Domain Configuration
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

# Database Configuration
variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "devops_dashboard"
}

variable "db_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "devops_user"
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}
