provider "aws" {
  region = "eu-central-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Who can SSH into EC2"
  type        = string
  default     = "0.0.0.0/0"
}

resource "aws_key_pair" "lab" {
  key_name   = "aws-lab"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "fastapi_sg" {
  name        = "fastapi-sg"
  description = "FastAPI security group"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "fastapi" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  key_name               = aws_key_pair.lab.key_name
  vpc_security_group_ids = [aws_security_group.fastapi_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    exec > /var/log/user-data.log 2>&1

    apt-get update
    apt-get install -y docker.io

    systemctl enable docker
    systemctl start docker

    usermod -aG docker ubuntu
  EOF

  tags = {
    Name = "fastapi-server"
  }
}

output "public_ip" {
  value       = aws_instance.fastapi.public_ip
  description = "Public IP of FastAPI server"
}