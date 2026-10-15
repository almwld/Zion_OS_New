---
name: data-export
description: Export data from SQLite/JSONL/TSV to CSV, JSON, or Markdown tables.
version: 0.1.0
execution-mode: advisory
argument-hint: "<source-file> [--format csv|json|markdown] [--filter EXPR] [--limit N]"
category: data-science
status: candidate
---
# Data Export

Convert data between formats for reporting, sharing, or analysis.

## When to Use
- Pulling bus history for a report
- Exporting ledger entries for analysis
- Creating Markdown tables for docs or PRs
- Generating CSV for spreadsheet import

## Execution

1. **Detect source format** from file extension (.db/.sqlite, .jsonl, .tsv)
2. **Read data** using appropriate parser (sqlite3, json, csv stdlib modules)
3. **Apply filters** if --filter provided (Python expression on row dict)
4. **Apply limit** if --limit provided
5. **Output** in requested format:
   - `csv`: stdlib csv.writer
   - `json`: json.dumps with indent=2
   - `markdown`: pipe-delimited table

## Output Format

Writes to stdout or file. Reports row count and any skipped/filtered rows.

## Skill Chains
- Source inspection first → `[sqlite-inspect]` or `[jsonl-validate]`
- For bus data → `[bus-analytics]` first to identify interesting ranges
- For client deliverables → `[assessment-report]` or `[exec-summary]`
