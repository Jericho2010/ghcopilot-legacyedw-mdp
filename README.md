# ghcopilot-legacyedw-mdp

This repository captures guidance and bootstrap assets for migrating a legacy EDW into Databricks with Unity Catalog.

## Repository contents

- `EDW_UC_HOWTO.md` - the migration runbook and operating guidance for Azure SQL Server-family sources.
- `Bootstrap_DW/` - Terraform scaffolding and design docs for provisioning an Azure SQL sample data warehouse in the same repository.

## Bootstrap_DW

`Bootstrap_DW/` is a normal subdirectory of this repository, not a separate Git repository or submodule.

It contains:

- `DESIGN.md` - the bootstrap architecture and decision record
- `README.md` - usage guidance for the bootstrap stack
- `TERRAFORM_MCP_SERVER_INSTRUCTIONS.md` - Terraform MCP lookup guidance
- `modules/sql_bootstrap/` - the reusable Terraform module used by the root stack

## Intended workflow

1. Review `EDW_UC_HOWTO.md` for the migration process and Lakebridge expectations.
2. Use `Bootstrap_DW/` to provision a disposable Azure SQL sample source system.
3. Connect Databricks and Lakebridge to that source to validate analysis, transpilation, and reconciliation before targeting the real legacy EDW.
