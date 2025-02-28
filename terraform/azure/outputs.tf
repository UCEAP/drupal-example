output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "service_plan_name" {
  value = azurerm_service_plan.sp.name
}

output "app_service_name" {
  value = azurerm_linux_web_app.wa.name
}