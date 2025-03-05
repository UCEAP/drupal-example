output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "redis_cache_name" {
  value = azurerm_redis_cache.rc.name
}

output "database_name" {
  value = azurerm_mysql_flexible_server.db.name
}

output "service_plan_name" {
  value = azurerm_service_plan.sp.name
}

output "app_service_name" {
  value = azurerm_linux_web_app.wa.name
}
