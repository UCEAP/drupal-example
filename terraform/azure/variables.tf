variable "name_prefix" {
  type        = string
  default     = "drupal-example"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_location" {
  type        = string
  default     = "eastus2"
  description = "Location of the resource group."
}

variable "app_service_plan_sku" {
  type        = string
  default     = "B1"
  description = "The SKU of the Service Plan."
}
