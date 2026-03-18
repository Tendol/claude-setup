---
paths:
  - "**/migrations/**"
  - "**/alembic/**"
  - "**/*migration*"
  - "**/*.sql"
---

# Database & Migration Conventions

## Migrations
- Every migration MUST be reversible. Include both `upgrade()` and `downgrade()`.
- Never drop columns or tables without a deprecation period — rename first, remove later.
- Add indexes concurrently where supported: `CREATE INDEX CONCURRENTLY`.
- Test migrations against a real database, not mocks.
- Data migrations belong in separate migration files from schema migrations.
- Always verify the downgrade path works before merging.

## PostgreSQL
- Use parameterized queries — never string interpolation for SQL.
- Use appropriate column types (e.g., `timestamptz` not `timestamp`, `uuid` for IDs).
- Add `NOT NULL` constraints by default unless nullable is intentional.
- Use transactions for multi-statement operations.
- Add indexes for foreign keys and frequently queried columns.
