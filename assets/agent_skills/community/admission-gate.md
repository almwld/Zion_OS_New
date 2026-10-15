---
name: admission-gate
description: Redaction gate for publishing fleet artifacts to external remotes. Hard-fails on local paths, machine names, Tailscale/SSH identifiers, secrets, bus paths, and live fleet directory references. Auto-normalizes home paths to placeholders. Produces machine-readable receipt + human audit summary.
version: 0.1.0
execution-mode: side_effecting
category: fleet-ops
status: candidate
---

# admission-gate

Redaction gate for publishing fleet artifacts to external remotes. Hard-fails on local paths, machine names, Tailscale/SSH identifiers, secrets, bus paths, and live fleet directory references. Auto-normalizes home paths to placeholders. Produces machine-readable receipt + human audit summary.

## When to Use

- Before publishing fleet artifacts to external remotes
- When sharing logs, configs, or docs outside the fleet
- Pre-publish scan for PII and identifiers

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
