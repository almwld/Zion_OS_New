---
name: sqlite-inspect
description: Inspect SQLite databases -- schema, row counts, recent writes, integrity check.
version: 0.1.0
execution-mode: advisory
argument-hint: "<db-path> [--tables] [--recent N] [--integrity]"
category: data-science
status: candidate
---
# SQLite Inspect

Examine SQLite databases used by hummbl-governance services (event_store, costs.db, ledger indexes).

## When to Use
- Debugging event_store or cost tracking issues
- Verifying data after migrations
- Checking database integrity after crashes
- Exploring unfamiliar SQLite files in _state/

## Execution

1. **Schema dump**: `sqlite3 <db> ".schema"`
2. **Table list with row counts**:
   ```bash
   sqlite3 <db> "SELECT name, (SELECT count(*) FROM [name]) FROM sqlite_master WHERE type='table';"
   ```
3. **Recent rows** (if timestamp column exists):
   ```bash
   sqlite3 <db> "SELECT * FROM <table> ORDER BY rowid DESC LIMIT N;"
   ```
4. **Integrity check**: `sqlite3 <db> "PRAGMA integrity_check;"`
5. **File size and last modified**: `ls -lh <db>`

## Output Format

```
SQLite Inspect | <db-path>
===========================
File: <path> | Size: <size> | Modified: <date>
Integrity: OK | Tables: N

| Table | Rows | Columns |
|-------|------|---------|
| ... | ... | ... |

Recent entries (last N):
<table output>
```

## Skill Chains
- After finding issues → `[mtsmu-debug]`
- After migration → `[sqlite-inspect]` to verify
- Data extraction needed → `[data-export]`
