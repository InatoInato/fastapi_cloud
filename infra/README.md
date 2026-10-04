# First Terraform lab: import an SSH public key

This is the only Terraform root. It manages one EC2 key pair: no VM, VPC, or
database. Use this to practise Terraform state and compare it with AWS before
adding infrastructure.

From the project root, first confirm the AWS account. If you use a named
profile, set `AWS_PROFILE` in this shell before running Terraform.

```bash
aws sts get-caller-identity
```

Create the lab SSH key only if you do not already have it:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/aws-fastapi-lab
```

Then prepare Terraform and review its plan:

```bash
terraform -chdir=infra init
terraform -chdir=infra fmt -check
terraform -chdir=infra validate
terraform -chdir=infra plan
```

The plan should show one `aws_key_pair`. Terraform uploads the `.pub` file;
keep the private key on your Mac. To use another key or region, copy
`infra/terraform.tfvars.example` to `infra/terraform.tfvars` and edit it. Do
not put AWS credentials or app secrets in Terraform files.

Read the plan, then apply and compare Terraform's state with AWS:

```bash
terraform -chdir=infra apply
terraform -chdir=infra output
terraform -chdir=infra state list
aws ec2 describe-key-pairs --region "$(terraform -chdir=infra output -raw region)" --key-names "$(terraform -chdir=infra output -raw key_pair_name)"
aws sts get-caller-identity
```

Try a failure: run `AWS_PROFILE=does-not-exist terraform -chdir=infra plan`,
read the credential error, then run `aws sts get-caller-identity` with your
real profile. If AWS reports `AccessDenied`, inspect the denied action before
changing IAM permissions.

When finished, remove the key pair with:

```bash
terraform -chdir=infra destroy
```

Read the destroy plan before confirming. The private key on your Mac remains.

Next, add networking to this same root one resource at a time: VPC, subnets,
Internet Gateway, routes, and Security Groups. Check the plan and AWS CLI after
each change. Add EC2 only after you can explain the routes and rules. Leave NAT
Gateway and RDS until later; both can add ongoing charges.
