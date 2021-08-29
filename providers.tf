provider "azurerm" {
  features {}

  storage_use_azuread = true
}

provider "azuread" {}

provider "random" {}

provider "http" {}

provider "null" {}