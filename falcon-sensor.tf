# Azure Provider configuration
provider "azurerm" {
  features {}
  subscription_id = "<ADD AZURE SUBSCRIPTION ID>"
  tenant_id       = "<ADD AZURE TENANT ID>"
  client_id       = "<ADD AZURE APPLICATION ID>"
  client_secret   = "<ADD AZURE API SECRET"
}

# Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "vm_name" {
  description = "Name of the Linux VM"
  type        = string
}

variable "falcon_client_id" {
  description = "CrowdStrike Falcon API Client ID"
  type        = string
  sensitive   = true
}

variable "falcon_client_secret" {
  description = "CrowdStrike Falcon API Client Secret"
  type        = string
  sensitive   = true
}

# Reference the existing VM
data "azurerm_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
}

# Create the VM extension for Falcon sensor installation
resource "azurerm_virtual_machine_extension" "falcon_install_linux" {
  name                       = "CSFalconLinuxInstall"
  virtual_machine_id         = data.azurerm_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    fileUris = [
      "https://raw.githubusercontent.com/CrowdStrike/falcon-scripts/main/bash/install/falcon-linux-install.sh"
    ]
  })

  protected_settings = jsonencode({
    commandToExecute = "bash -c \"wget -q https://raw.githubusercontent.com/CrowdStrike/falcon-scripts/main/bash/install/falcon-linux-install.sh && chmod +x falcon-l
inux-install.sh && FALCON_CLIENT_ID='${var.falcon_client_id}' FALCON_CLIENT_SECRET='${var.falcon_client_secret}' ./falcon-linux-install.sh\""
  })

  tags = {
    environment = "production"
    purpose     = "falcon-installation"
  }

  timeouts {
    create = "45m"
    delete = "15m"
  }
}
