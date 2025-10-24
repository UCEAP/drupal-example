# AWS Secrets Manager - Database Password
resource "aws_secretsmanager_secret" "db_password" {
  name_prefix             = "${var.name_prefix}-db-password-"
  description             = "RDS MySQL admin password for ${var.name_prefix}"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.name_prefix}-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id       = aws_secretsmanager_secret.db_password.id
  secret_string   = random_password.db_password.result
  version_stages = ["AWSCURRENT"]
}

# AWS Secrets Manager - Redis Auth Token
resource "aws_secretsmanager_secret" "redis_auth" {
  name_prefix             = "${var.name_prefix}-redis-auth-"
  description             = "ElastiCache Redis auth token for ${var.name_prefix}"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.name_prefix}-redis-auth"
  }
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id       = aws_secretsmanager_secret.redis_auth.id
  secret_string   = random_password.redis_auth_token.result
  version_stages = ["AWSCURRENT"]
}

# AWS Secrets Manager - Drupal Hash Salt
resource "aws_secretsmanager_secret" "drupal_salt" {
  name_prefix             = "${var.name_prefix}-drupal-salt-"
  description             = "Drupal hash salt for ${var.name_prefix}"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.name_prefix}-drupal-salt"
  }
}

resource "aws_secretsmanager_secret_version" "drupal_salt" {
  secret_id       = aws_secretsmanager_secret.drupal_salt.id
  secret_string   = random_bytes.drupal_salt.base64
  version_stages = ["AWSCURRENT"]
}
