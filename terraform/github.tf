# GitHub Actions Secrets
# GitHub Actions Secrets - Secrets Manager ARNs (not plaintext values)
resource "github_actions_secret" "db_password_secret_arn" {
  repository      = var.github_repo
  secret_name     = "AWS_MYSQL_PASSWORD_SECRET_ARN"
  plaintext_value = aws_secretsmanager_secret.db_password.arn
}

resource "github_actions_secret" "redis_auth_secret_arn" {
  repository      = var.github_repo
  secret_name     = "AWS_REDIS_AUTH_SECRET_ARN"
  plaintext_value = aws_secretsmanager_secret.redis_auth.arn
}

resource "github_actions_secret" "drupal_salt_secret_arn" {
  repository      = var.github_repo
  secret_name     = "AWS_HASH_SALT_SECRET_ARN"
  plaintext_value = aws_secretsmanager_secret.drupal_salt.arn
}

# GitHub Actions Variables
resource "github_actions_variable" "db_host" {
  repository    = var.github_repo
  variable_name = "AWS_MYSQL_HOST"
  value         = aws_db_instance.main.address
}

resource "github_actions_variable" "db_port" {
  repository    = var.github_repo
  variable_name = "AWS_MYSQL_TCP_PORT"
  value         = tostring(var.db_port)
}

resource "github_actions_variable" "db_user" {
  repository    = var.github_repo
  variable_name = "AWS_MYSQL_USER"
  value         = var.db_username
}

resource "github_actions_variable" "db_name" {
  repository    = var.github_repo
  variable_name = "AWS_MYSQL_DATABASE"
  value         = var.db_name
}

resource "github_actions_variable" "redis_host" {
  repository    = var.github_repo
  variable_name = "AWS_REDIS_HOST"
  value         = aws_elasticache_cluster.redis.cache_nodes[0].address
}

resource "github_actions_variable" "redis_port" {
  repository    = var.github_repo
  variable_name = "AWS_REDIS_PORT"
  value         = tostring(var.redis_port)
}

resource "github_actions_variable" "ecs_cluster" {
  repository    = var.github_repo
  variable_name = "AWS_ECS_CLUSTER"
  value         = aws_ecs_cluster.main.name
}

resource "github_actions_variable" "ecs_service" {
  repository    = var.github_repo
  variable_name = "AWS_ECS_SERVICE"
  value         = aws_ecs_service.app.name
}

resource "github_actions_variable" "ecs_task_definition" {
  repository    = var.github_repo
  variable_name = "AWS_ECS_TASK_DEFINITION"
  value         = aws_ecs_task_definition.app.family
}

resource "github_actions_variable" "aws_region" {
  repository    = var.github_repo
  variable_name = "AWS_REGION"
  value         = var.aws_region
}

# ECR Variables for pushing images
resource "github_actions_variable" "ecr_repository_url" {
  repository    = var.github_repo
  variable_name = "ECR_REPOSITORY_URL"
  value         = aws_ecr_repository.drupal.repository_url
}

resource "github_actions_variable" "ecr_repository_name" {
  repository    = var.github_repo
  variable_name = "ECR_REPOSITORY_NAME"
  value         = aws_ecr_repository.drupal.name
}

resource "github_actions_variable" "aws_account_id" {
  repository    = var.github_repo
  variable_name = "AWS_ACCOUNT_ID"
  value         = var.aws_account_id
}
