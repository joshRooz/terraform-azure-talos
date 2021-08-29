output "resource_group_name" {
  description = "Resource group name that was dynamically created."
  value       = azurerm_resource_group.this.name
}

output "client_public_ip" {
  description = "Public IP of the Terraform client used on Network Security Group rules."
  value       = data.http.tf_client.body
}

output "lb_public_ip" {
  description = "Public facing IP of load balancer for Talos."
  value       = azurerm_public_ip.lb.ip_address
}

output "controlplane_public_ips" {
  description = "Public IPs for controlplan VMs."
  value       = { for k, v in azurerm_public_ip.controlplane : v.name => v.ip_address }
}