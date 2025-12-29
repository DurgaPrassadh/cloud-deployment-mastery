# Terraform Outputs
# File: deployment/terraform/outputs.tf

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "frontend_public_ip" {
  description = "Elastic IP of the frontend EC2"
  value       = aws_eip.frontend.public_ip
}

output "frontend_instance_id" {
  description = "Instance ID of frontend EC2"
  value       = aws_instance.frontend.id
}

output "frontend_private_ip" {
  description = "Private IP of frontend EC2"
  value       = aws_instance.frontend.private_ip
}

output "backend_private_ip" {
  description = "Private IP of backend EC2"
  value       = aws_instance.backend.private_ip
}

output "backend_instance_id" {
  description = "Instance ID of backend EC2"
  value       = aws_instance.backend.id
}

output "database_private_ip" {
  description = "Private IP of database EC2"
  value       = aws_instance.database.private_ip
}

output "database_instance_id" {
  description = "Instance ID of database EC2"
  value       = aws_instance.database.id
}

output "nat_gateway_ip" {
  description = "Elastic IP of NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "ssh_command_frontend" {
  description = "SSH command to connect to frontend"
  value       = "ssh -i your-key.pem ubuntu@${aws_eip.frontend.public_ip}"
}

output "ssh_command_backend" {
  description = "SSH command to connect to backend (via frontend bastion)"
  value       = "ssh -i your-key.pem -J ubuntu@${aws_eip.frontend.public_ip} ubuntu@${aws_instance.backend.private_ip}"
}

output "ssh_command_database" {
  description = "SSH command to connect to database (via backend)"
  value       = "ssh -i your-key.pem -J ubuntu@${aws_eip.frontend.public_ip},ubuntu@${aws_instance.backend.private_ip} ubuntu@${aws_instance.database.private_ip}"
}

output "deployment_summary" {
  description = "Deployment summary"
  value = <<-EOT
    ╔══════════════════════════════════════════════════════════════╗
    ║                    DEPLOYMENT SUMMARY                         ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Frontend (Public):   ${aws_eip.frontend.public_ip}                        ║
    ║  Backend (Private):   ${aws_instance.backend.private_ip}                           ║
    ║  Database (Private):  ${aws_instance.database.private_ip}                           ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  VPC:                 ${aws_vpc.main.id}                       ║
    ║  NAT Gateway:         ${aws_eip.nat.public_ip}                        ║
    ╚══════════════════════════════════════════════════════════════╝
  EOT
}
