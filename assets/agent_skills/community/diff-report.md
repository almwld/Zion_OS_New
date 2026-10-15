---
name: diff-report
description: Rich diff between two data files (CSV, JSON, JSONL) with statistical summary of changes
version: 0.1.0
execution-mode: advisory
argument-hint: "<file1> <file2> [--format summary|detailed]"
category: dev-tools
status: candidate
---
# Diff Report

Compare two data files and produce a rich diff with statistical summary. Supports CSV, JSON, and JSONL formats. Highlights added, removed, and modified records with aggregate change metrics.

## When to Use
- You need to compare two versions of a dataset to understand what changed
- You want a statistical summary of changes rather than a raw line diff
- You are reviewing data migrations or ETL pipeline outputs
- You need to verify that a data transformation preserved expected records

## Execution
1. Parse `$ARGUMENTS` for two file paths and optional `--format` (summary or detailed)
2. Detect file format for both files (CSV, JSON, JSONL)
3. Load and normalize both datasets into comparable structures
4. For CSV: compare by row index or key column if identifiable
5. For JSON: deep comparison of nested structures
6. For JSONL: line-by-line comparison with content hashing
7. Compute change statistics: added, removed, modified records/fields
8. If `--format detailed`, show per-record changes; otherwise show aggregate summary
9. Flag any schema changes (new columns, type changes, missing fields)

## Output Format
```
Diff Report | <file1> vs <file2>

## Summary
| Metric | Value |
|--------|-------|
| Records in file1 | <N> |
| Records in file2 | <N> |
| Added | <N> |
| Removed | <N> |
| Modified | <N> |
| Unchanged | <N> |

## Schema Changes
- ADDED column: <name> (type: <type>)
- REMOVED column: <name>

## Top Changes (if detailed)
| Record | Field | Old Value | New Value |
|--------|-------|-----------|-----------|
| ...    | ...   | ...       | ...       |

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Changes span multiple repos | `[mono-diff]` for cross-repo comparison |
| Changes need documentation | `[changelog]` to generate release notes |
