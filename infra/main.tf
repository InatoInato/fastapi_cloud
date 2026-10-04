# Read-only: show which AWS account the current credentials target.
data "aws_caller_identity" "current" {}

# Lab 1's single managed resource. Lab 3 can attach it to an EC2 instance.
resource "aws_key_pair" "lab" {
  key_name_prefix = "aws-fastapi-lab-"
  public_key      = file(pathexpand(var.public_key_path))

  tags = {
    Project = "aws-fastapi-lab"
  }
}
