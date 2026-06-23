output "public_ip" {
  value       = aws_eip.fastapi_eip.public_ip
  description = "Static Elastic IP of FastAPI server"
}

output "my_ip_detected" {
  value       = local.my_cidr
  description = "Your current IP that was whitelisted for SSH"
}