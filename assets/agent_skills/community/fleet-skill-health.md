---
name: fleet-skill-health
description: Validate fleet SKILL.md inventory structure through frontmatter smoke checks, declared-root coverage, inventory drift, and baseline snapshots; do not use for lifecycle scoring or pruning.
version: 0.1.1
execution-mode: advisory
argument-hint: "[smoke|rootset|drift|baseline] [mode-specific flags] [--json] [--strict]"
category: dev-tools
status: candidate
providers:
  required: [python]
---
# Fleet Skill Health

Consolidates four fleet-level skill monitoring capabilities into one skill:

| Mode | What it does | Former skill |
|------|-------------|--------------|
| `smoke` | Fast smoke validation of all SKILL.md files (frontmatter, headings, placeholders) | fleet-skill-smoke v0.1.2 |
| `rootset` | Root coverage matrix — missing/duplicate/orphan skill scopes | fleet-skill-rootset-scan v0.1.0 |
| `drift` | Inventory drift tracking vs baseline snapshot (added/removed/modified) | fleet-skill-drift v0.1.2 |
| `baseline` | Baseline snapshot management (init/refresh/show/status) | fleet-skill-baseline-manager v0.1.0 |

## When to Use

- Right after adding/updating multiple SKILL.md files → `smoke`
- Before cross-machine skill sync → `smoke` + `rootset`
- Tracking what changed since last snapshot → `drift`
- Bootstrapping or refreshing the baseline → `baseline`
- In a long-running Intel-Surge loop between heavy checks → `smoke`

This skill validates inventory structure. It does not score usage, epistemic
quality, promotion readiness, retirement, or pruning candidates; use
`[skill-evolve]` for those lifecycle decisions. For missing routing triggers,
use `[routing-evolve]`.

## Mode: smoke

Validates each discovered `SKILL.md`:
1. YAML frontmatter exists with required keys: `name`, `description`, `version`, `execution-mode`
2. File contains at least one markdown section header (`^# `)
3. No placeholder tokens (`TODO`, `TBD`, `FIXME`, `<NEEDS_FILL>`, `path/to/`)
4. `--strict` treats any FAIL as hard stop

```powershell
python $HOME/.agents/skills/fleet-skill-health/scripts/smoke.py --top 20
python $HOME/.agents/skills/fleet-skill-health/scripts/smoke.py --strict --json
```

## Mode: rootset

Validates declared skill roots and coverage:
- Ensures declared roots exist
- Per-root SKILL.md coverage counts
- Detects overlapping declared roots
- Detects orphan skill files outside canonical roots
- Compares declared roots to canonical root set

```powershell
python $HOME/.agents/skills/fleet-skill-health/scripts/rootset_scan.py
python $HOME/.agents/skills/fleet-skill-health/scripts/rootset_scan.py --strict --json
```

## Mode: drift

Tracks skill inventory drift over time:
- Enumerates all SKILL.md paths across roots
- Canonicalizes to stable IDs (root-label/relative-path)
- Computes deltas vs prior snapshot: added, removed, modified (hash/size change)
- `--strict` blocks if removals >3 or template-token removals detected
- `--baseline-update` saves refreshed snapshot

```powershell
python $HOME/.agents/skills/fleet-skill-health/scripts/drift.py
python $HOME/.agents/skills/fleet-skill-health/scripts/drift.py --baseline-update
python $HOME/.agents/skills/fleet-skill-health/scripts/drift.py --strict --json
```

## Mode: baseline

Creates and maintains the all-skills baseline snapshot:
- `init` — create baseline once (or with `--force`)
- `refresh` — overwrite baseline with full live snapshot
- `show` / `status` — report without writing
- Gated updates with `--max-removed` and `--max-template-removed` thresholds

```powershell
python $HOME/.agents/skills/fleet-skill-health/scripts/baseline_manager.py --mode init
python $HOME/.agents/skills/fleet-skill-health/scripts/baseline_manager.py --mode refresh
python $HOME/.agents/skills/fleet-skill-health/scripts/baseline_manager.py --mode status --json
```

## Output Format

```
Fleet Skill Health | <mode>

<mode-specific summary>

SUMMARY  mode=<mode>  total=<N>  pass=<P>  warn=<W>  fail=<F>
```

## Skill Chains

| After this mode... | Consider... |
|--------------------|-------------|
| `smoke` (fail/warn found) | `drift` for time-series context on what changed |
| `drift` (removals detected) | `[skill-audit]` for security/epistemic pass on survivors |
| `baseline` (init/refresh) | `drift` to verify the new baseline is clean |
| Any mode (clean) | `[skill-evolve]` to score health, `[skill-selection-eval]` for sizing |

## Provenance

Consolidated 2026-08-03 from four separate skills (fleet-skill-smoke, fleet-skill-rootset-scan, fleet-skill-drift, fleet-skill-baseline-manager) to reduce catalog over-supply. Scripts extracted verbatim from inline PowerShell here-strings in the original SKILL.md files.
