---
name: json-explore
description: Navigate complex JSON/JSONL structures, extract paths, compare versions, show schema
version: 0.1.0
execution-mode: advisory
argument-hint: "<file> [--path JSONPATH] [--compare FILE2]"
category: data-science
status: candidate
---
# JSON Explore

Navigate complex JSON and JSONL structures interactively. Extract specific paths, infer schema, compare two versions for structural or value differences, and summarize nested data shapes.

## When to Use
- You need to understand the structure of a large or deeply nested JSON file
- You want to extract specific values using JSONPath-like expressions
- You need to compare two JSON files for structural or content differences
- You want to infer or validate the implicit schema of a JSON/JSONL dataset

## Execution
1. Parse `$ARGUMENTS` for file path, optional `--path` for extraction, `--compare` for diff
2. Load the JSON or JSONL file, detecting format automatically
3. If JSONL, sample first 100 lines to infer consistent schema
4. Map the structure: keys, depths, types, array lengths, null rates
5. If `--path` specified, extract and display matching values
6. If `--compare` specified, compute structural diff (added/removed keys, type changes, value changes)
7. Present schema summary and findings

## Output Format
```
JSON Explore | <filename>

## Structure
Format: JSON | JSONL (<N> lines)
Depth: <max nesting depth>
Top-level keys: <list>

## Schema
| Path | Type | Count | Nulls | Example |
|------|------|-------|-------|---------|
| .id  | string | 100 | 0 | "abc-123" |
| ...  | ...    | ... | ... | ...       |

## Comparison (if --compare)
| Change | Path | File1 | File2 |
|--------|------|-------|-------|
| ADDED  | .new_key | - | string |
| ...    | ...  | ...   | ...    |

## Findings
- <finding with severity and action>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Schema needs migration | `[schema-migrate]` to generate migration scripts |
| Contract schema changed | `[contract-review]` to validate compatibility |
