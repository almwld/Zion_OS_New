---
name: script-flag-check
description: Scan SKILL.md files for CLI flag references (--flag) and verify they exist in the referenced binary's --help output. Catches the "bulk replacement changed binary name but left flags that only existed in the old binary" failure mode.
version: 1.0.0
execution-mode: advisory
argument-hint: "[--json] [--strict] [--root PATH]"
category: skills-meta
status: candidate
---
# Script Flag Check

## When to Use

- After a bulk text replacement that changes binary names in SKILL.md files
- After renaming or refactoring a `~/bin/` script's CLI interface
- As part of fleet health checks alongside `[script-existence-check]` and `[skill-supersession-check]`
- Before committing changes that touch CLI command examples in SKILL.md files

## What It Catches

SKILL.md files that reference CLI flags a binary doesn't support. This was the `reasoning-router` -> `fleet-llm` bulk replacement failure mode: the replacement changed `reasoning_router.py` to `fleet-llm.py` but left `--task`, `--dry-run`, `--context-length` flags that only existed in `reasoning_router.py`. The resulting commands in 5 SKILL.md files would fail at runtime.

## Operations

### Scan all skill roots (default)
```bash
python ~/bin/script-flag-check.py
```

### JSON output (for CI / logging)
```bash
python ~/bin/script-flag-check.py --json
```

### Strict mode (exit 1 on any mismatch)
```bash
python ~/bin/script-flag-check.py --strict
```

## What It Checks

1. Scans all `SKILL.md` files under `~/.agents/skills/`, `~/.agents/skills-full/`, `~/.codex/skills/`, `~/.cursor/skills/`
2. Extracts all `python ~/bin/<name>.py --<flag>` command references
3. Runs `<binary> --help` to get the actual supported flags
4. Reports flags referenced in SKILL.md that don't exist in the binary's `--help` output

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| Flag mismatches found | Fix the SKILL.md references to use the correct flags |
| Missing binaries found | `[script-existence-check]` to verify script binaries exist |
| Fleet health check | `[fleet-skill-smoke]` + `[script-existence-check]` + `[skill-supersession-check]` + `[script-flag-check]` |

## Origin

Created 2026-09-14 after AAR for reasoning-router dangling-reference audit. The bulk `reasoning_router.py` -> `fleet-llm.py` replacement changed binary names but left `--task`, `--dry-run`, `--context-length` flags that only existed in `reasoning_router.py`. Self-review caught 7 broken commands in 5 SKILL.md files. This skill automates that check.
