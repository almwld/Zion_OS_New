---
name: control-catalog
description: Manage a catalog of governance controls mapped to multiple frameworks (NIST, ISO, SOC 2).
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action list|add|map|search|export] [--framework nist|iso|soc2|all] [--domain DOMAIN]"
category: governance-compliance
status: candidate
---
# Control Catalog

Maintain a structured catalog of AI governance controls that map across frameworks. The single source of truth for "what controls exist and which frameworks they satisfy."

## When to Use
- Building a governance program from scratch
- Mapping existing controls to a new framework
- Client engagement requiring multi-framework compliance
- When user says "control catalog" or "controls database"

## Storage

Controls stored at `_state/governance/control-catalog.jsonl`:
```json
{"id": "CTL-001", "name": "Model Inventory", "domain": "Model", "description": "Maintain inventory of all AI models in production", "frameworks": {"nist_ai_rmf": "GOVERN 1.1", "iso_42001": "6.1.2", "soc2": "CC6.1"}, "status": "implemented", "evidence": "model-registry.jsonl", "owner": "platform-team"}
```

## Execution

### list
Show all controls, optionally filtered by framework or domain.

### add
Create a new control with framework mappings.

### map
Map an existing control to a new framework category.

### search
Find controls by keyword, framework reference, or domain.

### export
Export catalog as Markdown table, CSV, or JSON for client deliverables.

## Output Format

```
Control Catalog | {action}
==========================

## Controls ({N} total)
| ID | Name | Domain | NIST | ISO | SOC 2 | Status |
|----|------|--------|------|-----|-------|--------|
| CTL-001 | Model Inventory | Model | GOVERN 1.1 | 6.1.2 | CC6.1 | Implemented |

## Coverage
| Framework | Controls Mapped | % Coverage |
|-----------|----------------|------------|
| NIST AI RMF | {N}/{total} | {%} |
| ISO 42001 | {N}/{total} | {%} |
| SOC 2 | {N}/{total} | {%} |
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Gaps found | `[gap-analysis]` (quantify gaps) |
| New framework | `[nist-map]` or `[iso-crosswalk]` (map controls) |
| Client deliverable | `[assessment-report]` (include catalog) |
| Export | `[docgen]` (generate formatted report) |
