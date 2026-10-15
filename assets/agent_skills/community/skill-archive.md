---
name: skill-archive
description: Move a dormant skill to cold storage. Only after 90d dormancy across ALL runtimes + no routing triggers. Severe -- removes from canonical entirely (unlike skill-demote which is reversible).
version: 0.1.0
execution-mode: side_effecting
category: hummbl-research
status: candidate
---

# skill-archive

Move a dormant skill to cold storage. Only after 90d dormancy across ALL runtimes + no routing triggers. Severe -- removes from canonical entirely (unlike skill-demote which is reversible).

## When to Use

- After 90d dormancy across all runtimes
- No routing triggers reference the skill
- Cold storage of truly extinct skills

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
