variable "aws_region" {
  description = "Region where this lab's key pair will be registered."
  type        = string
  default     = "us-east-1"
}

variable "public_key_path" {
  description = "Path to your existing SSH public key. Keep the private key on your Mac."
  type        = string
  default     = "~/.ssh/aws-fastapi-lab.pub"
}
