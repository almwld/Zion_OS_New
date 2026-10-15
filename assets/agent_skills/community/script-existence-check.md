---
name: script-existence-check
description: Scan all SKILL.md files for ~/bin/ script references and verify the binaries exist. Catches the "skill doc written but script never built" failure mode that fleet-llm exemplified. Reports dangling references with the SKILL.md that references them.
version: 1.0.0
execution-mode: advisory
argument-hint: "[--json] [--strict] [--root PATH] [--bin-root PATH]"
category: skills-meta
status: candidate
---
# Script Existence Check

## When to Use

- After creating or updating SKILL.md files that reference `~/bin/` scripts
- Before `[mesh-sync]` or cross-machine propagation
- As part of `[fleet-skill-smoke]` for deeper validation
- When investigating whether a skill's referenced tool actually exists
- Periodic fleet health checks to catch stale script references

## What It Catches

Skills that pass `[fleet-skill-smoke]` (valid frontmatter, has sections, no TODOs) but reference a `~/bin/<name>.py` script that doesn't exist on disk. This was the `fleet-llm` failure mode: 26 files referenced `~/bin/fleet-llm.py` for months, and `fleet-skill-smoke` never caught it because it validates SKILL.md format, not script existence.

## Operations

### Scan all skill roots (default)
```bash
python ~/bin/script-existence-check.py
```

### JSON output (for CI / logging)
```bash
python ~/bin/script-existence-check.py --json
```

### Strict mode (exit 1 on any dangling reference)
```bash
python ~/bin/script-existence-check.py --strict
```

### Custom skill root
```bash
python ~/bin/script-existence-check.py --root ~/.agents/skills-full
```

## What It Checks

1. Scans all `SKILL.md` files under `~/.agents/skills/`, `~/.agents/skills-full/`, `~/.codex/skills/`, `~/.cursor/skills/`
2. Extracts all `~/bin/<name>.py`, `~/bin/<name>.sh`, `~/bin/<name>.ps1`, `~/bin/<name>.cmd` references
3. Checks each referenced script exists in `~/bin/`
4. Reports dangling references with the SKILL.md file that references them

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| Dangling references found | `[skill-supersession-check]` to check if the skill was superseded |
| New skill being created | `[fleet-skill-smoke]` for format validation |
| Fleet health check | `[fleet-skill-smoke]` + `[script-existence-check]` + `[skill-supersession-check]` |

## Origin

Created 2026-09-14 after AAR for fleet-llm dangling-reference audit. Root cause: `fleet-skill-smoke` validates SKILL.md schema format, not whether the script a skill claims to invoke actually exists. `fleet-llm` passed validation for months despite pointing to a nonexistent binary.
