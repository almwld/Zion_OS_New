---
name: factory-batch-run
description: Run Phase 0 HUAOMP/MTSMU scoring on a batch of candidates in parallel. Wrapper around the scorer that processes multiple candidates and aggregates results.
version: 0.1.0
execution-mode: side_effecting
category: dev-tools
status: candidate
---

# factory-batch-run

Run Phase 0 HUAOMP/MTSMU scoring on a batch of candidates in parallel. Wrapper around the scorer that processes multiple candidates and aggregates results.

## When to Use

- Batch processing multiple skill candidates through the factory pipeline
- Parallel HUAOMP/MTSMU scoring

## Notes

- Skill directory populated by junction remediation P5 (2026-07-26)
- Content sourced from fleet skill registry descriptions

## Skill Chains

### Mandatory

- None — this skill is self-contained.

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction
- **T3 (Medium)**: MUST get operator approval before execution
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
