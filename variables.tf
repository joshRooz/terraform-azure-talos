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

variable "subnet_address_spaces" {
  description = "Address space for the Talos subnet."
  type        = list(string)
  default     = ["192.168.254.0/24"]
}

variable "controlplane_instances" {
  description = "Number of controlplane instances to deploy."
  type        = number
  default     = 3

  validation {
    condition     = contains([1, 3, 5], tonumber(var.controlplane_instances))
    error_message = "The number of instances must be 1, 3, or 5."
  }
}

variable "worker_instances" {
  description = "Number of worker instances to deploy."
  type        = number
  default     = 1

  validation {
    condition     = try(tonumber(var.worker_instances) > 0 && tonumber(var.worker_instances) < 99)
    error_message = "The number of instances must be between 1 and 99."
  }
}
