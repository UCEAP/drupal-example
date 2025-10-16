variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources (e.g. us-west-2)"
  type        = string
  default     = "us-west-2"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "drupal-example"
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

# Network Configuration
variable "app_number" {
  description = "App CIDR octet (10.{app_number}.0.0/16). Range: 101-254"
  type        = number
  default     = 101
  validation {
    condition     = var.app_number >= 101 && var.app_number <= 254
    error_message = "app_number must be between 101 and 254."
  }
}

# ECS Configuration
variable "ecs_task_cpu" {
  description = "CPU units for ECS task (256 = 0.25 vCPU, 512 = 0.5 vCPU, 1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 2048
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 3
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

# RDS Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "drupal"
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "madmin"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

# ElastiCache Configuration
variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

# GitHub Configuration
variable "github_owner" {
  description = "GitHub organization or user"
  type        = string
  default     = "UCEAP"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "drupal-example"
}
