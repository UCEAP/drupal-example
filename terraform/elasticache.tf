# Random auth token for Redis
resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.name_prefix}-redis"
  engine               = "redis"
  engine_version       = var.redis_engine_version
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]
  port                 = var.redis_port

  transit_encryption_enabled = true

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
