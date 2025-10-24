# IAM Role for ECS Task Execution
# Used by the ECS agent to pull images and manage task resources
# Separate from the task role which is used by the application itself
resource "aws_iam_role" "ecs_task_execution" {
  name_prefix = "${var.name_prefix}-ecs-exec-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-ecs-execution-role"
  }
}

# AWS managed policy for ECS task execution
# Includes permissions for:
# - Pulling Docker images from ECR
# - Writing container logs to CloudWatch
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task (application runtime permissions)
# Used by the Drupal application running inside the container
# This role should have minimal permissions required for the application to function
resource "aws_iam_role" "ecs_task" {
  name_prefix = "${var.name_prefix}-ecs-task-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-ecs-task-role"
  }
}

# Policy for ECS task runtime permissions
# Allows the Drupal application container to access AWS services
resource "aws_iam_role_policy" "ecs_task" {
  name_prefix = "task-"
  role        = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow SSM Session Manager for interactive access to running tasks
        # Required for: aws ecs execute-command to debug/troubleshoot container
        Effect = "Allow"
        Action = [
          "ssmmessages:AcknowledgeMessage",
          "ssmmessages:GetEndpoint",
          "ssmmessages:GetMessages",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for ECS Task Execution to support SSM
resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Policy for ECS Task Execution to access Secrets Manager
# Allows the ECS agent to retrieve secrets from AWS Secrets Manager
# and inject them into the container at runtime
# Restricted to only the 3 secrets used by this application (least privilege)
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name_prefix = "ecs-task-exec-secrets-"
  role        = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow retrieving specific secrets from Secrets Manager
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.db_password.arn,
          aws_secretsmanager_secret.redis_auth.arn,
          aws_secretsmanager_secret.drupal_salt.arn
        ]
      }
    ]
  })
}
