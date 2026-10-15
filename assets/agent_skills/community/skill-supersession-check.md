---
name: skill-supersession-check
description: 'Scan for skills marked status: superseded and verify their successors exist and no live references remain in routing tables, skill chains, or policy docs. Catches the "skill superseded but succession incomplete" failure mode that fleet-llm exemplified.'
version: 1.0.0
execution-mode: advisory
argument-hint: "[--json] [--strict]"
category: skills-meta
status: candidate
---
# Skill Supersession Check

## When to Use

- After marking a skill as superseded in its SKILL.md frontmatter
- Before `[mesh-sync]` or cross-machine propagation
- As part of fleet health checks alongside `[fleet-skill-smoke]` and `[script-existence-check]`
- When investigating whether a superseded skill still has live references

## What It Catches

Skills marked `status: superseded` in their frontmatter where:
1. The `superseded_by` target does not exist as a skill (succession incomplete)
2. Active routing tables (`skill-routing.md`, `.skill-routing-index.json`) still point to the superseded skill
3. Skill chains (`rules/skill-chains.md`) still reference the superseded skill
4. Policy docs (`docs/policy/ai-use-policy.md`) reference the superseded skill as live

This was the `fleet-llm` failure mode: superseded by `fleet-llm` on 2026-09-06, but `fleet-llm` had no SKILL.md and 26 files still pointed to the dead skill for 8 days.

## Operations

### Scan all skill roots (default)
```bash
python ~/bin/skill-supersession-check.py
```

### JSON output (for CI / logging)
```bash
python ~/bin/skill-supersession-check.py --json
```

### Strict mode (exit 1 on any issue)
```bash
python ~/bin/skill-supersession-check.py --strict
```

## What It Checks

For each skill with `status: superseded` in frontmatter:

1. **Successor exists**: The `superseded_by` target has a `SKILL.md` in `skills/` or `skills-full/`
2. **No live routing references**: `skill-routing.md` has no `-> /<superseded-skill>` entries (excluding supersession notes)
3. **No routing index references**: `.skill-routing-index.json` has no `trigger_to_skill` entries pointing to the superseded skill
4. **No live chain references**: `rules/skill-chains.md` has no `/<superseded-skill>` entries (excluding supersession notes)
5. **No live policy references**: `docs/policy/ai-use-policy.md` has no live references (excluding supersession notes)

Supersession notes (lines containing "superseded", "SUPERSEDED", "was superseded", "script never built") are excluded — they are documentation of the supersession, not live references.

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| Successor missing | Create the successor SKILL.md before proceeding |
| Live references found | Redirect them to the successor skill |
| Dangling script references | `[script-existence-check]` to verify script binaries exist |
| Fleet health check | `[fleet-skill-smoke]` + `[script-existence-check]` + `[skill-supersession-check]` |

## Origin

Created 2026-09-14 after AAR for fleet-llm dangling-reference audit. Root cause: `fleet-llm` was superseded by `fleet-llm` but the succession was incomplete — `fleet-llm` got a script but no SKILL.md, and 26 files continued pointing to the dead skill. No mechanism existed to detect incomplete succession.
