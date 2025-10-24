# Terraform Architecture Review - Deferred Tasks

## VPC & Network
- [ ] Implement VPC Flow Logs for traffic debugging and monitoring

## Security & Management
- [x] Configure SSM Session Manager for ECS task access
  - Note: SSH to private database resources still requires a bastion host or RDS Proxy with SSM
  - For now, you can access ECS tasks via: `aws ecs execute-command --cluster <cluster> --task <task-id> --container drupal --interactive --command "/bin/bash"`

## Load Balancer
- [x] Set up ACM certificate for HTTPS (Route53 validation)
  - Implemented: Wildcard certificate *.uceap.net in iac-common/terraform/infra/acm.tf
  - DNS validation via Route 53 (automatic)
  - HTTPS listener enabled in alb.tf with TLS 1.3/1.2 policy
  - HTTP listener redirects to HTTPS (301)
  - Custom domain configured: demo.drupal-example.uceap.net
- [x] Enable ALB access logs to S3 for audit trail and debugging
- [ ] Enable deletion protection on ALB to prevent accidental deletion (currently false in alb.tf:58)

## ECS & Containers
- [x] Move secrets from Docker build-args to runtime environment variables
  - Removed ARGs from Dockerfile (MYSQL_PASSWORD, REDIS_AUTH, HASH_SALT)
  - Moved composer initialize-container from build-time to entrypoint (runtime)
  - Removed build-args from GitHub Actions workflow
  - Secrets now injected at runtime from AWS Secrets Manager
- [ ] Enforce specific Docker image tags (semantic versioning) instead of :latest for production deployments
- [ ] Change GitHub Secrets for AWS Secret Manager ARNs to GitHub Variables

## RDS Database
- [ ] Enable deletion protection for production (currently false in rds.tf:40)
- [ ] Require final snapshot on database deletion for data protection (currently skip_final_snapshot = true in rds.tf:43)
- [ ] Enable auto_minor_version_upgrade for automatic security patches (currently false in rds.tf:37)
- [ ] Adjust backup window (3am) and maintenance window (4am Monday) to avoid overlap
- [ ] Enable require_secure_transport = 1 for mandatory TLS database connections (currently 0 in rds.tf:66)
- [ ] Consider read replicas for scaling read-heavy Drupal workloads

## ElastiCache Redis
- [x] Enable Redis Replication Group (primary + replica) for Multi-AZ failover
  - Implemented: aws_elasticache_replication_group with automatic_failover_enabled = true
  - Multi-AZ enabled with 2 cache clusters (1 primary + 1 replica)
  - At-rest encryption enabled
- [ ] Change apply_immediately to false for safer production deployments (currently true in elasticache.tf:35)

## GitHub Actions Integration
- [x] Configure GitHub Actions to automatically set secrets and variables
  - AWS credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) from common IAM
  - Secrets Manager ARNs for database password, Redis auth, Drupal hash salt
  - ECS cluster, service, task definition names
  - ECR repository URL for image pushes
  - Database and Redis connection details
- [x] Remove secrets from Docker build process (completed above in ECS & Containers)

## Monitoring & Alerting
- [ ] Configure SNS topics and email subscriptions for CloudWatch alarm notifications
  - Create SNS topic for production alerts
  - Add SNS topic ARN to alarm_actions in cloudwatch.tf (currently empty arrays)
  - Current alarms created: ECS task count, ECS CPU, RDS CPU, ALB unhealthy targets, WAF blocked requests
- [ ] Set up log insights queries and dashboards for monitoring trends
- [ ] Configure long-term log archival to cheaper storage (e.g., S3 Glacier for logs older than 90 days)
