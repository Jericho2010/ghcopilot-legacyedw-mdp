# Azure SQL Sample DW Bootstrap Design

## Goal

Create a repeatable bootstrap that stands up an Azure SQL source system seeded with a Microsoft sample data warehouse so the EDW-to-Databricks migration flow in `EDW_UC_HOWTO.md` can be tested end to end.

## Design summary

The bootstrap uses an Azure SQL logical server and imports a Microsoft sample BACPAC into a new database. Terraform owns the durable infrastructure, while the actual BACPAC import is executed through Azure CLI because the supported `azurerm_mssql_database` resource still does not model BACPAC import in provider 4.x.

## Why Azure SQL Database on a logical server

- Lowest operational overhead for a disposable bootstrap source system
- Good fit for Lakebridge testing, JDBC connectivity, and reconciliation flows
- Avoids the cost and network complexity of Managed Instance when the objective is migration testing rather than feature-perfect SQL Server compatibility

## Target architecture

1. Authenticate to the target Azure tenant.
2. Provision a resource group in the selected region.
3. Provision an Azure SQL logical server with SQL authentication.
4. Create a storage account and private blob container.
5. Copy a Microsoft sample BACPAC into blob storage directly from a public source URL.
6. Run `az sql db import` using the staged BACPAC to create the sample database.
7. Store the generated SQL admin password in Key Vault for downstream consumers.

## Tenant-only input model

Required input:

- `tenant_id`

Operational assumption:

- The authenticated caller already has a valid Azure subscription context in that tenant, or passes `subscription_id` as an optional override.

This satisfies the tenant-driven experience while remaining compatible with Azure's requirement that every deployment lands in a specific subscription.

## Sample selection

The module supports:

- `AdventureWorksDW2022` (default)
- `WideWorldImportersDW`
- a custom `sample_bacpac_uri`

Why default to `AdventureWorksDW2022`:

- Closest match to the user's request
- Familiar Microsoft sample for dimensional-model testing
- Adequate for validating extraction, transpilation, reconciliation, and Unity Catalog landing patterns

## Security posture

Baseline security in this bootstrap is intentionally pragmatic:

- SQL public network access remains enabled to keep the bootstrap simple
- Azure services firewall rule is enabled because Azure SQL import/export requires Azure control plane access
- Additional firewall rules can be supplied explicitly
- SQL admin password is generated and stored in Key Vault
- TLS minimum version is pinned to 1.2

Hardening options for later:

- Replace SQL authentication with Entra admin + contained users for runtime access
- Add private endpoints for SQL and storage
- Lock storage and Key Vault behind network ACLs
- Move secrets fully out of Terraform state by injecting them from a secret manager upstream

## Operational flow

### Provision phase

Terraform creates the resource group, SQL server, Key Vault, storage account, container, and a staged blob populated from the Microsoft sample BACPAC URL.

### Seed phase

A `terraform_data` resource calls Azure CLI locally to execute `az sql db import`.

This step:

- skips work if the database already exists
- can force a re-import when `force_reimport = true`
- deletes the database on Terraform destroy so the bootstrap remains disposable

## Why not use `azurerm_mssql_database`

The current AzureRM provider supports regular database lifecycle management, but not first-class BACPAC import on `azurerm_mssql_database`. Because of that limitation, the design intentionally keeps the import as an operational step while still expressing the repeatable infrastructure declaratively.

## Fit with the EDW migration runbook

Once deployed, the stack gives you:

- an Azure SQL endpoint for Lakebridge `mssql` source analysis and reconciliation
- a stable sample warehouse schema for transpilation tests
- a known password location in Key Vault for integration with Databricks secrets or Lakebridge secret scope setup

## Recommended next steps after bootstrap

1. Validate Azure SQL connectivity from Databricks runtime.
2. Mirror the SQL connection settings into the Lakebridge `lakebridge_mssql` secret scope.
3. Export representative DDL / ETL artifacts from the sample DB for the `analyze` and `transpile` phases.
4. Use the imported sample tables as reconciliation test cases before connecting to the real legacy EDW.
