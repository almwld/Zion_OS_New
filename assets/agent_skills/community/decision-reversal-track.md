---
name: decision-reversal-track
description: Track decisions that were later reversed and why. Records the reversal context, trigger, and learning into the cognitive ledger.
version: 0.1.0
execution-mode: side_effecting
category: fleet-ops
status: candidate
---

# decision-reversal-track

Track decisions that were later reversed and why. Records the reversal context, trigger, and learning into the cognitive ledger.

## When to Use

- After reversing a prior architectural or process decision
- Building a decision quality feedback loop
- Postmortem analysis of decision failures

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
