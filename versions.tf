terraform {
  required_version = ">= 1.0.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.74.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
  }
}