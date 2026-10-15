---
name: contract-test
description: Verify service responses against contract schemas in contracts/ directory
version: 0.1.0
execution-mode: advisory
argument-hint: "[--schema <name>] [--all] [--service <url>]"
category: dev-tools
status: candidate
---
# contract-test | Contract Schema Verification

## When to Use
- After modifying services that produce contract-governed output
- Before tagging a new `fm-contracts-vX.Y` baseline
- Validating that live services match frozen contract schemas
- CI-equivalent local check for contract compliance

## Execution

### 1. Discover Contracts
- Scan `contracts/` directory for JSON Schema files (`.schema.json`)
- If `--schema <name>` specified, test only that schema
- If `--all`, test all discoverable schemas
- Map schemas to services/endpoints where possible

### 2. Load Schemas
- Parse each JSON Schema file
- Validate schema itself is well-formed
- Note schema version and frozen baseline status
- Current frozen baseline: `$FROZEN_BASELINE_TAG`

### 3. Collect Test Data
For each schema, gather test data from:
- Live service response (if `--service <url>` provided)
- Sample data in `contracts/*/examples/` if present
- Recent briefing output in `state/briefings/`
- Cognition ledger entries in `_state/cognition/`

### 4. Validate Against Schema
Use `your_package.cognition.schema_validator` (stdlib-only Draft 2020-12 subset):
- Validate each data sample against its schema
- Collect all validation errors with JSON path
- Check required fields, types, enum values, pattern constraints

### 5. Report Findings
- Group by schema: pass/fail count
- List all validation errors with field path and expected vs actual
- Flag any schemas with zero test data (untested contracts)

## Output Format

```
contract-test | contracts/

## Summary
- Schemas tested: 12
- Passed: 10 | Failed: 2 | No data: 1

## Results
| Schema                          | Samples | Pass | Fail | Status |
|---------------------------------|---------|------|------|--------|
| briefing.content.schema.json    | 5       | 5    | 0    | PASS   |
| agent.health.schema.json        | 3       | 2    | 1    | FAIL   |
| clp.ledger_entry.schema.json    | 8       | 8    | 0    | PASS   |
| cost.projection.schema.json     | 0       | --   | --   | NO DATA|

## Failures
1. agent.health.schema.json
   - Sample: state/briefings/2026-03-25.md
   - Error: $.probes[2].status -- expected enum ["healthy","degraded","down"], got "unknown"

## Untested Schemas
- cost.projection.schema.json -- no sample data found

## Frozen Baseline
- Current: $FROZEN_BASELINE_TAG
- Breaking changes detected: NO
```

## Skill Chains
- **Routing**: See `harness-routing.md` for SUT-type routing. This skill covers contract schema verification only.
- After failures -> fix service output, then `[api-test]` to verify
- Before release -> `[contract-test] --all` as gate check
- After adding new schema -> `[contract-test] --schema <name>` to verify examples
