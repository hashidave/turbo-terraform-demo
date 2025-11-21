terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
    turbonomic = {
      source  = "IBM/turbonomic"
      version = "1.2.0"
    }
  }
  cloud {
    organization = "ATT"
    hostname     = "36309-eastus2-nprd-tfe-kube-internal-lb-pls.azprv.3pc.att.com"

    workspaces {
      tags = ["turbo-test"]
    }
  }


}

provider "azurerm" {
  features {}
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id
}

provider "turbonomic" {
  username   = var.turbonomic_username
  password   = var.turbonomic_password
  hostname   = var.turbonomic_hostname
  skipverify = var.turbonomic_skipverify
}

locals {
  vm_name = "${var.prefix}-vm"
}

data "azurerm_resource_group" "example" {
  name     = var.azure_resource_group_name
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

data "turbonomic_cloud_entity_recommendation" "vm_recommendation" {
  entity_name = local.vm_name
  entity_type = "VirtualMachine"
  default_size = "defaultSize"
}

resource "azurerm_virtual_machine" "main" {
  name                  = local.vm_name
  location              = data.azurerm_resource_group.example.location
  resource_group_name   = data.azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = (
    data.turbonomic_cloud_entity_recommendation.vm_recommendation.new_instance_type != "defaultsize"
    ? data.turbonomic_cloud_entity_recommendation.vm_recommendation.new_instance_type
    : "Standard_D2s_v3"
  )

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}
