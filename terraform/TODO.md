# Terraform Architecture Review - Deferred Tasks

## VPC & Network
- [ ] Implement VPC Flow Logs for traffic debugging and monitoring

## Security & Management
- [x] Configure SSM Session Manager for ECS task access
  - Note: SSH to private database resources still requires a bastion host or RDS Proxy with SSM
  - For now, you can access ECS tasks via: `aws ecs execute-command --cluster <cluster> --task <task-id> --container drupal --interactive --command "/bin/bash"`

## Load Balancer
- [ ] Set up ACM certificate for HTTPS (Route53 validation)
- [x] Enable ALB access logs to S3 for audit trail and debugging
- [ ] Enable deletion protection on ALB to prevent accidental deletion

## ECS & Containers
- [ ] Enforce specific Docker image tags (semantic versioning) instead of :latest for production deployments
- [ ] Change GitHub Secrets for AWS Secret Manager ARNs to GitHub Variables

## RDS Database
- [ ] Require final snapshot on database deletion for data protection (currently skip_final_snapshot = true)
- [ ] Enable auto_minor_version_upgrade for automatic security patches
- [ ] Adjust backup window (3am) and maintenance window (4am Monday) to avoid overlap
- [ ] Enable require_secure_transport = 1 for mandatory TLS database connections
- [ ] Consider read replicas for scaling read-heavy Drupal workloads

## ElastiCache Redis
- [ ] Enable Redis Replication Group (primary + replica) for Multi-AZ failover instead of single node
  - Requires switching from aws_elasticache_cluster to aws_elasticache_replication_group
  - Enables automatic failover with replicas_per_node_group = 1
  - Approximately doubles cache infrastructure cost
- [ ] Change apply_immediately to false for safer production deployments

## Monitoring & Alerting
- [ ] Configure SNS topics and email subscriptions for CloudWatch alarm notifications
  - Create SNS topic for production alerts
  - Add SNS topic ARN to alarm_actions in cloudwatch.tf
  - Current alarms created: ECS task count, ECS CPU, RDS CPU, ALB unhealthy targets, WAF blocked requests
- [ ] Set up log insights queries and dashboards for monitoring trends
- [ ] Configure long-term log archival to cheaper storage (e.g., S3 Glacier for logs older than 90 days)
