# Terraform MCP Server Instructions

Use these MCP lookups if you want to refresh or extend the Terraform code in this directory.

## Provider versions used when authoring this stack

- `hashicorp/azurerm` `~> 4.63`
- `hashicorp/random` `~> 3.8`

## Key provider resources consulted

- `azurerm_mssql_server`
- `azurerm_storage_account`
- `azurerm_storage_blob`
- `azurerm_key_vault`
- `azurerm_role_assignment` (reviewed as an RBAC alternative)

## Suggested MCP workflow

1. Get the latest provider versions.
2. Inspect `azurerm_mssql_server` and `azurerm_storage_blob` resource docs.
3. Confirm whether `azurerm_mssql_database` has gained BACPAC import support.
4. If it has not, keep the Azure CLI import orchestration pattern.
5. If it has, replace the `terraform_data` import orchestration with the native database resource.

## Example MCP prompts

- "Get latest `azurerm` and `random` provider versions."
- "Show the resource docs for `azurerm_mssql_server`."
- "Show the resource docs for `azurerm_storage_blob`."
- "Confirm whether `azurerm_mssql_database` supports BACPAC import in the current provider version."

## Apply workflow

The Terraform MCP server in this environment is documentation-focused, so use the regular Terraform CLI to apply the stack:

```bash
cd Bootstrap_DW
terraform init
terraform plan
terraform apply
```
