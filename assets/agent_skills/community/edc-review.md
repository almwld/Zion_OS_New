---
name: edc-review
description: Derive an agent's Everyday Carry (EDC) skill set from usage telemetry, score concentration, and emit a PROPOSAL lean-set-review consumes. Thin derivation layer — not a parallel review engine.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--runtime opencode|devin|claude|codex|all] [--coverage 80] [--epistemic-only] [--json]"
category: hummbl-research
status: candidate
---
# EDC Review

Derives the Everyday Carry (EDC) — the minimal skill set covering P% of an
agent's session invocations — and emits a PROPOSAL `[lean-set-review]` consumes.
See `~/.agents/docs/EDC-for-AI-Agents.md` for the concept.

## When to Use

- Periodically (weekly) to review behavioral defaults vs. lean-set membership
- After `[skill-usage]` telemetry has accumulated
- When `[skill-selection-eval]` reports over-supply (EDC concentration diagnoses it)
- When an agent's sessions feel diffuse (no defaults, every session rediscovery)

## The Loop

```
[skill-usage] telemetry  ->  edc-review  ->  PROPOSAL  ->  [lean-set-review]
       (per agent/runtime)   (derive EDC set,        (consume as
                            score concentration,     promotion
                            emit proposal)           signal)
```

## Execution

### 1. Read telemetry
Run `[skill-usage] --json` (or read `~/.claude/_telemetry/skill-usage-*.json`
directly). If telemetry is sparse (<5% of skills with any invocation), run in
`--epistemic-only` mode and flag the gap (chain to `[factory-telemetry-populate]`).

### 2. Derive the EDC set
Per runtime, sort skills by invocation count descending. Accumulate until
coverage reaches P% (default 80). That set is the EDC.

### 3. Score concentration
```
EDC concentration = |EDC set| / |skills with >=1 invocation|
catalog-vs-EDC gap = |catalog| - |EDC set|
```
Low |EDC set| + high coverage = healthy defaults. High |EDC set| for 80% = diffuse.

### 4. Diff against lean-set membership
Per runtime lean set (`.opencode/skills`, `.devin/skills`, `.claude/skills`,
`.codex/skills`):
- **Promotion signal**: skill in EDC set but NOT in this runtime's lean set
  (reached for but not preloaded).
- **Demotion signal**: skill in lean set, NOT in EDC, zero specialist pulls
  (preloaded but never reached for).
- **Dead weight**: skill in catalog, NOT in EDC, zero invocations, no routing
  triggers (archive candidate — defer to `[skill-evolve] retire`).

### 5. Emit PROPOSAL
```
EDC REVIEW | <runtime> | <date> | coverage=80%
EDC SET (N skills cover 80% of invocations):
  1. sitrep (87 inv, 41 sessions)
  2. ponytail (62 inv, 38 sessions)
  [...]
CONCENTRATION: N=8 / 92 invoked = 0.087 (healthy)
CATALOG-vs-EDC GAP: 1696 - 8 = 1688 (pruning surface)

PROMOTE (in EDC, not in lean):
  - skill X (edc rank 4, usage=42) -> add to lean
DEMOTE (in lean, not in EDC, zero pulls):
  - skill Z (usage=0, 90d) -> remove from lean
DEAD WEIGHT (catalog, not in EDC, zero inv, no triggers):
  - skill W -> defer to [skill-evolve] retire
```
Post as bus PROPOSAL. `[lean-set-review]` consumes the promote/demote signals
via its standard closed loop.

## Telemetry Caveat

Starved without telemetry. `--epistemic-only` mode: skip usage-based derivation,
rely on `[skill-evolve]` epistemic scores to nominate an EDC set, flag the gap.
Same fallback `[lean-set-review]` uses.

## Safety

- **Advisory only.** Never mutates lean sets — emits PROPOSAL for
  `[lean-set-review]` + operator ACK.
- **Thin layer.** Does not duplicate `[lean-set-review]`'s promote/demote/archive
  execution; feeds it one more signal.
- **Read-only.** Reads telemetry and lean-set membership; writes nothing but the
  bus PROPOSAL.

## Skill Chains

| After... | Consider... |
|---|---|
| EDC review emits PROPOSAL | `[lean-set-review]` (consumes promote/demote) |
| Telemetry too sparse | `[factory-telemetry-populate]` |
| Dead weight found | `[skill-evolve] retire` |
| Over-supply diagnosed | `[skill-selection-eval]` for sizing detail |
| Concept reference | `~/.agents/docs/EDC-for-AI-Agents.md` |

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (advisory, read-only)
- **T3 (Medium)**: May run without restriction (advisory, read-only)
- **T4 (Probationary)**: May run (advisory — no destructive actions)

## Status

v0.1.0 — scaffolded. Active once `[factory-telemetry-populate]` fills the
`skill_invocations` tables. Until then, runs `--epistemic-only`.
