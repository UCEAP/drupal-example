# Deployment Guide - Drupal Example on AWS

This guide walks through deploying the Drupal application infrastructure to AWS.

## Prerequisites

- ✅ Common infrastructure applied (`iac-common/terraform/infra` - ACM cert + Route 53)
- ✅ Common IAM infrastructure applied (`iac-common/terraform/iam` - creates GitHub Actions IAM user)
- ✅ Terraform Cloud workspace configured with AWS credentials
- ✅ GitHub token configured for Terraform
- ✅ **GitHub Actions AWS credentials configured** (see "Manual GitHub Setup" below)

## Manual GitHub Setup

**⚠️ IMPORTANT:** AWS IAM credentials must be manually added to GitHub repository secrets.

The IAM user `github-actions` is created by the common IAM infrastructure. You need to retrieve the access key and add it to GitHub:

### Configure GitHub Secrets

```bash
gh variable set AWS_ACCESS_KEY_ID --body "(IAM access key ID)"
gh secret set AWS_SECRET_ACCESS_KEY --body "(IAM secret access key)"
```

## Deployment Steps

### Step 1: Apply Terraform Infrastructure

Deploy all AWS resources for the Drupal application:

```bash
cd /workspaces/drupal-example/terraform
terraform plan   # Review what will be created
terraform apply  # Create the infrastructure
```

**What gets created:**
- VPC with public/private/database subnets across 2 AZs
- NAT Gateways (2 for high availability)
- Security groups for ALB, ECS, RDS, Redis
- RDS MySQL Multi-AZ (db.t4g.micro)
- ElastiCache Redis Multi-AZ (cache.t4g.micro × 2)
- Application Load Balancer with HTTPS
- AWS WAF (OWASP Top 10 protection)
- ECR repository for Docker images
- ECS cluster, task definition, and service
- CloudWatch log groups and alarms
- GitHub Actions secrets and variables
- Route 53 A record: `demo.drupal-example.uceap.net` → ALB

**Estimated time:** 10-15 minutes

**⚠️ Note:** The ECS service will fail to start tasks initially because there's no Docker image in ECR yet. This is expected!

### Step 2: Push Initial Docker Image to ECR

Choose one of the following options:

#### Option A: Manual Push (Faster for First Deployment)

```bash
# Get ECR repository URL from Terraform output
cd /workspaces/drupal-example/terraform
ECR_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region)

# Build Docker image
cd /workspaces/drupal-example
docker build -t drupal-example .

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_URL

# Tag and push
docker tag drupal-example:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

#### Option B: GitHub Actions (Automatic)

```bash
# Commit and push to main branch
git add .
git commit -m "Deploy infrastructure and application"
git push origin main
```

This triggers the GitHub Actions workflow (`build_deploy_and_test.yml`) which:
1. Builds the Docker image
2. Pushes to ECR with tags `:latest` and `:${git-sha}`
3. Updates the ECS service to deploy the new image

### Step 3: Verify ECS Tasks Start

Wait 2-3 minutes for ECS to pull the image and start tasks:

```bash
cd /workspaces/drupal-example/terraform

# Check ECS service status
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name) \
  --region us-west-2 \
  --query 'services[0].{DesiredCount:desiredCount,RunningCount:runningCount,Status:status,Events:events[0:3]}'

# View ECS task logs in real-time
aws logs tail /ecs/drupal-example --follow --region us-west-2
```

**Expected output:**
- `DesiredCount`: 1
- `RunningCount`: 1
- `Status`: ACTIVE
- Recent events showing "service has reached a steady state"

### Step 4: Access Your Application

```bash
cd /workspaces/drupal-example/terraform
terraform output app_url
```

Visit the URL in your browser: **https://demo.drupal-example.uceap.net**

- ✅ HTTP requests automatically redirect to HTTPS
- ✅ Valid SSL certificate from ACM
- ✅ Protected by AWS WAF

---

## Verification Checklist

### DNS Resolution
```bash
dig demo.drupal-example.uceap.net
# Should return ALB IP addresses
```

### HTTPS Certificate
```bash
curl -I https://demo.drupal-example.uceap.net
# Should return 200 or 302 with valid SSL
```

### Database Connectivity (from ECS container)
```bash
# Get a running task ID
TASK_ID=$(aws ecs list-tasks \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service-name $(terraform output -raw ecs_service_name) \
  --region us-west-2 \
  --query 'taskArns[0]' \
  --output text | awk -F/ '{print $NF}')

# Connect to container via SSM Session Manager
aws ecs execute-command \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --task $TASK_ID \
  --container drupal \
  --interactive \
  --command "/bin/bash" \
  --region us-west-2

# Inside container, test MySQL connection
mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "SELECT 1;"
```

### Redis Connectivity (from ECS container)
```bash
# Inside ECS container (via execute-command above)
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_AUTH PING
# Should return: PONG
```

### CloudWatch Logs
- AWS Console → CloudWatch → Log groups → `/ecs/drupal-example`
- Check for application startup logs and errors

### WAF Metrics
- AWS Console → WAF & Shield → Web ACLs → `drupal-example-alb-waf`
- Review allowed/blocked request metrics

---

## Making Changes After Deployment

### Infrastructure Changes

Edit Terraform configuration files (*.tf), then:

```bash
cd /workspaces/drupal-example/terraform
terraform plan    # Review changes
terraform apply   # Apply changes
```

### Application Updates (New Docker Image)

#### Automatic via GitHub Actions (Recommended)

```bash
# Make code changes, commit, and push to main
git add .
git commit -m "Update application"
git push origin main
```

GitHub Actions will automatically:
1. Build new Docker image
2. Push to ECR with `:latest` and `:${git-sha}` tags
3. Update ECS task definition
4. Deploy to ECS service (rolling update)

#### Manual Deployment

```bash
# Build and push
cd /workspaces/drupal-example
docker build -t drupal-example .
ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)
docker tag drupal-example:latest $ECR_URL:latest
docker push $ECR_URL:latest

# Force new deployment
cd terraform
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --force-new-deployment \
  --region us-west-2
```

---

## Troubleshooting

### ECS Tasks Not Starting

**Check service events:**
```bash
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name) \
  --region us-west-2 \
  --query 'services[0].events[0:5]'
```

**Common causes:**
- **No Docker image in ECR** → Push image (see Step 2)
- **Task can't pull image** → Check IAM task execution role has ECR permissions
- **Health checks failing** → Check application logs in CloudWatch
- **Resource limits** → Check if CPU/memory limits are appropriate

### Can't Access Application

**Check ALB target health:**
```bash
cd /workspaces/drupal-example/terraform
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names ecs-$(terraform output -raw ecs_service_name) \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text) \
  --region us-west-2
```

**Common causes:**
- **Tasks not healthy** → Check health check path (`/`) returns 200-399
- **Security group issues** → Verify ALB security group can reach ECS tasks on port 80
- **DNS not propagated** → Wait 5-10 minutes, check with `dig`
- **Certificate issues** → Verify ACM certificate is issued and validated

### Database Connection Errors

**Common causes:**
- **Wrong credentials** → Check AWS Secrets Manager values match RDS
- **Security group** → Verify ECS security group has ingress from RDS security group on port 3306
- **DNS resolution** → RDS endpoint should resolve inside VPC
- **Drupal not configured** → Check `MYSQL_*` environment variables in task definition

### Redis Connection Errors

**Common causes:**
- **Auth token mismatch** → Verify `REDIS_AUTH` secret in Secrets Manager
- **Security group** → Verify ECS security group can reach Redis on port 6379
- **TLS issues** → Redis has `transit_encryption_enabled = true`, ensure app supports TLS
- **Endpoint wrong** → Verify using `primary_endpoint_address` not individual node

### High Costs

If you see unexpected AWS bills:

**Check running resources:**
```bash
# NAT Gateways (most expensive)
aws ec2 describe-nat-gateways --region us-west-2

# Running ECS tasks
aws ecs list-tasks --cluster $(terraform output -raw ecs_cluster_name) --region us-west-2

# RDS instances
aws rds describe-db-instances --region us-west-2

# ElastiCache clusters
aws elasticache describe-replication-groups --region us-west-2
```

**Cost optimization options:**
- Reduce to 1 NAT Gateway (lose HA): Save ~$32/month
- Use RDS Single-AZ (dev only): Save ~$12/month
- Reduce ECS min_capacity to 0 when not testing: Save ~$29/month per task

---

## Monitoring

### CloudWatch Alarms

The following alarms are configured but **not sending notifications** (no SNS topic):

1. **ECS Task Count** - Alerts if running tasks < minimum
2. **ECS CPU High** - Alerts if CPU > 90% for 15 minutes
3. **RDS CPU High** - Alerts if database CPU > 80% for 15 minutes
4. **ALB Unhealthy Targets** - Alerts if any targets are unhealthy
5. **WAF Blocked Requests** - Alerts if > 100 requests blocked in 5 minutes

**To enable email notifications:** See `TODO.md` for SNS topic setup instructions.

### Viewing Logs

```bash
# ECS application logs (real-time)
aws logs tail /ecs/drupal-example --follow --region us-west-2

# WAF logs (security events)
aws logs tail /aws/waf/drupal-example --follow --region us-west-2

# Filter logs for errors
aws logs tail /ecs/drupal-example --filter-pattern "ERROR" --region us-west-2
```

### Metrics Dashboard

View in AWS Console:
- **ECS**: CloudWatch → Container Insights → ECS clusters → drupal-example-cluster
- **RDS**: RDS → Databases → drupal-example-mysql → Monitoring
- **Redis**: ElastiCache → Redis clusters → drupal-example-redis → Metrics
- **ALB**: EC2 → Load Balancers → drupal-example-alb → Monitoring
- **WAF**: WAF & Shield → Web ACLs → drupal-example-alb-waf → Overview

---

## Cleanup / Destroy Infrastructure

**⚠️ Warning:** This will permanently delete all resources including databases!

```bash
cd /workspaces/drupal-example/terraform

# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

**Manual cleanup required:**
- ALB access logs in S3 bucket (bucket will fail to delete if not empty)
- ECR images (delete manually or set lifecycle policy)

To empty S3 bucket before destroy:
```bash
BUCKET_NAME=$(aws s3 ls | grep drupal-example-alb-logs | awk '{print $3}')
aws s3 rm s3://$BUCKET_NAME --recursive
```

---

## Next Steps

### Short-term (1-2 weeks)
- ✅ Monitor CloudWatch logs and metrics
- ✅ Test GitHub Actions deployments by pushing code changes
- ✅ Verify auto-scaling by generating load
- ⏳ Set up SNS notifications for CloudWatch alarms
- ⏳ Test database backups and restore procedures

### Medium-term (before production)
Review `TODO.md` for production hardening:
- Enable RDS deletion protection
- Require final snapshots on RDS deletion
- Enable TLS for MySQL connections
- Increase log retention periods
- Use semantic versioning for Docker images
- Add monitoring dashboards
- Perform load testing

---

## Support & Documentation

**Terraform Outputs:**
```bash
cd /workspaces/drupal-example/terraform
terraform output  # View all outputs
```

**Architecture Diagram:**
See `aws_drupal_infrastructure.png` in the terraform directory

**Cost Estimate:**
- Minimum (1 ECS task): ~$165-178/month
- Average (2 ECS tasks): ~$194-207/month
- Peak (3 ECS tasks): ~$223-236/month

**AWS Documentation:**
- [ECS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [RDS Multi-AZ](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)
- [ElastiCache Redis](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/WhatIs.html)
- [AWS WAF](https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html)
