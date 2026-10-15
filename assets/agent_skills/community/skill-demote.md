---
name: skill-demote
description: Demote a skill from a runtime lean set back to skills-full-only (on-demand). Removes the lean-set junction but keeps the skill in the canonical registry. Reversible.
version: 0.1.0
execution-mode: side_effecting
category: hummbl-research
status: candidate
---

# skill-demote

Demote a skill from a runtime lean set back to skills-full-only (on-demand). Removes the lean-set junction but keeps the skill in the canonical registry. Reversible -- the skill stays reachable via skills/.

## When to Use

- Reducing lean-set token cost
- Removing rarely-used skills from startup load
- Reversible demotion (unlike skill-archive)

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
