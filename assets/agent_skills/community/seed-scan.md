---
name: seed-scan
description: Python-harness scanner over the same canonical surfaces nexus scans (rules, candidates, archived, agents, skills, memory, routing, SoT/cross-refs) that ranks hits as seed candidates for hummbl-formalization — def-shaped, theorem-shaped, or open-question-shaped per MISSION.md. Use when looking for what in the fleet's PSOT could become a Lean 4 object, lemma, or honestly-recorded open question.
version: 0.1.0
execution-mode: advisory
argument-hint: "<topic or question> [--max N] [--json]"
status: candidate
category: governance-compliance
---
<!-- SoT: profile (~/.agents/skills-full/seed-scan/SKILL.md). Repo mirror: PROJECTS/apex-nexus/skills/seed-scan/SKILL.md. -->

# Seed-Scan

Nexus-shaped scan with a different question. `[nexus]` asks "what does the
fleet already know about X?" — `[seed-scan]` asks "what in the fleet could
become a Lean-checked object in `PROJECTS/hummbl-formalization`?"

The harness is `scripts/seed_scan.py` — stdlib-only Python 3, read-only,
no network. It walks the same seven surfaces nexus defines and scores each
line for formalization value instead of emitting a governance map.

## Surfaces scanned (same as nexus)

| Surface | Path under `--root` (default `~/.agents`) |
|---|---|
| Rules | `rules/*.md` |
| Candidates | `rules/_candidates/*.md` (tier marks C1-3 × M0-3 extracted) |
| Archived/superseded | `rules/_archived/*.md` + `SUPERSEDED` markers |
| Agents | `ROSTER.md`, `IDENTITY.md`, `rules/*-guardrails.md` |
| Skills | `skills/*/SKILL.md` and `skills-full/*/SKILL.md` (deduped) |
| Memory | `$FLEET_MEM`, `$RUNTIME_MEM`, else `memory/` |
| Routing | `skill-routing.md`, `skill-chains*.md`, `harness-routing.md` |

## Seed shapes (per MISSION.md)

- **def** — defines a term / names a typed object → candidate `structure`/definition
- **theorem** — carries deontic/invariant force (MUST, NEVER, always, invariant, enforced) → candidate lemma
- **open** — marked open/TODO/unclear/observe-only → record as open question (mission item 3)
- **superseded** — file carries a superseded marker → do not formalize; drift note only

## Invocation

```bash
python ~/.agents/skills/seed-scan/scripts/seed_scan.py "transformation algebra"
python ~/.agents/skills/seed-scan/scripts/seed_scan.py            # full sweep
python ~/.agents/skills/seed-scan/scripts/seed_scan.py kill-switch --json
# Windows fallback: py -3 <script> ... ; any Python 3.9+ works
```

Flags: `--root` (scan a mirror/other PSOT root), `--max`, `--per-surface`,
`--json` (machine-readable for downstream tooling).

## Output

Markdown block headed `## SEED-SCAN: <topic>`: per-surface file/seed counts,
ranked seed rows (`shape`, score, candidate tier, `file:line`, snippet),
shape totals, and recommended consumption mapping to hummbl-formalization
workflow. `--json` emits the same data structured.

## Chains

- **Before**: `[nexus]` for governance context on the same topic; seed-scan
  adds the "could this be Lean-checked" ranking.
- **After**: take a top-ranked seed into `hummbl-formalization` — write the
  `.lean` object, build with `lake build`, and if it targets an Init-only
  module, admit via `python scripts/seed_lab/admit.py`. Record open-shaped
  seeds as open questions, not as results.

## Anti-patterns

- **Formalizing superseded surfaces** — seeds marked `superseded` are drift
  notes, never targets.
- **Treating a high score as a theorem** — the score is a triage heuristic
  for where to look, not evidence the statement is provable.
- **Skipping `admit.py`** — Init-only modules are admitted by the repo's own
  harness; seed-scan finds candidates, it does not admit them.
- **Writing to scanned surfaces** — read-only. Promotions go through
  `rules/_candidates/` triage, not through this skill.
