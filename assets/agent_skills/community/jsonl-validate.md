---
name: jsonl-validate
description: Validate JSONL files against schemas, detect corruption, report line-level errors.
version: 0.1.0
execution-mode: advisory
argument-hint: "<file.jsonl> [--schema PATH] [--fix]"
category: data-science
status: candidate
---
# JSONL Validate

Verify integrity of append-only JSONL files (governance bus, cognitive ledger).

## When to Use
- After system crashes or unclean shutdowns
- Before ledger migrations
- Periodic health checks on _state/ files
- After multi-agent writes to shared JSONL

## Execution

1. **Line-by-line parse**: Read file, attempt `json.loads()` on each line
2. **Report corruption**: Lines that fail JSON parse (truncated, encoding errors)
3. **Schema validation** (if --schema): Validate each entry against JSON Schema
4. **Duplicate detection**: Check for duplicate IDs or content hashes
5. **Timestamp ordering**: Verify entries are chronologically ordered
6. **Fix mode** (if --fix): Write valid lines to .fixed file, report dropped count

## Output Format

```
JSONL Validate | <file>
========================
Lines: N total | N valid | N invalid | N duplicates
Schema: <pass/fail count if schema provided>
Order: chronological / OUT OF ORDER at line X

Errors:
  Line 42: JSONDecodeError -- truncated at byte 1024
  Line 99: Schema violation -- missing field 'timestamp'
```

## Skill Chains
- Before migration → `[jsonl-validate]` then `[migrate]`
- Corruption found → `[state-snapshot]` (restore from backup)
- Schema issues → `[contract-review]`
