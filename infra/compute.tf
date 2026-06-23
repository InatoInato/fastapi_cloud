resource "aws_key_pair" "lab" {
  key_name   = "aws-lab"
  public_key = var.ssh_public_key
}

resource "aws_instance" "fastapi_cloud" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

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

resource "aws_eip" "fastapi_eip" {
  instance = aws_instance.fastapi_cloud.id
  domain   = "vpc"

  tags = {
    Name = "fastapi-static-ip"
  }
}