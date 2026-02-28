# Copilot Legacy EDW Modernisation – Lakebridge How-To

Use this guide to drive a legacy EDW migration with Lakebridge. It is organized in the same phases Lakebridge implements: **Assessment → Conversion → Reconciliation**. All commands are executed via the Databricks CLI extension `databricks labs lakebridge`.

## 0) Prerequisites & Setup
- Databricks workspace access (dev or prod) with a cluster available; Databricks CLI configured with PAT or service principal **and** a `cluster_id` on the profile (`databricks configure --configure-cluster` or `DATABRICKS_CLUSTER_ID`).
- Python 3.10.1–3.13 and Java 11+ on the machine running the CLI.
- Network to GitHub, PyPI, and Maven Central (or internal mirrors).
- Install and verify Lakebridge:
  ```bash
  databricks labs install lakebridge --profile <profile>
  databricks labs lakebridge --help
  ```
- Install transpilers (prompts for defaults/overrides): `databricks labs lakebridge install-transpile`.
- Configure reconcile dependencies/warehouse (creates defaults if permitted): `databricks labs lakebridge configure-reconcile`. If warehouse creation is blocked, set `warehouse_id` in `~/.databrickscfg`.

## 1) Assessment (Pre-migration)
Goal: inventory code and quantify migration effort/complexity.

### Profiler (source metadata & workload insights)
1. Configure connection: `databricks labs lakebridge configure-database-profiler` (select `source-tech`, supply credentials).
2. Run profiling: `databricks labs lakebridge execute-database-profiler --source-tech <synapse|...>`.
3. Outputs: profiler extract DB + summary report; optional dashboard:  
   ```bash
   databricks labs lakebridge create-profiler-dashboard \
     --extract-file <path/to/profile_output.db> \
     --source-tech <source> \
     --volume-path /Volumes/<catalog>/<schema>/profiler_runs \
     [--catalog-name <catalog>] [--schema-name <schema>]
   ```

### Analyzer (static code/metadata scan)
1. Export legacy metadata to a local folder (SQL scripts, XML/JSON exports for ETL/orchestration).
2. Run analyzer (prompts for missing args):
   ```bash
   databricks labs lakebridge analyze \
     --source-directory <folder_with_exports> \
     --report-file <path/output.xlsx> \
     --source-tech <source> \
     --generate-json true   # optional
   ```
3. Outputs: Excel report (+ JSON if requested) with complexity scoring, inventory, and dependency mapping.

Use profiler + analyzer outputs to size effort, prioritize objects, and choose transpiler/validation scope.

## 2) Conversion (Transpile)
Goal: convert SQL/ETL/orchestration to Databricks targets.

- Transpilers available: **BladeBridge** (broad SQL/ETL coverage, default), **Morpheus** (next-gen SQL/dbt), **Switch** (LLM, experimental notebooks).
- Optional: during `install-transpile`, provide a custom BladeBridge config override for your source.
- Core run (override install-time defaults as needed):
  ```bash
  databricks labs lakebridge transpile \
    --input-source <path/to/sources> \
    --output-folder <path/to/output> \
    --source-dialect <snowflake|oracle|mssql|datastage|ssis|...> \
    --target-technology <DBSQL|SparkSql|SDP|Databricks Workflow> \
    --transpiler-config-path <path/to/config.json> \
    --error-file-path <path/errors.log> \
    --skip-validation <true|false> \
    --catalog-name <catalog> --schema-name <schema>
  ```
- Source-specific guides: see `docs/lakebridge/docs/transpile/source_systems` (SSIS, Redshift, DataStage).
- Outputs: converted code in `--output-folder`, optional validation results, and error log if provided.

## 3) Reconciliation (Post-migration)
Goal: prove parity between source and Databricks.

### Configure (CLI-generated resources)
- Run once: `databricks labs lakebridge configure-reconcile` (creates metadata catalog/schema/volume and default dashboards when permitted).
- Secrets: store source creds in secret scopes (e.g., `lakebridge_snowflake`, `lakebridge_oracle`, `lakebridge_mssql`, `lakebridge_synapse`, `lakebridge_databricks`). Not required when both sides are Databricks.
- Config file naming (placed under `~/.lakebridge`):  
  `recon_config_<DATA_SOURCE>_<CATALOG_OR_SCHEMA>_<REPORT_TYPE>.json`  
  `REPORT_TYPE` ∈ {schema, row, data, all}.

### Define reconciliation scope
- ReconcileConfig (global): `data_source`, `report_type`, `secret_scope`, `database_config` (source/target catalogs & schemas), `metadata_config` (catalog/schema/volume for Lakebridge metadata).
- TableRecon (per-table): `source_name`, `target_name`, `join_columns`, `column_mapping`, `transformations`, `column_thresholds`, `table_thresholds`, `aggregates`, `jdbc_reader_options` (partitioning), `filters`.
- Supported report types:  
  - **schema** (datatype/compatibility)  
  - **row** (hash match)  
  - **data** (row+column with joins/thresholds)  
  - **all** (schema + data)

### Execute
- Notebook workflow (Spark session required):
  ```python
  from databricks.sdk import WorkspaceClient
  from databricks.labs.lakebridge import __version__
  from databricks.labs.lakebridge.reconcile.trigger_recon_service import TriggerReconService

  ws = WorkspaceClient(product="lakebridge", product_version=__version__)
  result = TriggerReconService.trigger_recon(
      ws=ws,
      spark=spark,
      table_recon=table_recon,           # TableRecon object
      reconcile_config=reconcile_config  # ReconcileConfig object
  )
  print(result.recon_id)
  ```
- Aggregated/automation path (batch many tables): create `table_configs` and `table_recon_summary` Delta tables in the Lakebridge metadata catalog/schema, then use the provided recon notebooks (`recon_wrapper_nb`, `lakebridge_recon_main`, `transformation_query_generator`).
- Outputs: recon_id, metrics tables (schema/row/data mismatches), and an AI/BI dashboard deployed during install for drill-down.

## 4) Recommended Run Order for the Agent
1. **Verify environment**: prerequisites + `databricks labs lakebridge --help`.
2. **Assessment**: run profiler (if supported source) → run analyzer → capture reports.
3. **Plan**: prioritize objects and pick transpiler + overrides.
4. **Conversion**: execute `transpile` (capture errors.log, enable validation when possible).
5. **Reconcile**: configure secrets + config file(s) → run notebook/automation → review recon dashboard with `recon_id`.
6. **Iterate**: fix conversion gaps, rerun transpile/reconcile as needed until clean.

## Quick Command Reference
- Install: `databricks labs install lakebridge --profile <profile>`
- Transpiler deps: `databricks labs lakebridge install-transpile`
- Profiler: `databricks labs lakebridge configure-database-profiler` → `execute-database-profiler --source-tech <tech>`
- Analyzer: `databricks labs lakebridge analyze --source-directory <path> --report-file <file> --source-tech <tech> [--generate-json true]`
- Transpile: `databricks labs lakebridge transpile --input-source <path> --output-folder <path> --source-dialect <dialect> ...`
- Reconcile setup: `databricks labs lakebridge configure-reconcile`
- Reconcile run (notebook): use `TriggerReconService.trigger_recon(...)` with TableRecon + ReconcileConfig
- Profiler dashboard: `databricks labs lakebridge create-profiler-dashboard --extract-file <file> --source-tech <tech> --volume-path <uc volume>`

## Guardrails & Tips
- Ensure CLI profile has rights to create warehouses/catalogs/schemas (or supply existing `warehouse_id` and metadata locations).
- For restricted networks, mirror GitHub/Maven/PyPI or whitelist endpoints before install.
- Keep `--error-file-path` when transpiling; use `--skip-validation false` to catch SQL issues early.
- Name recon config files exactly per pattern (case-sensitive) and keep them under `.lakebridge`.
- Always capture `recon_id` per run; use the installed dashboard to drill into mismatches.
