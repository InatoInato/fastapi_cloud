# FastAPI Production Infrastructure

## Security Improvements

- ✅ **Application Load Balancer (ALB)** - Distributes traffic and terminates HTTP connections
- ✅ **Explicit VPC** - Full control over network isolation and CIDR blocks
- ✅ **IAM Roles** - EC2 instance runs with minimal required permissions
- ✅ **Security Groups** - Multi-layer: ALB accepts from internet, EC2 only from ALB
- ✅ **CloudWatch Logging** - System metrics and application logs centralized
- ✅ **Encrypted EBS** - Root volume encrypted by default
- ✅ **SSH Restrictions** - Limited to specific CIDR block (not 0.0.0.0/0)
- ✅ **Detectable Port** - Application runs on private port 8000, not exposed

## Setup Instructions

### 1. Configure Variables

```bash
cp infra/terraform.tfvars.example infra/terraform.tfvars
# Edit terraform.tfvars with your values:
# - allowed_ssh_cidr: Your IP address (e.g., 203.0.113.0/32)
# - instance_type: t3.small or larger for production
```

### 2. Initialize Terraform

```bash
cd infra
terraform init
```

### 3. Review Changes

```bash
terraform plan
```

### 4. Deploy

```bash
terraform apply
```

## Architecture

```
Internet → ALB (Port 80/443)
           ↓
        Security Group (allows 80/443)
           ↓
        EC2 Instance (Port 8000)
           ↓
        Docker Container (FastAPI)
```

## Next Steps for Production

1. **HTTPS/TLS**: Add ACM certificate and HTTPS listener to ALB
   - Request certificate from AWS Certificate Manager
   - Update ALB listener to use HTTPS
   - Redirect HTTP to HTTPS

2. **Auto Scaling**: Replace single instance with ASG
   - Create launch template
   - Configure Auto Scaling Group
   - Set scaling policies based on CPU/memory

3. **RDS Database**: Move to managed database
   - Create RDS instance
   - Update security group for database access
   - Use Secrets Manager for credentials

4. **Secrets Management**:
   - Store API keys in AWS Secrets Manager
   - Update IAM policy to allow retrieval
   - Reference in application startup

5. **Monitoring & Alerting**:
   - Create CloudWatch alarms for CPU, memory, disk
   - Set up SNS for notifications
   - Configure dashboard for metrics

6. **Backups & Recovery**:
   - Enable automated EBS snapshots
   - Document RTO/RPO requirements
   - Test restore procedures

## Cost Estimation

- **ALB**: ~$16/month
- **EC2 t3.small**: ~$8/month
- **Storage (20GB gp3)**: ~$2/month
- **CloudWatch**: ~$5/month
- **Data transfer**: Variable

**Total: ~$30-50/month** (lower with Reserved Instances)

## Removing Resources

```bash
terraform destroy
```

⚠️ This will delete all AWS resources created by this configuration.
