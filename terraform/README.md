# AWS Infrastructure for Drupal Application

This directory contains Terraform configuration to deploy the Drupal application on AWS using ECS Fargate.

## Architecture

The infrastructure consists of:

- **VPC**: Custom VPC with public, private, and database subnets across 2 availability zones
- **ECS Fargate**: Serverless container orchestration for running Drupal
- **Application Load Balancer**: Distributes traffic to ECS tasks with cross-zone load balancing
- **AWS WAF**: Web Application Firewall protecting against OWASP Top 10 attacks
- **RDS MySQL**: Managed MySQL database (db.t4g.micro)
- **ElastiCache Redis**: Managed Redis cache (cache.t4g.micro)
- **Auto Scaling**: Scales ECS tasks based on CPU and memory utilization (1-3 tasks)
- **CloudWatch**: Centralized logging for ECS tasks and WAF metrics
- **GitHub Actions Integration**: Automatically sets secrets and variables
- **SSM Session Manager**: Secure access to running ECS tasks for debugging

## Prerequisites

1. **AWS CLI** configured with credentials
2. **Terraform** >= 1.0
3. **GitHub Token** with repo and workflow permissions

## Setup

### 1. Configure AWS Credentials

Ensure your AWS CLI is configured with appropriate credentials:

```bash
aws configure
```

Or use environment variables:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
```

### 2. Set GitHub Token

You need a GitHub Personal Access Token with `repo` and `workflow` scopes:

```bash
export TF_VAR_github_token="your-github-token"
```

Or create a `terraform.tfvars` file:

```hcl
github_token = "your-github-token"
```

### 3. Initialize Terraform

```bash
cd terraform
terraform init
```

### 4. Review and Customize Variables

Edit `variables.tf` or create `terraform.tfvars` to customize:

```hcl
name_prefix  = "my-drupal-app"
aws_region   = "us-west-2"

# Adjust instance sizes for production
db_instance_class = "db.t4g.small"
redis_node_type   = "cache.t4g.small"
ecs_task_cpu      = 1024
ecs_task_memory   = 2048
```

## Deployment

### Plan

Preview what Terraform will create:

```bash
terraform plan
```

### Apply

Create the infrastructure:

```bash
terraform apply
```

This will take approximately 10-15 minutes to provision all resources.

### Get Application URL

After deployment completes:

```bash
terraform output alb_url
```

Visit the URL to access your Drupal application.

## Post-Deployment

### Manual Steps

Unlike Azure, AWS ECS doesn't require manual post-deployment configuration. However, you may want to:

1. **Configure DNS**: Point your domain to the ALB DNS name using a CNAME record
2. **Enable HTTPS**: Add an ACM certificate and uncomment the HTTPS listener in `alb.tf`
3. **Enable Multi-AZ for RDS**: Set `multi_az = true` in `rds.tf` for production

### GitHub Actions Variables

Terraform automatically sets these secrets/variables in your GitHub repository:

**Secrets (Secrets Manager ARNs):**
- `AWS_HASH_SALT_SECRET_ARN` - ARN of Drupal hash salt secret
- `AWS_MYSQL_PASSWORD_SECRET_ARN` - ARN of database password secret
- `AWS_REDIS_AUTH_SECRET_ARN` - ARN of Redis auth token secret

Note: Sensitive values are stored in AWS Secrets Manager and referenced by ARN. The ECS task retrieves values at runtime from Secrets Manager rather than reading plaintext environment variables.

**Variables:**
- `AWS_MYSQL_HOST`
- `AWS_MYSQL_TCP_PORT`
- `AWS_MYSQL_USER`
- `AWS_MYSQL_DATABASE`
- `AWS_REDIS_HOST`
- `AWS_REDIS_PORT`
- `AWS_ECS_CLUSTER`
- `AWS_ECS_SERVICE`
- `AWS_ECS_TASK_DEFINITION`
- `AWS_REGION`

Use these in your GitHub Actions workflows to deploy updates.

## Updating the Application

To deploy a new version of your Docker image:

1. Build and push new image to GHCR
2. Update the ECS service to force a new deployment:

```bash
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --force-new-deployment \
  --region us-west-2
```

Or use the GitHub Actions workflow with the exported variables.

## Monitoring

### View ECS Logs

```bash
aws logs tail /ecs/drupal-example --follow --region us-west-2
```

### Check ECS Service Status

```bash
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name) \
  --region us-west-2
```

### View Running Tasks

```bash
aws ecs list-tasks \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --region us-west-2
```

## Cost Optimization

For development/testing environments, consider:

- Using smaller instance types (already configured with t4g.micro)
- Reducing `ecs_min_capacity` to 0 when not in use
- Setting `deletion_protection = false` on RDS to allow easy cleanup
- Using spot instances (requires switching from Fargate to EC2 launch type)

Estimated monthly cost: ~$50-80 USD for the minimal configuration

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources including databases. Make sure you have backups!

## Differences from Azure Configuration

| Azure | AWS Equivalent |
|-------|----------------|
| Azure Web App | ECS Fargate |
| Azure MySQL Flexible Server | RDS MySQL |
| Azure Redis Cache | ElastiCache Redis |
| App Service Plan | ECS Cluster + Task Definition |
| Resource Group | N/A (implicit in AWS) |
| Publish Profile | ECS Task Definition + Service |

Key differences:
- AWS requires explicit VPC and networking configuration
- AWS uses IAM roles instead of managed identities
- ECS requires task definitions with detailed container specs
- ALB is separate from ECS (unlike Azure Web App's built-in endpoint)
- Environment variables are set in task definition, not app service config

## Troubleshooting

### ECS Tasks Not Starting

Check the ECS service events:
```bash
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name) \
  --region us-west-2 \
  --query 'services[0].events[0:5]'
```

### Database Connection Issues

1. Verify security group rules allow ECS tasks to access RDS
2. Check database endpoint in task definition
3. Ensure `require_secure_transport` is set to 0 (already configured)

### Redis Connection Issues

1. Verify ElastiCache is in the same VPC
2. Check security group allows port 6379 from ECS tasks
3. Ensure auth token is correctly passed to container

## File Structure

```
terraform/
├── main.tf              # Main documentation
├── providers.tf         # AWS provider configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── vpc.tf              # VPC and networking
├── security_groups.tf   # Security groups
├── alb.tf              # Application Load Balancer
├── waf.tf              # AWS WAF rules and protection
├── rds.tf              # MySQL database
├── elasticache.tf      # Redis cache
├── ecs.tf              # ECS cluster and service
├── secrets.tf          # AWS Secrets Manager for sensitive data
├── iam.tf              # IAM roles and policies
├── cloudwatch.tf       # Log groups
├── github.tf           # GitHub integration
└── TODO.md             # Deferred architecture improvements
```

## Support

For issues or questions:
- Check CloudWatch logs for application errors
- Review ECS service events for deployment issues
- Consult AWS documentation for service-specific problems
