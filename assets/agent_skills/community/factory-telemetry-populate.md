---
name: factory-telemetry-populate
description: Populate skill_invocations telemetry across fleet runtimes so lean-set-review has evidence fuel. Attribututions skill invocations from session transcripts/state into per-runtime skill_invocations tables.
version: 0.1.0
execution-mode: side_effecting
category: hummbl-research
status: candidate
---

# factory-telemetry-populate

Populate skill_invocations telemetry across fleet runtimes so lean-set-review has evidence fuel. Attribututions skill invocations from session transcripts/state into per-runtime skill_invocations tables.

## When to Use

- Before running lean-set-review to ensure telemetry data exists
- Backfilling skill invocation counts from session transcripts

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
