# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# RDS MySQL Instance
resource "aws_db_instance" "main" {
  identifier     = "${var.name_prefix}-mysql"
  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  max_allocated_storage = 100 # Enable storage autoscaling

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Multi-AZ deployment for high availability
  multi_az = true

  # Backup configuration
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # Disable automated minor version upgrades
  auto_minor_version_upgrade = false

  # Enable deletion protection for production
  deletion_protection = false

  # Skip final snapshot for non-production (set to false for production)
  skip_final_snapshot = true

  # Enable enhanced monitoring (optional)
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  # Parameter group for MySQL configuration
  parameter_group_name = aws_db_parameter_group.main.name

  tags = {
    Name = "${var.name_prefix}-mysql"
  }
}

# DB Parameter Group for MySQL configuration
resource "aws_db_parameter_group" "main" {
  name_prefix = "${var.name_prefix}-mysql-"
  family      = "mysql8.0"
  description = "Custom parameter group for ${var.name_prefix}"

  # TLS/SSL not required (matching your Azure setup)
  # To enable TLS, change this to ON and configure Drupal with SSL
  parameter {
    name  = "require_secure_transport"
    value = "0"
  }

  # Recommended performance parameters
  parameter {
    name  = "max_connections"
    value = "100"
  }

  tags = {
    Name = "${var.name_prefix}-mysql-params"
  }

  lifecycle {
    create_before_destroy = true
  }
}
