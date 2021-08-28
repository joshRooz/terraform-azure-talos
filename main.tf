terraform {
  required_version = ">= 1.0.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.74.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.0.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
  }
}

provider "azurerm" {
  features {}

  storage_use_azuread = true
}

provider "azuread" {}

provider "random" {}

provider "http" {}

provider "null" {}

variable "namespace" {
  description = "Project namespace to use for a unique and consistent naming convention."
  type        = string
  default     = "talos"
}

variable "region" {
  description = "Name of the Azure region to deploy resources."
  type        = string
  default     = "australiasoutheast"
}

variable "vnet_address_space" {
  description = "Address space for Talos virtual network."
  type        = string
  default     = "192.168.254.0/23"
}

variable "subnet_address_space" {
  description = "Address space for the Talos subnet."
  type        = string
  default     = "192.168.254.0/24"
}

variable "controlplane_admin" {
  description = "Admin username for controlplane VMs but don't expect it to be useful."
  type        = string
  sensitive   = true
}

variable "worker_admin" {
  description = "Admin username for worker VMs but don't expect it to be useful."
  type        = string
  sensitive   = true
}


resource "random_pet" "this" {
  length    = 1
  prefix    = var.namespace
  separator = "-"
}

resource "random_integer" "this" {
  min = 100
  max = 999
}

data "azuread_client_config" "whoami" {}

resource "azurerm_resource_group" "this" {
  name     = join("-", ["rg", random_pet.this.id, random_integer.this.id])
  location = var.region
}

resource "azurerm_role_assignment" "this" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_client_config.whoami.object_id
}

resource "azurerm_storage_account" "this" {
  name                     = join("", ["sa", replace(random_pet.this.id, "-", ""), random_integer.this.id])
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version           = "TLS1_2"
  shared_access_key_enabled = false
}


resource "azurerm_storage_container" "this" {
  name                 = "vhds"
  storage_account_name = azurerm_storage_account.this.name

  depends_on = [
    azurerm_role_assignment.this
  ]
}


resource "azurerm_storage_blob" "this" {
  name                   = "talos-amd64-v0-11-5.vhd"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.this.name
  type                   = "Page"

  source = "disk.vhd"
}

resource "azurerm_image" "this" {
  name                = "talos-amd64-v0-11-5"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = azurerm_storage_blob.this.url
  }
}

data "http" "tf_client" {
  url = "https://api.ipify.org"
}

resource "azurerm_network_security_group" "this" {
  name                = "nsg-talos-subnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "apid"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "50000"
    source_address_prefix      = data.http.tf_client.body
    destination_address_prefix = var.subnet_address_space
  }

  security_rule {
    name                       = "trustd"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "50001"
    source_address_prefix      = data.http.tf_client.body
    destination_address_prefix = var.subnet_address_space
  }


  security_rule {
    name                       = "etcd"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379-2380"
    source_address_prefix      = data.http.tf_client.body
    destination_address_prefix = var.subnet_address_space
  }

  security_rule {
    name                       = "kube"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = data.http.tf_client.body
    destination_address_prefix = var.subnet_address_space
  }
}

resource "azurerm_virtual_network" "this" {
  name                = join("-", ["vn", random_pet.this.id, random_integer.this.id])
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_address_space]

  subnet {
    name           = "talos-subnet"
    address_prefix = var.subnet_address_space
    security_group = azurerm_network_security_group.this.id
  }
}

resource "azurerm_public_ip" "lb" {
  name                = join("-", ["pip", "lb", random_pet.this.id, random_integer.this.id])
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  domain_name_label   = "pip-talos-lb"
}

resource "azurerm_lb" "this" {
  name                = join("-", ["lb", random_pet.this.id, random_integer.this.id])
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  frontend_ip_configuration {
    name                 = "talos-fe"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  name            = join("-", [azurerm_lb.this.name, "bepool"])
  loadbalancer_id = azurerm_lb.this.id
}

resource "azurerm_lb_probe" "this" {
  name                = join("-", [azurerm_lb.this.name, "probe"])
  resource_group_name = azurerm_resource_group.this.name
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = "Tcp"
  port                = 6443
}

resource "azurerm_lb_rule" "this" {
  name                           = join("-", [azurerm_lb.this.name, "rule-6443"])
  resource_group_name            = azurerm_resource_group.this.name
  loadbalancer_id                = azurerm_lb.this.id
  frontend_ip_configuration_name = azurerm_lb.this.frontend_ip_configuration[0].name
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  backend_address_pool_id        = azurerm_lb_backend_address_pool.this.id
  probe_id                       = azurerm_lb_probe.this.id
}

resource "azurerm_public_ip" "nic" {
  for_each = toset(["01", "02", "03"])

  name                = join("-", ["pip", each.value, "ctrl", random_pet.this.id, random_integer.this.id])
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  domain_name_label   = join("-", ["pip", "talos-control-plane", each.value])
}

resource "azurerm_network_interface" "this" {
  for_each = toset(["01", "02", "03"])

  name                = join("-", ["nic", "talos-control-plane", each.value])
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = element(azurerm_virtual_network.this.subnet[*].id, 0) # not ideal
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nic[each.value].id
  }
}

resource "null_resource" "this" {
  triggers = {
    lb_pip_change = azurerm_public_ip.lb.ip_address
  }

  provisioner "local-exec" {
    command     = "talosctl gen config talos-k8s-azure-tutorial https://$(terraform output lb_public_ip | sed 's|^.|| ; s|.$||'):6443"
    interpreter = ["/bin/env", "bash", "-c"]
  }
}

resource "azurerm_availability_set" "this" {
  name                        = join("-", ["as", random_pet.this.id, random_integer.this.id])
  location                    = azurerm_resource_group.this.location
  resource_group_name         = azurerm_resource_group.this.name
  platform_fault_domain_count = azurerm_resource_group.this.location == "australiasoutheast" ? 2 : 3
}

resource "azurerm_virtual_machine" "ctrl" {
  for_each = toset(["01", "02", "03"])

  name                          = join("-", ["vm", "talos-controlplane", each.value])
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  network_interface_ids         = [azurerm_network_interface.this[each.value].id]
  vm_size                       = "Standard_B1ls"
  availability_set_id           = azurerm_availability_set.this.id
  delete_os_disk_on_termination = true

  os_profile {
    computer_name  = join("-", ["vm", "talos-controlplane", each.value])
    admin_username = var.controlplane_admin
    custom_data    = file("./controlplane.yaml")
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("./dummy.pub")
      path     = "/home/${var.controlplane_admin}/.ssh/authorized_keys"
    }
  }

  storage_image_reference {
    id = azurerm_image.this.id
  }

  storage_os_disk {
    name          = join("-", ["osdisk", "talos-controlplane", each.value])
    create_option = "FromImage"
    caching       = "None"
    disk_size_gb  = 10
    os_type       = "Linux"
  }
}

#--------------
# Outputs
#--------------
output "resource_group_name" {
  description = "Resource group name that was dynamically created."
  value       = azurerm_resource_group.this.name
}

output "client_public_ip" {
  description = "Public IP of the Terraform client."
  value       = data.http.tf_client.body
}

output "lb_public_ip" {
  description = "Public facing IP of load balancer for Talos."
  value       = azurerm_public_ip.lb.ip_address
}

output "controlplane_public_ips" {
  description = "Public IPs for controlplan VMs."
  value       = { for k, v in azurerm_public_ip.nic : v.name => v.ip_address }
}