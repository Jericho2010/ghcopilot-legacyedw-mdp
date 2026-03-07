# Bootstrap_DW

This directory contains a reference design and Terraform scaffolding to bootstrap an Azure SQL sample data warehouse that can act as the legacy EDW source for Databricks + Unity Catalog migration testing.

## What this provisions

- An Azure resource group
- An Azure SQL logical server
- Firewall access for Azure services plus optional extra rules
- A storage account/container/blob that stages a Microsoft sample BACPAC
- A Key Vault secret containing the generated SQL admin password
- An automated `az sql db import` step to create the sample database

## Why the import is handled this way

`azurerm_mssql_database` in the current `azurerm` 4.x provider does not support first-class BACPAC import, so the pattern here is:

1. Provision the infrastructure with Terraform
2. Stage the BACPAC in Azure Blob Storage with Terraform
3. Run the Azure CLI import as a controlled `terraform_data` step

That keeps the bootstrap automated while staying on supported provider resources.

## Inputs

The only required Terraform variable is `tenant_id`.

In practice, you also need one of the following preconditions so Azure knows which subscription to deploy into:

- `az login --tenant <tenant_id>` followed by `az account set --subscription <subscription-id>`
- or `ARM_SUBSCRIPTION_ID` / `TF_VAR_subscription_id`

## Quick start

```bash
cd Bootstrap_DW
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set tenant_id
terraform init
terraform plan
terraform apply
```

## Defaults

- Sample dataset: `AdventureWorksDW2022`
- Import SKU: `Standard / S3`
- Network model: public endpoint enabled, Azure services allowed, optional extra firewall rules

## Outputs

After apply, you get the SQL server FQDN, database name, Key Vault URI, and the secret name storing the SQL admin password.

## Files

- `DESIGN.md` - architecture and decision record
- `TERRAFORM_MCP_SERVER_INSTRUCTIONS.md` - how to inspect/update this stack with the Terraform MCP server
- `modules/sql_bootstrap` - reusable Terraform module
