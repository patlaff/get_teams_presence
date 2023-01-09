terraform {

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.35.0"
    }
  }

  backend "azurerm" {}

  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {
    # key_vault {
    #   recover_soft_deleted_key_vaults = false
    #   purge_soft_delete_on_destroy = false
    #   purge_soft_deleted_secrets_on_destroy = false
    # }
  }

}