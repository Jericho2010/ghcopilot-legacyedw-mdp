provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
