# Drupal Application Infrastructure on AWS
#
# This Terraform configuration deploys a Drupal application on AWS using:
# - ECS Fargate for container orchestration
# - RDS MySQL for the database
# - ElastiCache Redis for caching
# - Application Load Balancer for traffic distribution
# - VPC with public/private/database subnets across 2 availability zones
#
# The infrastructure is organized into modular files:
# - vpc.tf: VPC, subnets, route tables, NAT gateways
# - security_groups.tf: Security groups for ALB, ECS, RDS, Redis
# - alb.tf: Application Load Balancer and target groups
# - rds.tf: RDS MySQL database
# - elasticache.tf: ElastiCache Redis cluster
# - ecs.tf: ECS cluster, task definition, service, auto-scaling
# - iam.tf: IAM roles and policies for ECS
# - cloudwatch.tf: CloudWatch log groups
# - github.tf: GitHub Actions secrets and variables
# - outputs.tf: Terraform outputs
# - variables.tf: Input variables
# - providers.tf: Provider configuration
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
#
# After applying, access your application at the ALB DNS name:
#   terraform output alb_url
