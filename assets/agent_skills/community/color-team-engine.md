---
name: color-team-engine
description: Full-spectrum color team registry and dispatcher for security wargames. Reads color-registry.yaml and dispatches any of 29 color teams as subagents with color-specific prompts, INT type routing, and ledger schema extensions.
version: 0.1.0
execution-mode: side_effecting
category: security
status: candidate
providers:
  optional: [yaml-ls]
---

# color-team-engine

Full-spectrum color team registry and dispatcher for security wargames. Reads color-registry.yaml and dispatches any of 29 color teams as subagents with color-specific prompts, INT type routing, and ledger schema extensions.

## When to Use

- Running spectrum wargames requiring multiple color teams
- Dispatching non-standard color teams (amber, lavender, gray, etc.)
- Wargame orchestration beyond standard red/blue/purple

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
