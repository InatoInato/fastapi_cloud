output "account_id" {
  description = "AWS account used by the provider. Compare with AWS CLI."
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "Region selected for this lab."
  value       = var.aws_region
}

output "key_pair_name" {
  description = "Name of the public SSH key imported into EC2."
  value       = aws_key_pair.lab.key_name
}
