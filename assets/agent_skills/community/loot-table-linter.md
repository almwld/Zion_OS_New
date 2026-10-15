---
name: loot-table-linter
description: Audits drop tables and RNG configs (JSON, CSV, YAML) for rounding errors, unreachable loot tiers, or missing fallback drop IDs.
version: 1.0.0
execution-mode: advisory
container:
  tier: "1"
  base_image: "python:3.11-slim"
  gpu: false
category: dev-tools
status: candidate
providers:
  required: [docker, pytest, python, uv]
  pip: [pyyaml]
---

# Loot Table Linter

Validates loot/drop tables for common game design errors.

## Supported Formats

- **JSON** - Array of drop objects with `id`, `weight`, `tier`, `fallback`
- **YAML** - Same structure as JSON
- **CSV** - Columns: id, weight, tier, fallback

## Checks Performed

| Check | Severity | Description |
|-------|----------|-------------|
| Weight normalization | Warning | Total weights should sum to 1.0 |
| Duplicate IDs | Warning | No two drops should share an ID |
| Unreachable weights | Warning | Weights < 0.1% may never trigger |
| Missing fallback | Warning | At least one `fallback: true` drop needed |
| Empty tiers | Error | Tiers with zero drops |
| Invalid weights | Error | Non-numeric or negative weights |
| Duplicate IDs | Error | Same ID used multiple times |

## CLI Usage

```bash
# Dry run
python scripts/main.py --dry-run --json-output /dev/stdout

# Audit JSON loot table
python scripts/main.py --input loot_table.json --json-output result.json

# Audit CSV
python scripts/main.py --input drops.csv --json-output result.json

# Audit YAML
python scripts/main.py --input loot.yaml --json-output result.json

# Docker
docker compose run --rm skill --input /workspace/loot.json --json-output /workspace/result.json
```

## Output Schema

```json
{
  "status": "ok|error",
  "skill": "loot-table-linter",
  "version": "1.0.0",
  "result": {
    "total_drops": 10,
    "total_weight": 1.0,
    "tier_distribution": {"common": 5, "rare": 3, "legendary": 2},
    "has_fallback": true,
    "findings": [
      {"severity": "warning", "message": "Total weight sums to 0.995", "index": null},
      {"severity": "error", "message": "Tier 'mythic' has no drops", "index": null}
    ],
    "status": "fail"
  },
  "error": null
}
```

## Exit Codes

- `0` - All checks pass (status: pass)
- `1` - Validation errors found (status: fail)
- `2` - Usage error

## Container

- **Tier**: 1 (Pure Python)
- **Base Image**: `python:3.11-slim`
- **GPU**: Not required