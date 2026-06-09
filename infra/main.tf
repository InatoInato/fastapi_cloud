provider "aws" {
    region = "eu-central-1"
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

    key_name = aws_key_pair.lab.key_name

    vpc_security_group_ids = [aws_security_group.fastapi_sg.id]

    user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    exec > /var/log/user-data.log 2>&1

    apt-get update
    apt-get install -y docker.io git

    systemctl enable docker
    systemctl start docker

    usermod -aG docker ubuntu

    cd /opt

    git clone https://github.com/InatoInato/fastapi_cloud.git

    cd fastapi_cloud

    docker build -t fastapi .

    docker run -d \
    --name fastapi \
    --restart unless-stopped \
    -p 80:8000 \
    fastapi

    EOF

    tags = {
        Name = "fastapi-server"
    }
}

output "public_ip" {
    value = aws_instance.fastapi.public_ip
}