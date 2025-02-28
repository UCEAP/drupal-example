resource "random_pet" "resource_group_name" {
  prefix = var.name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.resource_group_name.id
}

resource "random_pet" "service_plan_name" {
  prefix = var.name_prefix
}

resource "azurerm_service_plan" "sp" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = random_pet.service_plan_name.id
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku
}

resource "random_pet" "web_app_name" {
  prefix = var.name_prefix
}

resource "azurerm_linux_web_app" "wa" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.sp.id
  name                = random_pet.web_app_name.id
  site_config {}
}