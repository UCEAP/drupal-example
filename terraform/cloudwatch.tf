# CloudWatch Log Group for ECS Tasks
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = 7

  tags = {
    Name = "${var.name_prefix}-ecs-logs"
  }
}

# CloudWatch Log Group for WAF Logs
# Logs all WAF activity including blocked requests
# Note: WAF log group names must start with "aws-waf-logs-"
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${var.name_prefix}"
  retention_in_days = 30 # Extended retention for security compliance

  tags = {
    Name = "${var.name_prefix}-waf-logs"
  }
}

# CloudWatch Log Group for ALB Access Logs
# Logs all HTTP/HTTPS requests to the Application Load Balancer
resource "aws_cloudwatch_log_group" "alb" {
  name              = "/aws/alb/${var.name_prefix}"
  retention_in_days = 14

  tags = {
    Name = "${var.name_prefix}-alb-logs"
  }
}

# CloudWatch Alarm - ECS Task Count
# Alert if running task count drops below minimum
resource "aws_cloudwatch_metric_alarm" "ecs_task_count" {
  alarm_name          = "${var.name_prefix}-ecs-task-count"
  alarm_description   = "Alert when ECS running task count is below minimum"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningCount"
  namespace           = "ECS/ContainerInsights"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = var.ecs_min_capacity
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [] # Add SNS topic ARN here for notifications

  tags = {
    Name = "${var.name_prefix}-ecs-task-count-alarm"
  }
}

# CloudWatch Alarm - ECS Task CPU Utilization
# Alert if CPU utilization stays critically high
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.name_prefix}-ecs-cpu-high"
  alarm_description   = "Alert when ECS task CPU utilization is critically high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CpuUtilized"
  namespace           = "ECS/ContainerInsights"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 90 # Alert if >90% CPU
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [] # Add SNS topic ARN here for notifications

  tags = {
    Name = "${var.name_prefix}-ecs-cpu-high-alarm"
  }
}

# CloudWatch Alarm - RDS CPU Utilization
# Alert if database CPU is consistently high
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.name_prefix}-rds-cpu-high"
  alarm_description   = "Alert when RDS CPU utilization is consistently high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 80 # Alert if >80% CPU
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  alarm_actions = [] # Add SNS topic ARN here for notifications

  tags = {
    Name = "${var.name_prefix}-rds-cpu-high-alarm"
  }
}

# CloudWatch Alarm - ALB Unhealthy Target Count
# Alert if any targets become unhealthy
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  alarm_name          = "${var.name_prefix}-alb-unhealthy-targets"
  alarm_description   = "Alert when ALB has unhealthy targets"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60 # 1 minute
  statistic           = "Average"
  threshold           = 1 # Alert if any target unhealthy
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.ecs.arn_suffix
  }

  alarm_actions = [] # Add SNS topic ARN here for notifications

  tags = {
    Name = "${var.name_prefix}-alb-unhealthy-targets-alarm"
  }
}

# CloudWatch Alarm - WAF Blocked Requests
# Alert if WAF is blocking excessive requests (potential attack)
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "${var.name_prefix}-waf-blocked-requests"
  alarm_description   = "Alert when WAF blocks excessive requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 100 # Alert if >100 requests blocked in 5 min
  treat_missing_data  = "notBreaching"

  dimensions = {
    WebACL = aws_wafv2_web_acl.alb.name
    Region = var.aws_region
    Rule   = "ALL"
  }

  alarm_actions = [] # Add SNS topic ARN here for notifications

  tags = {
    Name = "${var.name_prefix}-waf-blocked-requests-alarm"
  }
}
