---
name: schema-diff
category: dev-tools
description: "Compare two API or data schema versions and classify changes as breaking or non-breaking. Produce a migration impact report with affected consumers, required actions, and risk assessment. Use when evaluating schema changes before deployment or reviewing a PR that modifies contracts."
version: 0.1.0
status: candidate
execution-mode: advisory
argument-hint: "[--old <schema-file>] [--new <schema-file>] [--format openapi|graphql|protobuf|json-schema|sql]"
---

# schema-diff

Compare two schema versions and classify every change as **breaking**, **non-breaking**, or **deprecated**. Produce a migration impact report so operators can decide whether a change is safe to ship and what consumers must do.

## When to use

- Reviewing a PR that modifies an API contract or data schema.
- Preparing a deployment that changes request/response shapes or DDL.
- Auditing a version bump before publishing.

## When NOT to use

- Migration scripts → `schema-migrate`. Correctness/linting → `contract-review`. Runtime validation → validator middleware.

## Inputs

| Flag | Required | Description |
|------|----------|-------------|
| `--old <file>` | Yes | Path or URL to the baseline schema. |
| `--new <file>` | Yes | Path or URL to the proposed schema. |
| `--format` | No | `openapi` \| `graphql` \| `protobuf` \| `json-schema` \| `sql`. Auto-detected from content/extension if omitted. |

Supported formats: **OpenAPI 3.x** (paths, operations, parameters, schemas, enums), **GraphQL SDL** (types, fields, arguments, enums, interfaces, unions, input types), **Protobuf** (messages, fields+tags, enums, services, `reserved`), **JSON Schema** (properties, `required`, types, `enum`, constraints, `additionalProperties`), **SQL DDL** (columns, types, constraints, indexes, tables).

## Workflow

1. **Load** both schema versions (fetch if URL). Verify both parse before diffing.
2. **Normalize** each into an internal model: endpoints/operations, types/tables, fields/columns, constraints, enums, deprecation markers.
3. **Compute the diff**: added, removed, modified elements (type, constraint, tag/position, deprecation flag changes).
4. **Classify** each change per rules below. A rename = remove + add; classify each part and link them.
5. **Identify affected consumers** by grepping the codebase for removed/modified/renamed symbols. Report `file:line` refs grouped by consumer, with confidence `high`/`medium`/`low`.
6. **Assess risk** per change and aggregate for the whole diff.
7. **Emit** machine-readable JSON + human-readable markdown.

## Breaking change classification rules

### BREAKING

| Format | Change | Why |
|--------|--------|-----|
| OpenAPI | Removed path/operation; removed/newly-required param; removed guaranteed response field | Callers fail (404/405, missing input, missing output). |
| OpenAPI | Changed field type; narrowed enum; tightened `min`/`max`/`pattern`; added `additionalProperties: false` | Previously-valid data rejected. |
| GraphQL | Removed field/type/union member/interface; removed enum value; removed/made-required argument; incompatible argument type change; return type → non-null | Selections/queries error at runtime. |
| Protobuf | Removed/renumbered field tag; changed field type; removed in-use enum value; removed service method | Wire-compat breaks; decode/RPC errors. |
| JSON Schema | Added `required` entry; changed `type`; narrowed `enum`; tightened `min`/`max`/`pattern`; added `additionalProperties: false` | Existing data invalid. |
| SQL | Dropped column/table; renamed column; tightened constraint (`NOT NULL`/`CHECK`/shrunk domain); incompatible type change | App code breaks; rows/inserts fail; data loss. |

### NON-BREAKING

- Added optional field/property/column/endpoint/type/enum value/message (no new `required`, no shadowing).
- Widened constraint: raised `max`, lowered `min`, loosened `pattern`, removed `required` entry, `additionalProperties` → `true`, `NOT NULL` → nullable, widened domain.
- Description/doc-only changes. Added `deprecated: true` marker (marker is non-breaking; later removal is breaking).

### DEPRECATED

- Field/enum value/operation/column newly marked `deprecated` in the new schema. Flag separately so consumers can plan removal.

## Risk assessment

Per change: **low** (non-breaking), **medium** (breaking, narrow blast radius), **high** (breaking + widely-used symbol).

Aggregate: **low** (no breaking/deprecations), **medium** (breaking but few/known consumers, or only deprecations), **high** (breaking touches widely-referenced symbols or removed endpoints with active callers).

## Output format

Write two files (paths printed to stdout):

### `schema-diff.report.json`

```json
{
  "format": "openapi", "old": "v1.yaml", "new": "v2.yaml",
  "summary": { "breaking": 3, "nonBreaking": 7, "deprecated": 1, "risk": "high" },
  "changes": [{
    "id": "C1", "kind": "removed-field", "classification": "breaking", "severity": "high",
    "path": "#/components/schemas/User/properties/email",
    "description": "Removed field `email` from `User`.",
    "affectedConsumers": [{ "consumer": "billing-service", "refs": ["src/billing/user.go:42"], "confidence": "high" }],
    "requiredActions": ["Stop reading `email` in billing-service or source it elsewhere."],
    "migrationHint": "schema-migrate --from v1.yaml --to v2.yaml"
  }],
  "recommendedMigrationPath": ["Coordinate `email` removal with billing-service.", "Ship v2 behind a flag; monitor 4xx/5xx.", "Remove flag after one clean release cycle."]
}
```

### `schema-diff.report.md`

Human-readable: risk badge, counts table, per-change sections (classification, affected consumers, required actions, migration path). Ends with a "Suggested next step" recommending `schema-migrate` if any breaking change needs a script.

## Boundaries

- Does **not** generate migration scripts — recommend `schema-migrate`. Does **not** validate/lint — recommend `contract-review`. Does **not** execute against a live DB/server.
- Consumer-impact analysis is best-effort static grep; confidence flagged per match set.
