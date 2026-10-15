---
name: workers-d1
description: Manage Cloudflare D1 SQLite databases — schema, migrations, queries, and bindings from Workers
version: 0.1.0
execution-mode: advisory
argument-hint: "[--db <name>] [--action schema|migrate|query|backup]"
category: backend-infra
status: candidate
---
# workers-d1 | Cloudflare D1 SQLite Database Management

## When to Use
- Provisioning a D1 database for a Cloudflare Worker
- Applying schema migrations at the edge
- Inspecting or querying a D1 database without external tooling
- Creating backups before destructive migrations

## Execution

### 1. Parse Arguments
- `--db <name>`: D1 database name (required for all actions)
- `--action schema|migrate|query|backup`: operation to perform
- If no action given, list databases via `wrangler d1 list`

### 2. schema — Inspect or Generate Schema
- Run `npx wrangler d1 execute <db> --command ".schema"`
- Parse table definitions, indexes, and foreign keys
- If generating, produce SQL DDL from a model description

### 3. migrate — Apply Migrations
- Locate migration files in `migrations/` directory
- Apply in order with `npx wrangler d1 migrations apply <db>`
- Record applied migrations in `d1_migrations` table
- Roll back on failure if down-migration exists

### 4. query — Execute SQL
- Validate SQL is read-only unless `--write` flag is set
- Run `npx wrangler d1 execute <db> --command "<sql>"`
- Format results as a table; warn on full-table scans

### 5. backup — Export Database
- Run `npx wrangler d1 export <db> --output backup.sql`
- Verify row counts match live database
- Store backup in `_state/backups/d1_<db>_<date>.sql`

### 6. Verify Binding
- Confirm `[[d1_databases]]` block in `wrangler.toml`
- Check `binding`, `database_name`, and `database_id` are set

## Output Format

```
workers-d1 | <db-name>

## Action: <schema|migrate|query|backup>

## Schema
| Table      | Columns | Indexes | FKs |
|------------|---------|---------|-----|
| users      | 5       | 2       | 0   |
| posts      | 7       | 3       | 1   |

## Migration
- Applied: 0003_add_user_avatar.sql
- Status: success | Rows affected: 0

## Query Result
| id | name    | email             |
|----|---------|-------------------|
| 1  | Alice   | alice@example.com |

## Binding
- Binding: DB | Database: <name> | ID: <uuid>
- wrangler.toml: configured / missing

## Verdict
READY / MIGRATION_FAILED / BINDING_MISSING / BACKUP_MISMATCH
```

## Skill Chains
- After schema inspection -> `[cloudflare]` to verify Worker integration
- After backup -> `[sqlite-inspect]` to validate exported SQL
- Before deployment -> `[deploy-checklist]` to confirm prerequisites
