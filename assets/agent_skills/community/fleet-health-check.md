---
name: fleet-health-check
description: Composite fleet health check that runs all 4 validation skills — fleet-skill-smoke (schema), script-existence-check (binaries exist), skill-supersession-check (succession complete), script-flag-check (CLI flags valid). Single-command fleet integrity sweep.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--strict] [--json]"
category: fleet-ops
status: candidate
---
# Fleet Health Check

Single-command composite check that runs all 4 fleet validation skills in sequence and aggregates results. Catches the three classes of dangling-reference failure: missing binaries, incomplete supersession, and stale CLI flags.

## When to Use

- Before `[mesh-sync]` or cross-machine propagation
- After bulk skill edits (renames, replacements, supersessions)
- As part of a periodic fleet health audit
- After creating new skills or retiring old ones
- Before committing changes that touch CLI command examples in SKILL.md files

## Check Suite

| Check | Skill | What it catches |
|-------|-------|-----------------|
| Schema validation | `[fleet-skill-smoke]` | Missing frontmatter, placeholder tokens, no markdown headings |
| Script existence | `[script-existence-check]` | SKILL.md references to `~/bin/` scripts that don't exist |
| Supersession | `[skill-supersession-check]` | Skills marked `status: superseded` with missing successors or live refs |
| CLI flags | `[script-flag-check]` | SKILL.md references to CLI flags the binary doesn't support |

## Operations

### Run all 4 checks (default)
```bash
python ~/bin/fleet-health-check.py
```

### Strict mode (exit 1 on any failure)
```bash
python ~/bin/fleet-health-check.py --strict
```

### JSON output (for CI / logging)
```bash
python ~/bin/fleet-health-check.py --json
```

## Output Format

```
Fleet Health Check
===================================================================
1. Schema (fleet-skill-smoke)      ... PASS (964 skills, 0 fail)
2. Script existence                 ... PASS (197 refs, 0 dangling)
3. Supersession                     ... PASS (2 superseded, 0 issues)
4. CLI flags                        ... PASS (67 files, 0 mismatches)
===================================================================
Overall: PASS
```

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| Any check FAILS | Fix the specific issue flagged by the failing check |
| All checks PASS | Safe to proceed with `[mesh-sync]` or fleet propagation |
| After bulk skill edits | Run this before committing to catch introduced bugs |

## Origin

Created 2026-09-15 after the reasoning-router dangling-reference audit revealed that 3 classes of failure (missing binaries, incomplete supersession, stale CLI flags) were not caught by any existing validation. Each class now has a dedicated check skill; this composite skill runs all 4 in sequence.
