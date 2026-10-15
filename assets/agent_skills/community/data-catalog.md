---
name: data-catalog
description: Build and query a data catalog with metadata, schema, access policies, and lineage links
version: 0.1.0
execution-mode: advisory
argument-hint: "[--source <db|api|file>] [--format json|yaml]"
category: dev-tools
status: candidate
---
# data-catalog | Data Catalog Builder

## When to Use
- Establishing a searchable inventory of datasets across systems
- Onboarding a new data source into governance workflows
- Discovering schema, ownership, and access policies for a dataset
- Providing lineage links for impact analysis and compliance audits

## Execution

### 1. Parse Arguments
- `--source <db|api|file>`: restrict catalog scan to a single source type
- `--format json|yaml`: output format for the catalog document (default json)

### 2. Discover Sources
- Enumerate configured connections (databases, APIs, file stores)
- For each source, list available datasets, tables, and endpoints
- Record source type, connection metadata, and last-modified timestamps

### 3. Extract Metadata
- For each dataset: capture schema (columns, types), row count, and size
- Detect primary keys, foreign keys, and indexes where available
- Record owner, data Principal AI Agent (business owner), and classification tags if present
- Link to existing lineage records by table or column name

### 4. Apply Access Policies
- Read policy rules from `_state/policies/` or source annotations
- Tag each asset with access level: public, internal, restricted, confidential
- Record role grants and column-level masks where defined

### 5. Build Catalog Document
- Assemble entries into a single catalog document
- Include a table of contents, source index, and searchable tags
- Write to `_state/catalog/catalog.<format>`

## Output Format

```
data-catalog | <source-or-all>

## Summary
- Sources scanned: 3 | Datasets cataloged: 42
- Format: json | Catalog file: _state/catalog/catalog.json

## Catalog Entries
| Dataset            | Source   | Rows     | Access       | Owner       | Lineage |
|--------------------|----------|----------|--------------|-------------|---------|
| public.users       | postgres | 1,204,33 | internal     | data-team   | linked  |
| api.payments       | stripe   | 88,210   | restricted   | finance     | linked  |
| file.events_2024   | s3       | 5,200,00 | confidential | platform    | none    |

## Schema Sample (public.users)
- id: integer, pk, not null
- email: varchar(255), unique, pii
- created_at: timestamp, not null

## Verdict
PASS | 42 datasets cataloged, 38 lineage links resolved
```

## Skill Chains
- After cataloging -> `[data-lineage]` to trace dependencies
- After cataloging -> `[data-profile]` to enrich column statistics
- Before cataloging -> `[data-govern]` to define policy frameworks
