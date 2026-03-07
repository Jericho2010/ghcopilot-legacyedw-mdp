data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

resource "random_password" "sql_admin" {
  count = var.sql_admin_password == null ? 1 : 0

  length           = 24
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 2
  override_special = "!@#%^*-_"
}

locals {
  project_slug_raw     = replace(lower(var.project_name), "/[^0-9a-z-]/", "-")
  project_slug_trimmed = trim(local.project_slug_raw, "-")
  project_slug         = local.project_slug_trimmed != "" ? local.project_slug_trimmed : "legacyedw"
  project_compact_raw  = replace(local.project_slug, "/[^0-9a-z]/", "")
  project_compact      = substr(local.project_compact_raw != "" ? local.project_compact_raw : "legacyedw", 0, 12)

  suffix = random_string.suffix.result

  resource_group_name  = substr("${local.project_slug}-bootstrap-rg", 0, 90)
  sql_server_name      = substr("${local.project_compact}sql${local.suffix}", 0, 63)
  storage_account_name = substr("${local.project_compact}stg${local.suffix}", 0, 24)
  key_vault_name       = substr("${local.project_compact}kv${local.suffix}", 0, 24)

  sql_admin_password = coalesce(var.sql_admin_password, try(random_password.sql_admin[0].result, null))

  sample_catalog = {
    AdventureWorksDW2022 = "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksDW2022.bacpac"
    WideWorldImportersDW = "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImportersDW-Standard.bacpac"
  }

  sample_bacpac_uri = coalesce(var.sample_bacpac_uri, local.sample_catalog[var.sample_dataset])
  sample_blob_name  = "${var.sample_dataset}.bacpac"
  import_max_size   = format("%dGB", var.import_max_size_gb)
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_key_vault" "this" {
  name                            = local.key_vault_name
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  tenant_id                       = var.tenant_id
  sku_name                        = "standard"
  enabled_for_template_deployment = true
  purge_protection_enabled        = false
  soft_delete_retention_days      = 7
  public_network_access_enabled   = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover",
      "Restore",
    ]
  }

  tags = var.tags
}

resource "azurerm_mssql_server" "this" {
  name                                    = local.sql_server_name
  resource_group_name                     = azurerm_resource_group.this.name
  location                                = azurerm_resource_group.this.location
  version                                 = "12.0"
  administrator_login                     = var.sql_admin_login
  administrator_login_password_wo         = local.sql_admin_password
  administrator_login_password_wo_version = 1
  minimum_tls_version                     = "1.2"
  public_network_access_enabled           = true
  connection_policy                       = "Default"

  tags = var.tags
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  count = var.allow_azure_services ? 1 : 0

  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "extra" {
  for_each = {
    for rule in var.extra_firewall_rules : rule.name => rule
  }

  name             = each.value.name
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}

resource "azurerm_storage_account" "this" {
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_storage_container" "sample" {
  name                  = "sample-bacpac"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "sample" {
  name                   = local.sample_blob_name
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.sample.name
  type                   = "Block"
  source_uri             = local.sample_bacpac_uri
  access_tier            = "Hot"
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = local.sql_admin_password
  key_vault_id = azurerm_key_vault.this.id

  tags = var.tags
}

resource "terraform_data" "sample_import" {
  count = var.run_sample_import ? 1 : 0

  input = {
    resource_group_name  = azurerm_resource_group.this.name
    location             = azurerm_resource_group.this.location
    sql_server_name      = azurerm_mssql_server.this.name
    database_name        = var.database_name
    sql_admin_login      = var.sql_admin_login
    sql_admin_password   = local.sql_admin_password
    storage_uri          = azurerm_storage_blob.sample.url
    storage_key          = azurerm_storage_account.this.primary_access_key
    sample_bacpac_uri    = local.sample_bacpac_uri
    db_edition           = var.import_edition
    db_service_objective = var.import_service_objective_name
    db_max_size          = local.import_max_size
    force_reimport       = tostring(var.force_reimport)
  }

  triggers_replace = [
    azurerm_mssql_server.this.id,
    azurerm_storage_blob.sample.id,
    var.database_name,
    tostring(var.force_reimport),
    var.import_edition,
    var.import_service_objective_name,
    local.import_max_size,
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = file("${path.module}/scripts/import_bacpac.sh.tftpl")

    environment = {
      OPERATION            = "create"
      RESOURCE_GROUP_NAME  = self.input.resource_group_name
      LOCATION             = self.input.location
      SQL_SERVER_NAME      = self.input.sql_server_name
      DATABASE_NAME        = self.input.database_name
      SQL_ADMIN_LOGIN      = self.input.sql_admin_login
      SQL_ADMIN_PASSWORD   = self.input.sql_admin_password
      STORAGE_URI          = self.input.storage_uri
      STORAGE_KEY          = self.input.storage_key
      SAMPLE_BACPAC_URI    = self.input.sample_bacpac_uri
      DB_EDITION           = self.input.db_edition
      DB_SERVICE_OBJECTIVE = self.input.db_service_objective
      DB_MAX_SIZE          = self.input.db_max_size
      FORCE_REIMPORT       = self.input.force_reimport
    }
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = file("${path.module}/scripts/import_bacpac.sh.tftpl")

    environment = {
      OPERATION           = "destroy"
      RESOURCE_GROUP_NAME = self.input.resource_group_name
      SQL_SERVER_NAME     = self.input.sql_server_name
      DATABASE_NAME       = self.input.database_name
    }
  }

  depends_on = [
    azurerm_mssql_firewall_rule.allow_azure_services,
    azurerm_mssql_firewall_rule.extra,
    azurerm_key_vault_secret.sql_admin_password,
    azurerm_storage_blob.sample,
  ]
}
