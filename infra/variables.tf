variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}