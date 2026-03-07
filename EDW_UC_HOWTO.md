# Copilot Legacy EDW Migration Runbook (Azure SQL Server Focus)

This is the **agent instruction set** for migrating **Azure SQL Server workloads** (Azure SQL DB / Managed Instance / SQL Server family, plus Synapse SQL pools where applicable) to **Databricks + Unity Catalog** using Lakebridge’s built-in migration logic.

## 1) Operating Model (Mandatory)

Run every migration wave in Lakebridge’s native order:

1. **Assessment** (`analyze`; optional `profiler` for Synapse)
2. **Conversion** (`install-transpile`, `describe-transpile`, `transpile`)
3. **Reconciliation** (`configure-reconcile`, table config, `reconcile` / `aggregates-reconcile`)

No phase skipping. If a gate fails, iterate within that phase.

---

## 2) Azure SQL Server Preconditions

Before starting:

- Databricks CLI profile is valid and includes `cluster_id`.
- Python `3.10.1`-`3.13.x`; Java `11+`.
- Lakebridge installed and available on CLI profile.
- Workspace permissions include UC usage + SQL Warehouse create/use (or preconfigured `warehouse_id`).
- Source connectivity from Databricks runtime to Azure SQL/Synapse endpoints.

Preflight:
```bash
databricks auth profiles
databricks clusters list
databricks labs lakebridge --help
```

---

## 3) Lakebridge Logic the Agent Must Enforce

### 3.1 Transpile resolution order
For transpile settings, Lakebridge resolves:
1. CLI flag values
2. Stored workspace configuration
3. Interactive prompts

Invalid input is a hard stop. Fix input source; do not auto-fallback.

### 3.2 Reconcile config contract
- Table config filename format is strict:
  `recon_config_<DATA_SOURCE>_<CATALOG_OR_SCHEMA>_<REPORT_TYPE>.json`
- Case sensitivity matters for `<CATALOG_OR_SCHEMA>`.
- Report type for table reconcile: `schema`, `row`, `data`, `all`.

### 3.3 SQL Server source identity
- Use `mssql` for SQL Server and Azure SQL reconciliation source.
- Synapse dedicated SQL pool reconcile also uses SQL Server connector semantics (`mssql` family behavior in docs); profiler is Synapse-specific.

### 3.4 Reconcile runtime semantics
- One table config entry is processed at a time, with run output keyed by `recon_id`.
- Exceptions fail reconciliation; mismatches are recorded and require remediation.
- Intermediate storage is cleaned after execution attempts.

---

## 4) Per-Wave Execution Protocol (Azure SQL Server)

### Phase A - Assess
1. Export source artifacts (T-SQL, ETL/orchestration metadata).
2. Run analyzer with SQL Server tech:
   ```bash
   databricks labs lakebridge analyze \
     --source-directory <exports_dir> \
     --report-file <out/report.xlsx> \
     --source-tech mssql \
     --generate-json true
   ```
3. Optional Synapse profiling path only:
   ```bash
   databricks labs lakebridge configure-database-profiler
   databricks labs lakebridge execute-database-profiler --source-tech synapse
   ```
4. Build prioritized migration queue from complexity + dependencies.

**Gate A:** source inventory complete and migration batches prioritized.

### Phase B - Convert
1. Install/refresh transpilers:
   ```bash
   databricks labs lakebridge install-transpile
   databricks labs lakebridge describe-transpile
   ```
2. Run conversion for SQL Server dialect:
   ```bash
   databricks labs lakebridge transpile \
     --input-source <batch_input_dir> \
     --output-folder <batch_output_dir> \
     --source-dialect mssql \
     --target-technology DBSQL \
     --error-file-path <batch_errors.log> \
     --skip-validation false \
     --catalog-name <uc_catalog> \
     --schema-name <uc_schema>
   ```
3. Resolve all conversion errors from `error-file-path` before reconcile.

**Gate B:** converted artifacts generated and validation completed/triaged.

### Phase C - Reconcile
1. Configure reconcile dependencies:
   ```bash
   databricks labs lakebridge configure-reconcile
   ```
   If auto-warehouse creation is blocked, set `warehouse_id` in `~/.databrickscfg`.

2. Configure source secret scope for SQL Server:
   - Default scope: `lakebridge_mssql`
   - Required secret keys:
     - `user`
     - `password`
     - `host`
     - `port`
     - `database`
     - `encrypt` (`true`/`false`)
     - `trustServerCertificate` (`true`/`false`)

3. Create table config in `.lakebridge`:
   `recon_config_mssql_<SOURCE_CATALOG_OR_SCHEMA>_<REPORT_TYPE>.json`

4. Reconcile mode selection:
   - `schema`: datatype compatibility
   - `row`: hash-level row parity
   - `data`: row+column mismatch analysis with `join_columns`
   - `all`: schema + data checks

5. Run reconcile and capture `recon_id` (CLI job path or notebook/API path).

6. Run aggregated parity checks if required:
   ```bash
   databricks labs lakebridge aggregates-reconcile
   ```

**Gate C:** no reconcile exceptions; mismatch scope known and actionable.

---

## 5) SQL Server-Specific Reconcile Authoring Rules

- Always provide `join_columns` for `data`/`all` when PKs exist.
- Use `column_mapping` for renamed target columns.
- In `transformations`, null handling must be explicit:
  `coalesce(<expr>, '_null_recon_')`
- Normalize datetime/timestamp comparisons to epoch/string on both sides when cross-engine precision differs.
- Use `jdbc_reader_options` for large SQL Server tables to avoid serial scans.
- Use `filters` for wave slicing (for example, date windows or tenant partitions).

---

## 6) Unity Catalog Targeting Policy

For each wave, explicitly define:

- UC validation target (`catalog.schema`) for transpile validation
- UC source-to-target table mapping (`catalog.schema.table`)
- Reconcile metadata location (`metadata_config.catalog/schema/volume`)

No wave is complete without explicit UC mappings and metadata destinations.

---

## 7) Decision Matrix

- **Proceed to next wave**: reconcile exceptions = 0; mismatches accepted or fixed.
- **Rework conversion**: structural mismatches or repeated SQL incompatibilities.
- **Escalate source issue**: conversion is clean but source data quality/key integrity blocks parity.

---

## 8) Minimal Azure SQL Server Command Set

```bash
databricks labs install lakebridge --profile <profile>
databricks labs lakebridge install-transpile
databricks labs lakebridge describe-transpile
databricks labs lakebridge analyze --source-directory <dir> --report-file <file.xlsx> --source-tech mssql --generate-json true
databricks labs lakebridge transpile --input-source <dir> --output-folder <dir> --source-dialect mssql --target-technology DBSQL --error-file-path <errors.log> --skip-validation false
databricks labs lakebridge configure-reconcile
databricks labs lakebridge reconcile
databricks labs lakebridge aggregates-reconcile
```

Use commands as primitives, but drive execution by the phase gates and Lakebridge logic above.
