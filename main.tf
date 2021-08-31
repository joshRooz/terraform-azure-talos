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

resource "azurerm_storage_account_network_rules" "this" {
  storage_account_name = azurerm_storage_account.this.name
  resource_group_name  = azurerm_resource_group.this.name

  default_action             = "Deny"
  ip_rules                   = [data.http.tf_client.body]
  virtual_network_subnet_ids = [azurerm_subnet.this.id]
  bypass                     = ["None"]
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
    name                         = "apid"
    priority                     = 1001
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "50000"
    source_address_prefix        = data.http.tf_client.body
    destination_address_prefixes = var.subnet_address_spaces
  }

  security_rule {
    name                         = "trustd"
    priority                     = 1002
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "50001"
    source_address_prefix        = data.http.tf_client.body
    destination_address_prefixes = var.subnet_address_spaces
  }

  security_rule {
    name                         = "etcd"
    priority                     = 1003
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "2379-2380"
    source_address_prefix        = data.http.tf_client.body
    destination_address_prefixes = var.subnet_address_spaces
  }

  security_rule {
    name                         = "kube"
    priority                     = 1004
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "6443"
    source_address_prefix        = data.http.tf_client.body
    destination_address_prefixes = var.subnet_address_spaces
  }
}

resource "azurerm_virtual_network" "this" {
  name                = join("-", ["vn", random_pet.this.id, random_integer.this.id])
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_address_space]
}

resource "azurerm_subnet" "this" {
  name                 = "talos-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.subnet_address_spaces

  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_subnet_network_security_group_association" "this" {
  network_security_group_id = azurerm_network_security_group.this.id
  subnet_id                 = azurerm_subnet.this.id
}

resource "azurerm_public_ip" "lb" {
  name                = join("-", ["pip", random_pet.this.id, "lb", random_integer.this.id])
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  availability_zone   = azurerm_resource_group.this.location == "australiasoutheast" ? "No-Zone" : "Zone-Redundant"
  domain_name_label   = "pip-talos-lb"
}

resource "azurerm_lb" "this" {
  name                = join("-", ["lb", random_pet.this.id, random_integer.this.id])
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "talos-fe"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  name            = join("-", [azurerm_lb.this.name, "bepool"])
  loadbalancer_id = azurerm_lb.this.id
}

resource "azurerm_lb_backend_address_pool_address" "this" {
  for_each = toset(local.controlplane_instances)

  name                    = join("-", ["lb-bepool", azurerm_virtual_machine.controlplane[each.key].name])
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
  virtual_network_id      = azurerm_virtual_network.this.id
  ip_address              = azurerm_network_interface.controlplane[each.key].private_ip_address
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

locals {
  controlplane_instances = [
    for i in range(1, var.controlplane_instances + 1) : join("", ["0", tostring(i)])
  ]
}

resource "azurerm_public_ip" "controlplane" {
  for_each = toset(local.controlplane_instances)

  name                = join("-", ["pip", random_pet.this.id, "controlplane", random_integer.this.id, each.value])
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  domain_name_label   = join("-", ["pip", random_pet.this.id, "controlplane", random_integer.this.id, each.value])
}

resource "azurerm_network_interface" "controlplane" {
  for_each = toset(local.controlplane_instances)

  name                = join("-", ["nic", random_pet.this.id, "controlplane", random_integer.this.id, each.value])
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.controlplane[each.value].id
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
  name                        = join("-", ["as", random_pet.this.id, "controlplane", random_integer.this.id])
  location                    = azurerm_resource_group.this.location
  resource_group_name         = azurerm_resource_group.this.name
  platform_fault_domain_count = azurerm_resource_group.this.location == "australiasoutheast" ? 2 : 3
}

resource "azurerm_virtual_machine" "controlplane" {
  for_each = toset(local.controlplane_instances)

  name                          = join("-", ["vm", random_pet.this.id, "controlplane", random_integer.this.id, each.value])
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  network_interface_ids         = [azurerm_network_interface.controlplane[each.value].id]
  vm_size                       = "Standard_B1ls"
  availability_set_id           = azurerm_availability_set.this.id
  delete_os_disk_on_termination = true

  os_profile {
    computer_name  = join("-", ["vm", random_pet.this.id, "controlplane", each.value])
    admin_username = "wvwiwvbuzzzzzpzuikbpqswpz" # nil
    custom_data    = file("./controlplane.yaml")
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("./dummy.pub")
      path     = "/home/wvwiwvbuzzzzzpzuikbpqswpz/.ssh/authorized_keys"
    }
  }

  storage_image_reference {
    id = azurerm_image.this.id
  }

  storage_os_disk {
    name          = join("-", ["osdisk", random_pet.this.id, "controlplane", random_integer.this.id, each.value])
    create_option = "FromImage"
    caching       = "None"
    disk_size_gb  = 10
    os_type       = "Linux"
  }
}

locals {
  worker_instances_to_ten = [
    for i in range(1, var.worker_instances + 1) : join("", ["0", tostring(i)])
    if i < 10
  ]
  worker_instances_ten_to_hundred = [
    for i in range(1, var.worker_instances + 1) : tostring(i)
    if i >= 10
  ]
  worker_instances = concat(local.worker_instances_to_ten, local.worker_instances_ten_to_hundred)
}

resource "azurerm_network_interface" "worker" {
  for_each = toset(local.worker_instances)

  name                = join("-", ["nic", random_pet.this.id, "worker", random_integer.this.id, each.value])
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "worker" {
  for_each = toset(local.worker_instances)

  name                          = join("-", ["vm", random_pet.this.id, "worker", random_integer.this.id, each.value])
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  network_interface_ids         = [azurerm_network_interface.worker[each.value].id]
  vm_size                       = "Standard_B1ls"
  delete_os_disk_on_termination = true

  os_profile {
    computer_name  = join("-", ["vm", random_pet.this.id, "worker", each.value])
    admin_username = "zoftwedghyintpxgcwainzajq" # nil
    custom_data    = file("./join.yaml")
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("./dummy.pub")
      path     = "/home/zoftwedghyintpxgcwainzajq/.ssh/authorized_keys"
    }
  }

  storage_image_reference {
    id = azurerm_image.this.id
  }

  storage_os_disk {
    name          = join("-", ["osdisk", random_pet.this.id, "worker", random_integer.this.id, each.value])
    create_option = "FromImage"
    caching       = "None"
    disk_size_gb  = 10
    os_type       = "Linux"
  }
}