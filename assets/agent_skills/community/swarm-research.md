---
provider-specific: true
name: swarm-research
description: >
  Adaptive swarm research pattern (C+S+G notation). C canaries map territory,
  S swarm agents validate in parallel, G gap-finders/fillers guarantee coverage.
  Presets: compact (1+4+1=6), classic (1+9+1=11), evolved (3+9+3=15), maximal
  (10+10+10=30). Hard constraint: max(C,S,G) ≤ 10 (batch limit). Use when
  validating a large claim set across a broad surface area where breadth and
  depth both matter and gaps are unacceptable.
version: 0.3.0
status: tested
execution-mode: advisory
meta-skill: orchestrate
meta-skill-mode: invocation-time
meta-skill-topology: ladder
argument-hint: "[--pattern compact|classic|evolved|maximal|C+S+G] <claim-set or research topic>"
tags:
  - research
  - swarm
  - validation
  - parallel
  - canary
  - gap-filler
  - gap-finder
  - meta-skill
category: fleet-ops
---

# swarm-research

Adaptive parallel research pattern using **C+S+G notation**: **C canaries →
S swarm agents → G gap-finders/fillers**.

The canaries shape the swarm's tasks. The swarm validates in parallel. The
gap-finders/fillers catch what prior agents missed. This is not blind parallel
dispatch — it is canary-informed adaptive parallelism with a coverage guarantee.

**Lexicon**: This skill uses the canonical swarm lexicon defined in
`~/.agents/rules/swarm-lexicon.md`. All swarm-family skills share this
vocabulary.

## When to Use

- Validating a large set of claims (10+) across a broad surface area
- Researching a topic where both breadth AND depth matter
- When gaps are unacceptable (audit, compliance, due diligence)
- When you need the largest possible claim set validated in minimum time
- When a single agent would take too long and simple parallel dispatch would
  leave blind spots

## When NOT to Use

- Simple lookup questions (use a single agent)
- Claims that are sequential / dependent on each other
- Surface area too small to benefit from parallel agents
- Token budget cannot support the chosen pattern's agent count
- N < 5 independent dimensions → use `dispatch` or a fixed-N topology
  (dual-agent, tri-agent, quad-agent) instead

## The C+S+G Pattern

### General Form

A swarm pattern is written as `C+S+G` where:
- `C` = number of canaries (canary wave)
- `S` = number of swarm agents (swarm wave)
- `G` = number of gap-finders/fillers (gap wave)

**Hard constraint**: `max(C, S, G) ≤ 10` (the devin `subagent_general`
batch limit). No wave may exceed 10 simultaneous agents. If a wave needs
more than 10 agents, split it into multiple sequential batches within
the same wave.

### Presets

| Preset | Pattern | Total | When to use |
|--------|---------|-------|-------------|
| **compact** | 1+4+1 | 6 | Small surface (<20 claims), fast validation |
| **classic** | 1+9+1 | 11 | Medium surface (20-100 claims), the original |
| **evolved** | 3+9+3 | 15 | Large surface (100+ claims), 3 canaries reduce blind-spot risk, 3 gap agents ensure coverage |
| **maximal** | 10+10+10 | 30 | Exhaustive audit, missing anything is catastrophic |

**Default**: `evolved` (3+9+3). The operator's stated evolution target.

### Custom Patterns

Any `C+S+G` combination is valid as long as `max(C,S,G) ≤ 10`:
- `2+6+2` = 10 (balanced, moderate surface)
- `1+10+1` = 12 (swarm-heavy, broad validation)
- `3+3+3` = 9 (triadic, three-way cross-check at each wave)
- `5+5+5` = 15 (symmetric, equal investment per wave)

---

## The Three Waves

### Wave 1: Canary (C agents, 1 batch)

**Purpose**: Map the territory. Generate the largest possible set of claims
for the swarm to validate. Canaries do NOT go deep — they go wide.

**Multi-canary strategy** (C > 1): Each canary takes a different angle on
the territory. The orchestrator merges their maps into a unified scope set
before dispatching the swarm.

Common canary angle assignments:
- **C=1**: One canary maps everything (single map, single-point-of-failure for coverage)
- **C=2**: Canary A = filesystem/files, Canary B = code/content
- **C=3**: Canary A = filesystem, Canary B = codebase, Canary C = documentation/rules
- **C=5**: One canary per fleet surface (skills, rules, agents, docs, state)
- **C=10**: One canary per major directory tree (maximum breadth)

**Each canary's output**:
- Complete inventory of concepts/claims found
- File paths and source locations
- One-line description per concept
- Preliminary maturity assessment
- **Recommended research scopes for the swarm** — each non-overlapping
- Noted gaps/ambiguities for the gap-finders/fillers

**Profile**: `subagent_general` (full tool access for broad search)

**Key principle**: Be fast, be broad, be complete. Do not go deep — that's
the swarm's job. The canary's value is shaping the swarm's tasks so they
don't overlap and don't miss anything.

**Cross-check (C > 1)**: After all canaries complete, the orchestrator
merges their maps:
1. Deduplicate claims found by multiple canaries
2. Merge scope recommendations into a unified non-overlapping set
3. **Scope-disjointness check** (v0.3.0): Verify no item (skill, claim,
   concept) appears in more than one swarm scope. If an item appears in
   multiple scopes, assign it to exactly one and remove from the others.
   This prevents contradictory verdicts from different swarm agents on the
   same item. (Origin: AAR 2026-09-03 — eval-forge was assessed by both
   Swarm 4 and Swarm 6 with opposite verdicts because scope boundaries
   leaked.)
4. Identify any surface area that no canary covered (early gap detection)
5. If canaries disagree on scope boundaries, the orchestrator adjudicates

**Canary search strategy** (v0.3.0): Canaries should use BOTH:
- **Verb-based taxonomy**: search for known composition verbs (orchestrate,
  generate, validate, route, loop, manifest, dispatch) in descriptions
  and body text
- **Pattern-based text scan**: search for "composes", "chains", "invokes",
  "dispatches", "routes to", "wraps" in skill descriptions. This catches
  composition patterns that don't map to any known verb (e.g., "composes
  6 skills into a unified profile" is a composition pattern that the
  verb-based taxonomy missed in round 3).
  (Origin: AAR 2026-09-03 — 5 "discovery" skills missed because canary
  only searched for known verbs, not for the word "composes".)

### Wave 2: Swarm (S agents, 1 batch, fan topology)

**Purpose**: Deep validation of the claim set. Each agent takes one
non-overlapping scope and validates it exhaustively.

**Dispatch**: All S agents sent in parallel in a single message (S
`run_subagent` calls with `is_background=true`).

**Profile**: `subagent_general` (full tool access for deep research)

**Scope assignment**: The orchestrator assigns scopes based on the merged
canary map. The key constraints are:
1. **Non-overlapping** — no two agents research the same claim
2. **Complete coverage** — every claim from the canary map is assigned to
   exactly one swarm agent
3. **Maximum parallelism** — all S agents dispatched simultaneously

**The grid** (conceptual, not rigid):

For S=9 (classic/evolved), the 3x3 grid is a framing device:
```
           Axis A: Breadth          Axis B: Depth           Axis C: Cross-cutting
Team 1:    Agent 1 (scope 1)        Agent 2 (scope 2)        Agent 3 (scope 3)
Team 2:    Agent 4 (scope 4)        Agent 5 (scope 5)        Agent 6 (scope 6)
Team 3:    Agent 7 (scope 7)        Agent 8 (scope 8)        Agent 9 (scope 9)
```

For other S values, the grid is N×M or simply a flat list of S scopes.
The grid is a framing device, not a constraint. The canary map defines
the scopes based on what it finds.

**Each agent's output**:
- Per-claim verdict: VERIFIED / PARTIALLY VERIFIED / INVALIDATED / UNVERIFIABLE
- Source URL or file path + line references
- 1-2 sentence note per claim
- Any new claims discovered during validation (for the gap-finders/fillers)

**Rate limit note**: The batch limit is 10 concurrent subagents. S ≤ 10
fits within this limit. The canary wave completes before the swarm wave
dispatches, so at no point are more than 10 agents running simultaneously
(when waves are sequential).

### Wave 3: Gap (G agents, 1 batch)

**Purpose**: Catch what the C+S prior agents missed. Do exhaustive sweeps
with full breadth. Guarantee coverage.

**Multi-gap strategy** (G > 1): Each gap agent takes a different approach
to finding/filling holes:

- **G=1**: One gap-filler does an exhaustive sweep (single-point-of-failure for coverage guarantee)
- **G=2**: 1 gap-finder (diagnoses holes) + 1 gap-filler (fills holes)
- **G=3**: 1 gap-finder + 2 gap-fillers, OR 3 finder-fillers each sweeping a different surface
- **G=5**: 1 gap-finder + 4 gap-fillers, one per fleet surface
- **G=10**: Maximum gap coverage, one per major directory tree

**Gap-finder vs gap-filler** (distinct roles):
- **Gap-finder**: Identifies what's missing. Diagnostic. Outputs a list of holes.
- **Gap-filler**: Fills identified holes by doing the missing research. Execution. Outputs validated claims.

In compact patterns (G=1), the same agent does both. In evolved patterns
(G=3), the orchestrator may assign roles explicitly.

**Each gap agent's output**:
- Claims or concepts that were missed by all C+S prior agents
- Gaps in coverage (claims that were assigned but not fully validated)
- Cross-cutting patterns visible only when looking at all prior outputs together
- Final coverage assessment: what percentage of the total claim space was validated?

**Profile**: `subagent_general`

**Key principle**: Gap agents are not summary agents — they are
coverage-guarantee agents. Their job is to find holes, not to synthesize.
Synthesis is the orchestrator's job.

### Synthesis (orchestrator, not a subagent)

After all C+S+G agents complete, the orchestrator synthesizes:
- Aggregate verdicts across all claims
- Maturity ranking
- Cross-cutting patterns
- Recommendations
- Coverage assessment
- Swarm pattern assessment (did this pattern work for this task?)
- **Commit research artifacts** (v0.3.0): Write the synthesis to a durable
  file and commit it to git. Post a bus STATUS with the file path and key
  findings. This ensures the research survives the session and is visible
  to the fleet. (Origin: AAR 2026-09-03 — round 3 synthesis was left
  uncommitted; another agent had to commit it separately.)

For high-stakes synthesis, route through `[cross-agent]` as chief
synthesis officer (per poly-agent convention).

---

## Execution Checklist

```
[ ] 1. Select pattern (compact/classic/evolved/maximal/custom C+S+G)
[ ] 2. Dispatch C canaries (1 batch, background, subagent_general)
       — Canary instructions MUST include both verb-based and pattern-based
         text scan (v0.3.0)
[ ] 3. Wait for all canaries to complete (read_subagent with block=true, ×C)
[ ] 4. Read canary outputs — merge maps, deduplicate, assign S scopes
[ ] 5. SCOPE-DISJOINTNESS CHECK (v0.3.0): verify no item appears in >1 scope
[ ] 6. Dispatch S swarm agents (1 batch, all background, all subagent_general,
       each with a non-overlapping scope)
[ ] 7. Wait for all S to complete (read_subagent with block=true, ×S)
[ ] 8. Read all S outputs — collect findings + any new claims
[ ] 9. Dispatch G gap-finders/fillers (1 batch, background, subagent_general,
       with canary map + swarm outputs as context)
[ ] 10. Wait for all G to complete (read_subagent with block=true, ×G)
[ ] 11. Read all G outputs
[ ] 12. Synthesize all C+S+G outputs into final report
[ ] 13. Assess pattern fit (was this the right pattern for this task?)
[ ] 14. COMMIT research artifacts + post bus STATUS (v0.3.0)
```

---

## Token Budget

| Preset | Canary cost | Swarm cost | Gap cost | Total |
|--------|-------------|------------|----------|-------|
| compact (1+4+1) | Low | Medium | Low | ~6 agent-turns |
| classic (1+9+1) | Low | High | Medium | ~12-15 agent-turns |
| evolved (3+9+3) | Medium | High | Medium | ~18-22 agent-turns |
| maximal (10+10+10) | High | Very High | High | ~40-50 agent-turns |

---

## Why This Pattern Works

1. **Canary-informed**: The swarm doesn't research blindly. The canary/ies
   shape each agent's scope so they cover maximum surface area with zero
   overlap.

2. **Multi-canary robustness** (C > 1): Multiple canaries reduce the risk
   that a single canary's blind spots propagate to all swarm agents. Three
   maps from different angles are more complete than one.

3. **Parallel depth**: S agents going deep simultaneously means breadth
   (from the canaries) AND depth (from the swarm) in minimum wall-clock time.

4. **Coverage guarantee**: The gap wave exists specifically to find holes.
   Multiple gap agents (G > 1) reduce the risk that a single gap-filler
   shares the same blind spots as the prior agents.

5. **Within batch limits**: 10 concurrent subagent limit is never exceeded
   because waves are sequential and each wave is ≤ 10 agents.

6. **Adaptable**: The C+S+G notation scales from 6 agents (compact) to 30
   agents (maximal) without changing the pattern structure.

---

## Comparison to Alternatives

| Pattern | Agents | Breadth | Depth | Coverage | Speed | Blind-spot risk |
|---------|--------|---------|-------|----------|-------|-----------------|
| Single agent | 1 | Low | High | Unknown | Slow | High |
| Blind parallel (N agents) | N | High | Varies | Gaps likely | Fast | Medium |
| Sequential chain | N | Medium | High | Good | Slowest | Low |
| dispatch (≤5) | ≤5 | Medium | Medium | Medium | Fast | Medium |
| poly-agent (N≥5) | N≥5 | High | High | Good | Fast | Low |
| **swarm-research compact (1+4+1)** | 6 | Medium | Medium | Good | Fast | Medium |
| **swarm-research classic (1+9+1)** | 11 | High | High | Guaranteed | Fast | Low |
| **swarm-research evolved (3+9+3)** | 15 | Very High | High | Guaranteed | Fast | Very Low |
| **swarm-research maximal (10+10+10)** | 30 | Maximum | High | Guaranteed | Medium | Minimum |

---

## Pattern Selection Guide

```
How many claims to validate?
  ├─ <10: Use a single agent or dispatch (≤5)
  ├─ 10-20: compact (1+4+1) — 6 agents, fast
  ├─ 20-100: classic (1+9+1) — 11 agents, balanced
  ├─ 100-500: evolved (3+9+3) — 15 agents, robust
  └─ 500+: maximal (10+10+10) — 30 agents, exhaustive

How broad is the surface area?
  ├─ Single directory: compact
  ├─ Multiple directories: classic
  ├─ Entire fleet tree: evolved
  └─ Multiple repos + fleet: maximal

How critical is coverage?
  ├─ Missing some claims is OK: compact or classic
  ├─ Missing any claim is bad: classic or evolved
  └─ Missing any claim is catastrophic: evolved or maximal

Token budget constraints?
  ├─ Tight: compact (6 agents)
  ├─ Moderate: classic (11 agents) or evolved (15 agents)
  └─ Unlimited: maximal (30 agents)
```

---

## Example: Canvas of Canvases Validation (classic 1+9+1)

- Canary (1): Mapped 7 frameworks + 1 meta-framework → generated 7 research scopes
- Swarm (7 of 9 slots used): 7 agents validated each framework in parallel
- Gap-filler (1): Confirmed no additional frameworks were missed
- Result: All claims validated in ~5 minutes wall-clock time

## Example: "-of-" Meta-Composition Concepts (classic 1+9+1)

- Canary (1): Mapped 26 concepts, 9 scopes, 10 gaps
- Swarm (9): Validated all 26 concepts across 9 non-overlapping scopes
- Gap-filler (1): Found 25 additional concepts the canary + swarm missed
- Result: ~100 concepts validated in ~5 minutes wall-clock time
- Lesson: The gap-filler proved essential — without it, 25% of concepts
  would have been missed. This motivated the evolution to 3+9+3.

## Example: Meta-Skill Validation (evolved 3+9+3, first live test)

- **Canaries (3)**: A=self-declaration scan (5 found), B=composition pattern
  scan (~85 found), C=rules/docs definition scan (0 formal definitions found)
  → 3 maps merged into 9 disjoint scopes
- **Swarm (9)**: Each agent validated one scope category (DISPATCH,
  MANIFEST+ORCHESTRATE, GENERATE, VALIDATE×3, ROUTE+LOOP, self-decl gap,
  formal definition)
  → 35 TRUE_META, 12 BORDERLINE, 48 NOT_META (raw, pre-reconciliation)
- **Gap (3)**: 1 finder (7 contradictions, 15 missed skills, 7 double-counted)
  + 2 fillers (two-tier model + 43-skill deduplicated inventory)
  → All contradictions resolved by two-tier definition
- **Result**: 43 meta-level skills identified (31 Tier 1 + 12 Tier 2),
  formal two-tier definition produced, 7 contradictions resolved, 15
  missed skills caught by gap agents. Pattern assessed: 3+9+3 worked.
- **Lessons** (from AAR):
  - Scope boundaries leaked (eval-forge double-counted with opposite verdicts)
  - 15 skills missed by all 9 swarm scopes (caught by gap finder)
  - Gap fillers disagreed (resolved by synthesis)
  - No commit made (fixed in v0.3.0 by adding commit step)

---

## Related Skills

- `deep-research` — single-agent deep research (use for smaller scope)
- `research-pipeline` — 5-stage research pipeline (use for ongoing research)
- `poly-agent` — manifest-driven N-agent dispatch (use for non-research multi-agent tasks)
- `cross-agent` — chief synthesis officer (use for high-stakes synthesis)
- `dispatch` — decompose and dispatch ≤5 agents (use for small decomposable tasks)
- `swarm` — machine-level fan-out via SSH (use for cross-machine parallelism)
- `swarm-manifest` — pre-flight manifest generation (use before any swarm)
- `cross-check-protocol` — cross-agent validation protocol
- `evidence-grade` — evidence quality grading

## Lexicon

This skill uses the canonical swarm lexicon (`~/.agents/rules/swarm-lexicon.md`).
Key terms: swarm, wave, batch, team, lane, canary, swarm agent, gap-finder,
gap-filler, orchestrator, synthesis officer, batch limit, coverage guarantee.

## Base120 Alignment

- **SY1 (Leverage Points)**: The canaries are the leverage point — small input,
  large output (shapes all S swarm tasks)
- **CO3 (Functional Composition)**: canary wave → swarm wave → gap wave is a
  typed composition chain
- **DE2 (Factorization)**: The S scopes are a factorization of the claim
  space — non-overlapping, complete
- **IN3 (Problem Reversal)**: The gap-finder inverts the question — instead
  of "what did we find?" it asks "what did we miss?"
- **P1 (First Principles)**: Coverage guarantee is the first principle —
  the pattern exists to ensure no claim is left unvalidated
- **CO13 (Multi-Agent Coordination)**: The C+S+G pattern is a typed
  multi-agent coordination structure with explicit wave boundaries

## Subagent Profile Policy

All canary, swarm, and gap-finder/filler agents MUST use
`profile="subagent_general"` per `~/.agents/rules/devin-subagent-profile-policy.md`.
No paid-profile dispatches without explicit operator approval.

## Skill Chains

### Mandatory (MUST pass before dispatch)
- **Pattern selection**: Orchestrator must declare the C+S+G pattern before dispatch
- **Scope non-overlap**: Orchestrator must verify no two swarm agents share a scope

### Advisory
- Before swarm-research → `swarm-manifest` for pre-flight capacity check (optional for compact, recommended for evolved+)
- After synthesis → `ledger` the findings with swarm-research evidence
- After first run with a new pattern → `aar` on pattern fit (did this C+S+G work for this task?)
- For high-stakes synthesis → `cross-agent` as chief synthesis officer

## Authority

- **T1+ (Principal AI Agent)**: May dispatch any C+S+G pattern
- **T2 (Active/High)**: May dispatch compact or classic with operator notification
- **T3 (Medium)**: May dispatch compact only, operator approval for classic+
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill (multi-agent dispatch)
- **Operator**: Override any restriction — swarm-research is advisory until human ACKs

## Version History

- **v0.3.0** (2026-09-03): First live test of evolved (3+9+3) pattern. Added scope-disjointness check (step 5 in checklist). Added pattern-based text scan to canary instructions ("composes", "chains", "invokes"). Added commit + bus STATUS step to synthesis phase. Added meta-skill frontmatter (orchestrate / invocation-time / ladder). Updated example with real 3+9+3 data from meta-skill validation run.
- **v0.2.0** (2026-09-03): Adaptable C+S+G pattern. Presets (compact/classic/evolved/maximal). Multi-canary and multi-gap support. Swarm lexicon integration. Gap-finder vs gap-filler distinction. Pattern selection guide.
- **v0.1.0** (2026-09-03): Initial 1+9+1 pattern. First live execution validated ~100 "-of-" concepts.
