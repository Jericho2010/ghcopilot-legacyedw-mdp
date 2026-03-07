output "resource_group_name" {
  description = "Bootstrap resource group name."
  value       = azurerm_resource_group.this.name
}

output "sql_server_name" {
  description = "Azure SQL logical server name."
  value       = azurerm_mssql_server.this.name
}

output "sql_server_fqdn" {
  description = "Azure SQL logical server FQDN."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "database_name" {
  description = "Name of the imported sample database."
  value       = var.database_name
}

output "sample_bacpac_blob_url" {
  description = "Blob URL used as the sample import source."
  value       = azurerm_storage_blob.sample.url
}

output "key_vault_uri" {
  description = "Key Vault URI that stores bootstrap secrets."
  value       = azurerm_key_vault.this.vault_uri
}

output "sql_admin_password_secret_name" {
  description = "Key Vault secret name for the SQL admin password."
  value       = azurerm_key_vault_secret.sql_admin_password.name
}

output "import_execution_note" {
  description = "Describes the sample import orchestration pattern."
  value       = var.run_sample_import ? "Database import is executed by Azure CLI through terraform_data because azurerm_mssql_database does not model BACPAC import in azurerm 4.x." : "Sample import disabled; infrastructure and staged BACPAC only."
}
