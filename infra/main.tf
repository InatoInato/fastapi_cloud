provider "aws" {
    region = "us-east-1"
}

data "aws_ami" "ubuntu" {
    most_recent = true

    owners = ["099720109477"] # Canonical

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_key_pair" "lab" {
    key_name   = "aws-lab"
    public_key = file("/Users/inato/.ssh/aws-lab.pub")
}

resource "aws_security_group" "fastapi_sg" {
    name        = "fastapi-sg"
    description = "Allow SSH and HTTP"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
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

    associate_public_ip_address = true

    key_name = aws_key_pair.lab.key_name

    vpc_security_group_ids = [
        aws_security_group.fastapi_sg.id
    ]

    user_data = <<-EOF
            #!/bin/bash
            apt update -y
            apt install -y python3-pip python3-venv
            python3 -m venv /opt/venv
            /opt/venv/bin/pip install fastapi uvicorn
        EOF

    tags = {
        Name = "fastapi-server"
    }
}

output "public_ip" {
    value = aws_instance.fastapi.public_ip
}