output "resource_group_name" {
  description = "Bootstrap resource group name."
  value       = module.sql_bootstrap.resource_group_name
}

output "sql_server_name" {
  description = "Azure SQL logical server name."
  value       = module.sql_bootstrap.sql_server_name
}

output "sql_server_fqdn" {
  description = "Azure SQL logical server FQDN."
  value       = module.sql_bootstrap.sql_server_fqdn
}

output "database_name" {
  description = "Imported sample database name."
  value       = module.sql_bootstrap.database_name
}

output "sample_bacpac_blob_url" {
  description = "Blob URL used as the import source."
  value       = module.sql_bootstrap.sample_bacpac_blob_url
}

output "key_vault_uri" {
  description = "Key Vault URI containing the SQL admin password secret."
  value       = module.sql_bootstrap.key_vault_uri
}

output "sql_admin_password_secret_name" {
  description = "Key Vault secret name that stores the SQL admin password."
  value       = module.sql_bootstrap.sql_admin_password_secret_name
}

output "import_execution_note" {
  description = "Explains how the sample import is orchestrated."
  value       = module.sql_bootstrap.import_execution_note
}
