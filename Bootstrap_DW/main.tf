module "sql_bootstrap" {
  source = "./modules/sql_bootstrap"

  tenant_id                     = var.tenant_id
  project_name                  = var.project_name
  location                      = var.location
  sql_admin_login               = var.sql_admin_login
  sql_admin_password            = var.sql_admin_password
  database_name                 = var.database_name
  sample_dataset                = var.sample_dataset
  sample_bacpac_uri             = var.sample_bacpac_uri
  run_sample_import             = var.run_sample_import
  force_reimport                = var.force_reimport
  import_edition                = var.import_edition
  import_service_objective_name = var.import_service_objective_name
  import_max_size_gb            = var.import_max_size_gb
  allow_azure_services          = var.allow_azure_services
  extra_firewall_rules          = var.extra_firewall_rules
  tags                          = local.tags
}
