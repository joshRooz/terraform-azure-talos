# Usage

<!--- BEGIN_TF_DOCS --->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.5 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 2.0.1 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 2.74.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >= 2.1.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 2.0.1 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 2.74.0 |
| <a name="provider_http"></a> [http](#provider\_http) | 2.1.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_availability_set.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set) | resource |
| [azurerm_image.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/image) | resource |
| [azurerm_lb.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) | resource |
| [azurerm_lb_backend_address_pool.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_probe.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_network_interface.controlplane](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.worker](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.controlplane](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.lb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_blob.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob) | resource |
| [azurerm_storage_container.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_machine.controlplane](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine) | resource |
| [azurerm_virtual_machine.worker](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [null_resource.this](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_integer.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |
| [random_pet.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [azuread_client_config.whoami](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [http_http.tf_client](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_controlplane_admin"></a> [controlplane\_admin](#input\_controlplane\_admin) | Admin username for controlplane VMs but don't expect it to be useful. | `string` | n/a | yes |
| <a name="input_controlplane_instances"></a> [controlplane\_instances](#input\_controlplane\_instances) | Number of controlplane instances to deploy. | `number` | `3` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Project namespace to use for a unique and consistent naming convention. | `string` | `"talos"` | no |
| <a name="input_region"></a> [region](#input\_region) | Name of the Azure region to deploy resources. | `string` | `"australiasoutheast"` | no |
| <a name="input_subnet_address_spaces"></a> [subnet\_address\_spaces](#input\_subnet\_address\_spaces) | Address space for the Talos subnet. | `list(string)` | <pre>[<br>  "192.168.254.0/24"<br>]</pre> | no |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | Address space for Talos virtual network. | `string` | `"192.168.254.0/23"` | no |
| <a name="input_worker_admin"></a> [worker\_admin](#input\_worker\_admin) | Admin username for worker VMs but don't expect it to be useful. | `string` | n/a | yes |
| <a name="input_worker_instances"></a> [worker\_instances](#input\_worker\_instances) | Number of worker instances to deploy. | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_public_ip"></a> [client\_public\_ip](#output\_client\_public\_ip) | Public IP of the Terraform client used on Network Security Group rules. |
| <a name="output_controlplane_public_ips"></a> [controlplane\_public\_ips](#output\_controlplane\_public\_ips) | Public IPs for controlplan VMs. |
| <a name="output_lb_public_ip"></a> [lb\_public\_ip](#output\_lb\_public\_ip) | Public facing IP of load balancer for Talos. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name that was dynamically created. |

<!--- END_TF_DOCS --->

