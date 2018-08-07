variable "prefix" {
  default = "daniele"
}

variable "datacenter" {
  default = "eastus"
}

variable "ARM_SUBSCRIPTION_ID" {
  description = "The Azure subscription ID"
}

variable "ARM_CLIENT_ID" {
  description = "The Azure client ID"
}

variable "ARM_CLIENT_SECRET" {
  description = "The Azure secret access key"
}

variable "ARM_TENANT_ID" {
  description = "The Azure tenant ID"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "${var.ARM_SUBSCRIPTION_ID}"
  client_id       = "${var.ARM_CLIENT_ID}"
  client_secret   = "${var.ARM_CLIENT_SECRET}"
  tenant_id       = "${var.ARM_TENANT_ID}"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "terraformgroup" {
  name     = "${var.prefix}ResourceGroupForVM"
  location = "${var.datacenter}"

  tags {
    environment = "${var.prefix} Terraform Demo"
  }
}
