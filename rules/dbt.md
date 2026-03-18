---
paths:
  - "**/models/**/*.sql"
  - "**/macros/**/*.sql"
  - "**/*.yml"
  - "**/dbt_project.yml"
  - "**/profiles.yml"
---

# dbt Conventions

- Use `ref()` for model references, `source()` for raw data sources. Never hardcode table names.
- Organize models in layers: `staging/` -> `intermediate/` -> `marts/`.
- Staging models: one per source table, rename columns, cast types, no joins.
- Use CTEs for readability — avoid deeply nested subqueries.
- Add `schema.yml` with descriptions and tests for every model.
- Use dbt built-in tests (`not_null`, `unique`, `accepted_values`, `relationships`) at minimum.
- Materialization: `view` for staging, `table` or `incremental` for marts.
- Incremental models must have an `is_incremental()` block and be idempotent.
- Use `{{ config(...) }}` at the top of each model file.
- Snowflake-specific: use `QUALIFY` for deduplication, `LATERAL FLATTEN` for arrays.
