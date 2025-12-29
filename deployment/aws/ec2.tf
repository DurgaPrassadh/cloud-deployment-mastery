# AWS EC2 Instances Terraform Configuration
# File: ec2.tf

# Latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "devops-deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Update with your public key path
}

# Frontend EC2
resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  key_name                    = aws_key_pair.deployer.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.frontend.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "devops-frontend"
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
  instance_type          = "t3.small"
  key_name               = aws_key_pair.deployer.key_name
  subnet_id              = aws_subnet.private_backend.id
  vpc_security_group_ids = [aws_security_group.backend.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "devops-backend"
    Tier = "backend"
  }
}

# Database EC2
resource "aws_instance" "database" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.deployer.key_name
  subnet_id              = aws_subnet.private_database.id
  vpc_security_group_ids = [aws_security_group.database.id]

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name = "devops-database"
    Tier = "database"
  }
}

# Outputs
output "frontend_public_ip" {
  value = aws_eip.frontend.public_ip
}

output "frontend_private_ip" {
  value = aws_instance.frontend.private_ip
}

output "backend_private_ip" {
  value = aws_instance.backend.private_ip
}

output "database_private_ip" {
  value = aws_instance.database.private_ip
}