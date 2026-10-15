---
provider-specific: true
name: explore-mode
description: Canary-first swarm exploration for Phase -1 Discovery. 1 canary maps territory, then N swarm agents (max 10) deep-dive non-overlapping scopes in parallel. Lightweight alternative to swarm-research when you need fast breadth+depth without the gap wave.
version: 0.2.0
execution-mode: advisory
argument-hint: "\"<topic, question, or surface to explore>\" [--swarm N] [--canary-angle <angle>] [--output <path>]"
category: fleet-ops
status: candidate
---
# Explore Mode

Canary-first swarm exploration. One canary maps the territory, then N swarm
agents (max 10) deep-dive non-overlapping scopes in parallel. Designed for
Phase -1 Discovery in LLL Engineering — the moment before you know enough to
plan, when you need to map what exists fast.

This is `swarm-research` with the gap wave stripped out. Simpler, cheaper,
faster. Use when you need breadth + depth but can tolerate some coverage gaps.

## When to Use

- Phase -1 Discovery: "what exists in this surface area?"
- Before a design decision: "what are the moving parts here?"
- When a single agent would take too long but full swarm-research is overkill
- When you need to map a codebase, topic, or system fast
- Operator says "explore", "map this", "what's out there", "recon"

## When NOT to Use

- Simple lookup → single agent
- Audit / compliance (gaps unacceptable) → `swarm-research` (has gap wave)
- N < 3 scopes after canary → just do the canary, skip the swarm
- Sequential / dependent claims → `poly-agent` ladder topology
- N > 10 scopes → `swarm-research` evolved/maximal pattern

## The 1 → N Pattern

```
Wave 1: 1 canary  →  maps territory, produces scope set
         │
         ▼
Wave 2: N swarm   →  each takes 1 non-overlapping scope, deep-dive
  (max 10)         │
                   ▼
         Orchestrator synthesizes
```

**Hard constraints**:
- N ≤ 10 total swarm agents
- **Max 5 concurrent subagents** (runtime limit). If N > 5, dispatch in waves of 5, reusing slots as agents complete. The 2-wave pattern (5 + 5) adds ~20 min latency vs a single batch but does not affect quality.
- **Profile**: `subagent_general` for all agents (operator directive — free tier only).

## Execution

### Step 1 — Dispatch 1 canary (background, subagent_general)

The canary's job is **breadth, not depth**. It maps the full territory and
produces a scope set for the swarm.

Canary prompt template:
```
You are a CANARY agent mapping territory for a swarm exploration.

Topic/surface: <TOPIC>

Your job: go WIDE, not deep. Produce:
1. Complete inventory of what exists in this surface area
2. File paths, URLs, or source locations
3. One-line description per item found
4. Recommended research scopes for the swarm — each NON-OVERLAPPING
5. Noted gaps/ambiguities

Do NOT go deep on any single item. That's the swarm's job.
Be fast, be broad, be complete.

Use both verb-based search AND pattern-based text scan:
- Search for known verbs (orchestrate, generate, validate, route, etc.)
- Search for composition patterns ("composes", "chains", "invokes", "wraps")
```

Wait for canary to complete (`read_subagent` with `block=true`).

### Step 2 — Read canary output, assign scopes

1. Read the canary's scope recommendations
2. **Scope-disjointness check (mechanical)**: write the canary inventory and
   scope globs to `plan.json` (`{"universe": [paths], "scopes": {name: [globs]}}`)
   and run `python scripts/explore_mode.py scope-check --plan plan.json`.
   Exit 1 lists gaps and overlaps; fix them before dispatch. (Origin: the
   2026-09-03 swarm missed 15 items and double-counted 7 without this check.)
3. If scopes overlap, assign each item to exactly one scope
4. If N < 3 scopes → skip the swarm, synthesize from canary alone
5. If N > 10 scopes → merge related scopes until N ≤ 10
6. Default N = canary's recommended scope count (capped at 10)
7. Operator can override with `--swarm N`

### Step 3 — Dispatch N swarm agents (background, wave-based if N > 5)

All N agents dispatched with `is_background=true`, `profile="subagent_general"`.

**If N ≤ 5**: dispatch all N in a single message (N `run_subagent` calls).

**If N > 5**: dispatch in waves of 5. Wave 1 = first 5 agents. As wave-1 agents
complete (check via `read_subagent`), dispatch wave-2 agents into freed slots.
The 2-wave pattern (5 + 5) is the default for N = 10.

Each agent gets one non-overlapping scope from the canary map.

Swarm agent prompt template:
```
You are a SWARM agent doing a deep-dive on one scope.

Scope: <SCOPE_DESCRIPTION>
Context from canary: <RELEVANT_CANARY_OUTPUT>

Your job: go DEEP on this scope. For each item in your scope:
1. Read the actual files / sources (do not trust the canary's summary)
2. Produce a verdict: EXISTS / PARTIALLY_EXISTS / DOES_NOT_EXIST / STALE
3. Note key details: what it does, how it works, dependencies
4. Flag anything the canary missed in your scope
5. Note cross-cutting patterns visible from your scope

Output: per-item findings + scope summary.
Write findings as JSONL to `_state/explore/sidecar-<scope>.jsonl`, one row per claim:
  {"scope", "claim_id", "finding", "evidence", "severity"}   (severity: info|low|warn|medium|high|critical)
Also emit research rows when you meet them:
  {"kind": "open_question", "scope", "claim_id", "question", "why_it_matters", "evidence_needed", "papers": []}
  {"kind": "conjecture", "scope", "claim_id", "claim", "observations", "falsification", "confidence", "class": "[INF]"}
Never overwrite another scope's sidecar or the merged ledger.
```

Read-only children cannot write files; the orchestrator writes their sidecar
from the completion report.

### Step 4 — Collect and synthesize

Wait for all N agents to complete. Merge mechanically first:

```
python scripts/explore_mode.py merge --dir _state/explore --ledger _state/explore/ledger.jsonl --dry-run
python scripts/explore_mode.py merge --dir _state/explore --ledger _state/explore/ledger.jsonl
```

Exit 1 means invalid rows or severity conflicts; resolve those in the synthesis.
The ledger is append-only. Conjectures stay `[INF]` until R1 provenance plus
non-author review. Optional last step for high-stakes maps: HUAOMP-Absolute set
ops + MTSMU verification (`rules/apex-nexus-composition.md` Pattern C).

Then synthesize:
- Aggregate findings across all scopes
- Cross-cutting patterns
- Coverage assessment (what % of territory was mapped?)
- Key discoveries / surprises
- Recommended next actions

### Step 5 — Output

Present synthesis to operator. If `--output` specified, write to file.

## Output Format

```
Explore Mode | <topic> | 1 canary + N swarm
═══════════════════════════════════════════════

## Canary Map
- Items found: <count>
- Scopes identified: <count>
- Gaps noted: <list>

## Swarm Results
| Scope | Agent | Items | Key Finding |
|-------|-------|-------|-------------|
| <scope> | swarm-N | <count> | <one-line> |

## Synthesis
- Coverage: <X>% of territory mapped
- Cross-cutting patterns: <list>
- Key discoveries: <list>
- Surprises / anomalies: <list>

## Recommended Next Actions
1. <action>
2. <action>
3. <action>
```

## Presets

| Preset | Pattern | When |
|--------|---------|------|
| **minimal** | 1→3 | Small surface, fast recon |
| **standard** | 1→5 | Medium surface (default) |
| **wide** | 1→10 | Large surface, max parallelism |

Default: **standard** (1→5). Operator can override with `--swarm N`.

## Cost Discipline

- Devin runtime: all agents use `profile="subagent_general"` (GLM-5.2 High, free tier)
- Claude Code runtime: canary and swarm use the `Explore` agent type (read-only;
  orchestrator reconstructs sidecars); batches of 5 or fewer. Merge and
  verification run on the lead session. Routing roles: `registry/providers.yaml`.
- Never use named persona profiles — persona lives in the prompt, not the profile
- 1 canary + N swarm = N+1 total dispatches (max 11)
- If quota is tight, reduce N or skip the swarm (canary alone is still useful)

## Bus Discipline

Any Explore Mode run that dispatches subagents MUST post to the coordination bus:

1. **STATUS at dispatch** — post a STATUS when the swarm is dispatched, noting
   the scope count, agent profile, and expected duration. This gives the fleet
   visibility into concurrent subagent slot consumption.
2. **SITREP at completion** — post a SITREP when synthesis is complete, noting
   the key finding and recommended next action. If the run produces an AAR with
   Improves > 0, the AAR's mandatory SITREP satisfies this requirement.

Rationale: a research operation consuming 5-11 subagent slots for 20-30 minutes
is fleet-visible activity. Without bus posts, other agents have no visibility
into the slot consumption or the research outcome.

Form (canonical identity, host tag first):
```
<ts>	devin	all	STATUS	host=<machine> Explore Mode: <topic> — <N> swarm agents dispatched, <N> non-overlapping scopes
<ts>	devin	all	SITREP	host=<machine> Explore Mode: <topic> — <1-line key finding> + <1-line top recommendation>
```

## Relationship to Other Skills

| Skill | Pattern | When to prefer |
|-------|---------|----------------|
| `explore-mode` | 1→N (no gap) | Fast discovery, tolerates some gaps |
| `swarm-research` | C+S+G (with gap) | Audit, compliance, gaps unacceptable |
| `poly-agent` | Manifest-driven N-agent | Complex topologies, multi-round |
| `intel-ingest` | Single ingest | Persisting findings after exploration |
| `novelty-surge` | Surge + reframe | External intel + divergent hypotheses |

## Skill Chains

| After completing... | Consider... |
|---------------------|-------------|
| `explore-mode` with significant findings | `intel-ingest` to persist findings |
| `explore-mode` for a design decision | `arcana-review` to pressure-test the design |
| `explore-mode` surfaces gaps needing full audit | `swarm-research` (adds gap wave) |
| `explore-mode` in Phase -1 Discovery | `seshat` to open the next phase with state |

## Base120 Context

- Primary: **IN6** (Exploration) — canary-first breadth-then-depth
- Related: **SY8** (Feedback Loops) — canary output shapes swarm scope
- Related: **DE3** (Categorization) — scope-disjointness check

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction
- **T3 (Medium)**: May run with operator notification
- **T4 (Probationary)**: May run with operator approval
- **Operator**: Override any restriction
