# Random auth token for Redis
resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

# ElastiCache Redis Replication Group (Multi-AZ with automatic failover)
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.name_prefix}-redis"
  description                = "Redis cluster for ${var.name_prefix} with Multi-AZ failover"
  engine                     = "redis"
  engine_version             = var.redis_engine_version
  node_type                  = var.redis_node_type
  port                       = var.redis_port
  parameter_group_name       = aws_elasticache_parameter_group.redis.name
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.redis.id]

  # Multi-AZ configuration
  automatic_failover_enabled = true
  multi_az_enabled           = true
  num_cache_clusters         = 2  # 1 primary + 1 replica across AZs

  # Security
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result
  at_rest_encryption_enabled = true

  # Maintenance and backup
  maintenance_window       = "sun:05:00-sun:06:00"
  snapshot_retention_limit = 5
  snapshot_window          = "03:00-04:00"

  # Apply changes immediately (set to false for production)
  apply_immediately = true

  tags = {
    Name = "${var.name_prefix}-redis"
  }
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "redis" {
  name        = "${var.name_prefix}-redis"
  family      = "redis7"
  description = "Custom parameter group for ${var.name_prefix} Redis"

  # Enable notifications for keyspace events (useful for Drupal)
  parameter {
    name  = "notify-keyspace-events"
    value = "Ex"
  }

  # Set max memory policy to evict least recently used keys
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = {
    Name = "${var.name_prefix}-redis-params"
  }

  lifecycle {
    create_before_destroy = true
  }
}
