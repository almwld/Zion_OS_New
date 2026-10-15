---
name: migration-check
description: Pre-migration validation — schema compatibility, data integrity, rollback plan
version: 1.0.0
execution-mode: remedial
argument-hint: <migration-path-or-description>
category: backend-infra
status: candidate
---
# Migration Check | `$ARGUMENTS`

Validate a migration before execution. Checks schema compatibility, data integrity, rollback feasibility, and contract compliance.

## Context Gathering

Before executing this skill, gather the following context:
- Run `ls -1 contracts/ 2>/dev/null | head -10`
- Run `ls -1 contracts/cognition/schemas/*.json 2>/dev/null`
- Run `git tag -l 'fm-contracts-*' 2>/dev/null`
- Run `wc -l _state/cognition/ledger.jsonl 2>/dev/null`

## Procedure

Parse `$ARGUMENTS` for the migration target. This could be a migration script path, a schema diff description, or a data format change.

### Step 1 — Identify Migration Type

Classify the migration:
- **Schema**: JSON Schema change in `contracts/` (field added/removed/renamed/retyped)
- **Data**: Format change in JSONL, TSV, SQLite (ledger, bus, event store, briefings)
- **Config**: Environment variable, launchd plist, or git hook change
- **Code**: Import path change, module rename, API signature change

### Step 2 — Schema Compatibility Check

For schema migrations, diff old vs new:

```bash
# Show current frozen baseline tag
git tag -l 'fm-contracts-*' | sort -V | tail -1

# Diff contract schemas against baseline
git diff $(git tag -l 'fm-contracts-*' | sort -V | tail -1)..HEAD -- contracts/ 2>/dev/null

# Validate new schema is valid JSON
python3 -c "
import json, glob, sys
errors = []
for f in glob.glob('contracts/**/*.json', recursive=True):
    try:
        json.load(open(f))
    except json.JSONDecodeError as e:
        errors.append(f'{f}: {e}')
if errors:
    print('FAIL: Invalid JSON schemas:')
    for e in errors: print(f'  {e}')
    sys.exit(1)
else:
    print(f'PASS: All contract schemas are valid JSON')
"
```

Classify changes as:
- **Additive** (new optional field): backward compatible, no version bump needed
- **Additive required** (new required field): BREAKING, needs major version bump
- **Removal** (field deleted): BREAKING, needs major version bump
- **Type change** (string to int): BREAKING, needs major version bump
- **Rename** (field renamed): BREAKING, needs migration script

### Step 3 — Data Integrity Check

For data migrations, verify source data health before transforming:

```bash
# JSONL integrity check (ledger)
python3 -c "
import json, sys
path = '_state/cognition/ledger.jsonl'
total = 0; errors = 0; nulls = {}
try:
    with open(path) as f:
        for i, line in enumerate(f, 1):
            total += 1
            try:
                obj = json.loads(line)
                for k, v in obj.items():
                    if v is None:
                        nulls[k] = nulls.get(k, 0) + 1
            except json.JSONDecodeError:
                errors += 1
                if errors <= 5: print(f'  Line {i}: malformed JSON')
    print(f'Total rows: {total}')
    print(f'Parse errors: {errors}')
    if nulls: print(f'Null fields: {nulls}')
    print('PASS' if errors == 0 else 'FAIL')
except FileNotFoundError:
    print(f'SKIP: {path} not found')
"

# TSV integrity check (bus)
python3 -c "
import sys
path = '_state/coordination/messages.tsv'
total = 0; errors = 0
try:
    with open(path) as f:
        for i, line in enumerate(f, 1):
            total += 1
            cols = line.rstrip('\n').split('\t')
            if len(cols) != 5:
                errors += 1
                if errors <= 5: print(f'  Line {i}: {len(cols)} cols (expected 5)')
    print(f'Total rows: {total}')
    print(f'Format errors: {errors}')
    print('PASS' if errors == 0 else 'FAIL')
except FileNotFoundError:
    print(f'SKIP: {path} not found')
"

# SQLite integrity (event store)
python3 -c "
import sqlite3, glob
for db in glob.glob('_state/**/*.db', recursive=True) + glob.glob('_state/**/*.sqlite', recursive=True):
    conn = sqlite3.connect(db)
    result = conn.execute('PRAGMA integrity_check').fetchone()
    tables = conn.execute(\"SELECT name FROM sqlite_master WHERE type='table'\").fetchall()
    counts = {t[0]: conn.execute(f'SELECT COUNT(*) FROM [{t[0]}]').fetchone()[0] for t in tables}
    print(f'{db}: integrity={result[0]}, tables={counts}')
    conn.close()
" 2>/dev/null || echo "SKIP: No SQLite databases found"
```

### Step 4 — Rollback Plan Verification

```bash
# Check if a rollback script or plan exists
find . -name '*rollback*' -o -name '*revert*' -o -name '*undo*' 2>/dev/null | grep -v node_modules | grep -v .git | head -10

# Check git can revert (clean working tree)
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
[ "$DIRTY" -eq 0 ] && echo "PASS: clean working tree (git revert possible)" || echo "WARN: $DIRTY dirty files (commit or stash before migration)"

# Check if state is backed up
ls -la _state/snapshots/ 2>/dev/null || echo "WARN: No _state/snapshots/ directory -- consider [state-snapshot] first"
```

### Step 5 — Breaking Change Detection

```bash
# Check if migration touches frozen contracts
git diff --name-only HEAD~5..HEAD -- contracts/ 2>/dev/null | while read f; do
    echo "CHANGED: $f"
    git log --oneline -1 -- "$f"
done

# Check for import path changes that break consumers
python3 -c "
import ast, sys, glob
target = sys.argv[1] if len(sys.argv) > 1 else 'your_project'
importers = []
for f in glob.glob('**/*.py', recursive=True):
    try:
        tree = ast.parse(open(f).read())
        for node in ast.walk(tree):
            if isinstance(node, (ast.Import, ast.ImportFrom)):
                mod = getattr(node, 'module', '') or ''
                if target in mod:
                    importers.append(f'{f}:{node.lineno}')
    except: pass
print(f'Files importing {target}: {len(importers)}')
for i in importers[:10]: print(f'  {i}')
" your_project 2>/dev/null
```

## Output Format

```
Migration Check | <description> | <date>
========================================

Type: <Schema | Data | Config | Code>
Scope: <files/tables affected>

Schema Compatibility:
  Frozen baseline: fm-contracts-v0.1
  Changes: <N additive, M breaking>
  Verdict: [SAFE|BREAKING] -- <reason>

Data Integrity:
  Ledger: <N rows, M errors, K null fields>
  Bus: <N rows, M format errors>
  Event Store: <integrity status, row counts>
  Verdict: [CLEAN|DIRTY] -- <details>

Rollback Plan:
  Git revert possible: [YES|NO]
  State snapshot exists: [YES|NO]
  Rollback script exists: [YES|NO]
  Verdict: [READY|MISSING] -- <what is needed>

Breaking Changes:
  Contract changes: <list>
  Import path changes: <list>
  Consumers affected: <N files>

Overall Readiness: [GO|NO-GO]
  Blockers: <list or "none">
  Warnings: <list or "none">

Next action: <proceed with migration | fix blockers | take snapshot first>
```

## Skill Chains
- Before: `[state-snapshot]` (backup before migrating), `[contract-review]` (if schema change)
- After: `[test-run]` (verify nothing broke), `[health]` (verify services healthy), `[commit]` (commit migration)
