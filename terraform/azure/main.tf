resource "random_pet" "resourcegroup_name" {
  prefix = var.name_prefix
}

resource "random_pet" "rediscache_name" {
  prefix = var.name_prefix
}

resource "random_pet" "database_name" {
  prefix = var.name_prefix
}

resource "random_pet" "serviceplan_name" {
  prefix = var.name_prefix
}

resource "random_pet" "webapp_name" {
  prefix = var.name_prefix
}

resource "random_password" "dbadmin_password" {
  length = 16
}

resource "random_bytes" "drupal_salt" {
  length = 55
}

resource "azurerm_resource_group" "rg" {
  location = var.resourcegroup_location
  name     = random_pet.resourcegroup_name.id
}

resource "azurerm_redis_cache" "rc" {
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = random_pet.rediscache_name.id
  sku_name            = var.rediscache_sku
  family              = var.rediscache_family
  capacity            = var.rediscache_capacity
}

resource "azurerm_mysql_flexible_server" "db" {
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  name                   = random_pet.database_name.id
  sku_name               = var.mysql_sku
  zone                   = 3 # apparently terraform can't handle automatically-assigned zones
  administrator_login    = var.dbadmin_login
  administrator_password = random_password.dbadmin_password.result
}

resource "azurerm_service_plan" "sp" {
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = random_pet.serviceplan_name.id
  os_type             = "Linux"
  sku_name            = var.serviceplan_sku
}

resource "azurerm_linux_web_app" "wa" {
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.sp.id
  name                = random_pet.webapp_name.id
  site_config {
    application_stack {
      docker_image_name        = var.docker_image
      docker_registry_url      = var.docker_registry
      docker_registry_username = var.github_username
      docker_registry_password = var.github_token
    }
  }
}

resource "github_actions_secret" "salt" {
  repository    = var.github_repo
  secret_name     = "AZURE_HASH_SALT"
  plaintext_value = random_bytes.drupal_salt.base64
}

resource "github_actions_variable" "dbhost" {
  repository    = var.github_repo
  variable_name = "AZURE_MYSQL_HOST"
  value         = azurerm_mysql_flexible_server.db.fqdn
}

resource "github_actions_variable" "dbport" {
  repository    = var.github_repo
  variable_name = "AZURE_MYSQL_TCP_PORT"
  value         = var.db_port
}

resource "github_actions_variable" "dbuser" {
  repository    = var.github_repo
  variable_name = "AZURE_MYSQL_USER"
  value         = var.dbadmin_login
}

resource "github_actions_secret" "dbpass" {
  repository      = var.github_repo
  secret_name     = "AZURE_MYSQL_PASSWORD"
  plaintext_value = azurerm_mysql_flexible_server.db.administrator_password
}

resource "github_actions_variable" "dbname" {
  repository    = var.github_repo
  variable_name = "AZURE_MYSQL_DATABASE"
  value         = var.db_name
}

resource "github_actions_variable" "redishost" {
  repository    = var.github_repo
  variable_name = "AZURE_REDIS_HOST"
  value         = azurerm_redis_cache.rc.hostname
}

resource "github_actions_secret" "redisauth" {
  repository      = var.github_repo
  secret_name     = "AZURE_REDIS_AUTH"
  plaintext_value = azurerm_redis_cache.rc.primary_access_key
}

resource "github_actions_variable" "webappname" {
  repository    = var.github_repo
  variable_name = "AZURE_WEBAPP_NAME"
  value         = azurerm_linux_web_app.wa.name
}