terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# The AWS provider reads your AWS CLI profile or environment credentials.
provider "aws" {
  region = var.aws_region
}
