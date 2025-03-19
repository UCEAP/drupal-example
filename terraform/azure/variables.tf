variable "name_prefix" {
  type        = string
  default     = "drupal-example"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resourcegroup_location" {
  type        = string
  default     = "eastus2"
  description = "Location of the resource group."
}

variable "serviceplan_sku" {
  type        = string
  default     = "B1"
  description = "The SKU of the Service Plan."
}

variable "rediscache_sku" {
  type        = string
  default     = "Basic"
  description = "The SKU of the Redis Cache."
}

variable "rediscache_family" {
  type        = string
  default     = "C"
  description = "The family of the Redis Cache."
}

variable "rediscache_capacity" {
  type        = number
  default     = 0
  description = "The capacity of the Redis Cache."
}

variable "mysql_sku" {
  type        = string
  default     = "B_Standard_B1ms"
  description = "The SKU of the MySQL Flexible Server."
}

variable "db_port" {
  type        = number
  default     = 3306
  description = "The port of the MySQL Flexible Server."
}

variable "db_name" {
  type        = string
  default     = "drupal"
  description = "The name of the MySQL database."
}

variable "dbadmin_login" {
  type        = string
  default     = "madmin"
  description = "The administrator login of the MySQL Flexible Server."
}

variable "docker_image" {
  type        = string
  default     = "uceap/drupal-example:latest"
  description = "The Docker image name for the Web App."
}

variable "docker_registry" {
  type        = string
  default     = "https://ghcr.io"
  description = "The Docker registry URL for the Web App."
}

variable "github_repo" {
  type        = string
  default     = "drupal-example"
  description = "The GitHub repository for the Web App."
}

variable "github_username" {
  type        = string
  default     = "uceap-bot"
  description = "The GitHub username for the Docker registry."
}

variable "github_token" {
  type        = string
  description = "The GitHub token for the Docker registry."
}