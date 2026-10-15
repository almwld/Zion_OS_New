---
name: insight-capture
description: Structured insight capture from sessions into the cognitive ledger. Distills a non-obvious finding into a tagged, retrievable ledger entry.
version: 0.1.0
execution-mode: side_effecting
category: fleet-ops
status: candidate
---

# insight-capture

Structured insight capture from sessions into the cognitive ledger. Distills a non-obvious finding into a tagged, retrievable ledger entry.

## When to Use

- Capturing a non-obvious finding during a session
- Persisting insights for future retrieval
- Building the cognitive ledger knowledge base

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
