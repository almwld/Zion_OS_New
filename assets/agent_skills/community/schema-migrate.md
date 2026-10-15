---
name: schema-migrate
description: Generate migration scripts when contract schemas change
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<schema-name> [--diff] [--generate]"
category: dev-tools
status: candidate
---
# [schema-migrate]

## When to Use
- Contract schema in `contracts/` has been updated
- Need to migrate existing data to new schema version
- Planning a breaking change to a shared data model
- Before bumping `fm-contracts-vX.Y` baseline tag

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=schema-migrate] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Identify Schema Change
```bash
# List contract schemas
find contracts/ -name "*.schema.json" -o -name "*.json" | head -20
# Recent schema changes
git log --oneline --since="30 days ago" -- "contracts/" | head -10
# Diff current vs last tag
git diff fm-contracts-v0.1..HEAD -- contracts/ 2>/dev/null | head -50
```

### 2. Schema Diff (if --diff)
Compare old and new schema versions:
```bash
# Find the schema file
find contracts/ -name "*$SCHEMA_NAME*" | head -5
# Show diff against baseline
git diff fm-contracts-v0.1..HEAD -- "contracts/**/*$SCHEMA_NAME*" 2>/dev/null
```

Classify changes:
- **ADDITIVE**: new optional fields (backward compatible)
- **BREAKING**: removed fields, type changes, new required fields
- **RENAME**: field renamed (breaking unless aliased)
- **DEFAULT**: new field with default value (usually safe)

### 3. Impact Analysis
```bash
# Find all code that uses this schema
grep -rn "$SCHEMA_NAME" $PROJECT_ROOT/ --include="*.py" | head -20
# Find all test fixtures using this schema
grep -rn "$SCHEMA_NAME" $PROJECT_ROOT/tests/ --include="*.py" | head -20
# Find state files that contain this data
find _state/ $PROJECT_ROOT/state/ -name "*.json" -o -name "*.jsonl" 2>/dev/null | head -10
```

### 4. Generate Migration (if --generate)
For each breaking change, generate a Python migration function:
- Read old-format data
- Transform to new format
- Validate against new schema
- Write migrated data
- Keep backup of original

Migration script template:
```python
"""Migration: <schema_name> v<old> -> v<new>"""
import json
import shutil
from pathlib import Path

def migrate(data_path: Path) -> None:
    # Backup
    shutil.copy2(data_path, data_path.with_suffix('.bak'))
    # Read
    with open(data_path) as f:
        data = json.load(f)
    # Transform
    # ... field mappings ...
    # Write
    with open(data_path, 'w') as f:
        json.dump(data, f, indent=2)
```

### 5. Validation
- Run schema validator against migrated data
- Run affected tests
- Verify no data loss

## Output Format

```
Schema Migration | <schema-name> | <date>
============================================

Schema: contracts/cognition/schemas/clp.ledger_entry.json
Baseline: fm-contracts-v0.1
Current:  HEAD

Changes Detected
----------------
  [ADDITIVE]  Added optional field "priority" (string, default: "normal")
  [BREAKING]  Renamed "agent_id" -> "agent_name"
  [BREAKING]  Changed "timestamp" type: string -> integer (epoch)
  [DEFAULT]   Added "schema_version" with default "1.1"

Impact
------
  Code references:     12 files in services/, 4 in cognition/
  Test fixtures:       8 files
  State files:         _state/cognition/ledger.jsonl (4,200 entries)

Migration Plan
--------------
  1. Add "agent_name" field (copy from "agent_id")
  2. Convert "timestamp" string -> epoch integer
  3. Add "schema_version": "1.1" to all entries
  4. Remove "agent_id" after code updated
  5. Update 12 source files + 8 test files

Generated: $PROJECT_ROOT/scripts/migrate_ledger_entry_v1_1.py

Requires SemVer: MINOR (additive) or MAJOR (if breaking changes ship)
Next action: <recommendation>
```

## Skill Chains

### Mandatory

- `[contract-review]` MUST pass before execution — breaking change detection ensures schema compatibility, impact analysis, and migration safety before any destructive write.

### Advisory

- After `[schema-migrate] --generate` → `[test-run]` to verify migration
- After `[schema-migrate]` → `[contract-review]` for formal schema approval
- Before `[schema-migrate]` → `[error-catalog]` to understand current validation errors

## Authority

- **T1 (TRUSTED)**: May run with `[contract-review]` passed
- **T2 (Active/High)**: Operator approval required + `[contract-review]` passed
- **T3 (Medium)**: Operator approval required + `[contract-review]` passed
- **T4 (Probationary)**: BLOCKED
- **Operator**: Override any restriction
