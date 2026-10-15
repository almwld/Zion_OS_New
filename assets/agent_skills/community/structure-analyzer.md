---
name: structure-analyzer
description: "Classify a fleet governance structure against the 10 archetypes from composition-doctrine.md. Identifies primary archetype, hybrids, and failure modes. Produces a classification receipt with doctrine citations."
version: 0.1.0
execution-mode: advisory
argument-hint: "<rule-or-doc-path | inline structural description>"
category: governance-compliance
status: candidate
---

# Structure Analyzer

Classify a fleet governance structure against the canonical archetypes from
`~/.agents/rules/composition-doctrine.md`. Produce a classification receipt
with evidence, failure modes, and doctrine citations.

## When to invoke

- When you need to classify a governance pattern, rule, or protocol by its structure
- When designing a new rule/skill and want to name its structure precisely
- When a bus break occurs and you need to name which layer/structure failed
- When reviewing whether a pattern is over- or under-engineered for its structure
- When the operator asks "what structure is this?" or "is this a lattice?"

## What this skill does

1. Reads the target structure (from a file path or an inline description)
2. Runs the classification decision flow (§ Classification Flow below)
3. Identifies the primary archetype, any secondary archetype (hybrid), and the composition
4. Maps to failure modes from the doctrine
5. Produces a classification receipt (§ Output Format)
6. Flags open questions if the archetype is provisional or has a thin boundary

## What this skill does NOT do

- Does NOT force a label. "Ambiguous," "hybrid," and "insufficient evidence" are valid outputs (doctrine §5.4).
- Does NOT classify "lattice" — that term is REJECTED (doctrine §3.1). If the input suggests "lattice," redirect to the actual archetype.
- Does NOT override the doctrine. The doctrine is canonical; this skill operationalizes it.
- Does NOT introduce new archetypes. If a pattern fits none, output "insufficient evidence" and recommend returning to evidence gathering (doctrine §5.2).

## Classification Flow

Run these checks in order. The first match is the primary archetype. If a
structure matches multiple, it is a **hybrid** — declare the composition
explicitly (doctrine §5.2). A pattern that cannot be stated as a combination
of named archetypes is either under-analyzed or needs a new archetype.

### Step 1 — Feedback path?

Does the output of one iteration feed the input of the next? Is there a
defined iteration cycle where downstream outcomes alter subsequent inputs?

- **Yes** → **Loop** (doctrine §2.2)
  - Failure mode: stall handling. Operator-paced loops stall → halt + STATUS. Machine-paced loops use wakeups. An operator-paced loop that proceeds after a stall is a bug.
  - Sub-check: is there a defined timeout/halt? If not, flag as gap.

### Step 2 — Ordered levels with directional progression?

Are there levels/states with a defined successor and predecessor? Is
progression directional (you move from one level to the next)?

- **Yes, and it's a total or partial order** → **Ladder** (doctrine §2.1)
  - Failure mode: classification disagreement at subjective boundaries (e.g., P1/P2). Recommend meta-review if classification has consequences (merge gates, promotion).
- **Yes, and data flows through stages as checkpoints (classification vs processing)** → also consider **Pipeline** (doctrine §2.7). The boundary is thin — see Step 7.

### Step 3 — Transition graph, event-driven, non-linear?

Is it a directed graph (possibly cyclic) where nodes are states and edges are
valid transitions? Multiple paths between states? Event-driven rather than
a defined iteration cycle?

- **Yes** → **State machine** (doctrine §2.3)
  - Distinguished from a loop: a loop has a defined iteration cycle; a state machine has event-driven transitions.
  - Distinguished from a ladder: a ladder has linear ordering; a state machine has multiple paths.

### Step 4 — Parallel co-existing perspectives on one domain?

Are there layers that are NOT ordered (one is not "above" another), NOT
alternatives (they co-exist), each with its own enforcement and failure mode?

- **Yes** → **Layered model** (doctrine §2.4 — **PROVISIONAL**)
  - Flag: this archetype has only one confirmed instance (the 3-layer vocabulary/lexicon/vernacular model). It is provisional. Recommend finding a second instance before relying on this classification.
  - Failure mode: silent failure at the lexicon layer (the lethal one — same token, different mental models, both passing checks).

### Step 5 — Ordered alternatives with a terminal state?

Is there an ordered list of alternatives tried in sequence, with a defined
terminal state (BLOCKED with evidence, or equivalent) when all are exhausted?

- **Yes, with a defined terminal state** → **Fallback chain** (doctrine §2.5)
  - The defined terminal state is a strength. If the structure lacks a terminal state, flag as gap (it degenerates into an unbounded list).
- **Yes, but elements are unranked / non-exclusive** → go to Step 6 (Heterarchy).

### Step 6 — Unranked elements, non-exclusive combination?

Are elements unranked or rankable in multiple ways? Selectable in non-exclusive
combinations?

- **Yes** → **Heterarchy** (doctrine §2.6)
  - Failure mode: combination guidance gap. If the selection rubric maps each task to ONE pattern but the structure permits combination, flag the gap. Recommend adding combination guidance.

### Step 7 — Sequential one-directional processing through stages?

Does data flow in one direction through stages, each a checkpoint, with no
feedback and no branching?

- **Yes** → **Pipeline** (doctrine §2.7)
  - **Boundary with ladder is thin.** A ladder classifies (you place something at a level); a pipeline processes (something flows through stages). If the distinction is unclear, flag as ambiguous and note the boundary may collapse in a future revision.
  - If all stages are visited (no branching) → pipeline. If stages can be skipped/branched → decision tree (Step 10).

### Step 8 — One-to-many parallel broadcast?

One input → multiple parallel outputs, no ordering between outputs, no feedback?

- **Yes** → **Fan-out** (doctrine §2.8)
  - Distinguished from a DAG: fan-out is one-to-many with no ordering; a DAG has directional advisory edges.

### Step 9 — Directed acyclic graph, advisory edges?

Edges represent advisory or mandatory relations. Multiple edges can leave a
node with equal weight (no priority ordering). Edges are directional. No
cycles. No joins/meets.

- **Yes** → **DAG** (doctrine §2.9)
  - Distinguished from heterarchy: DAG edges are directional; heterarchy elements are unranked.
  - Distinguished from fallback chain: DAG has no priority ordering.
  - If the structure has joins/meets, do NOT call it a lattice — re-examine. The "lattice" label is rejected (doctrine §3.1).

### Step 10 — Conditional branching, tree structure?

Conditions at each node determine which branch to follow. Each path leads to
one outcome. Tree structure (each node has one parent).

- **Yes** → **Decision tree** (doctrine §2.10)
  - Distinguished from fallback chain: branches are conditional, not prioritized.
  - Distinguished from pipeline: not all stages are visited.
  - Distinguished from DAG: tree structure, one parent per node.
  - Note: a decision tree with a fallback chain at a terminal branch is a well-formed hybrid (doctrine §4.4).

### Step 11 — No match?

If no archetype fits cleanly:
- Output "ambiguous" or "insufficient evidence" (doctrine §5.4).
- Do NOT force a label.
- Recommend: either gather more evidence, or propose a new archetype (with a structural definition and receipt) per doctrine §5.2.

## Lattice rejection check

If the input or your analysis suggests "lattice" as a classification:

1. **Stop.** "Lattice" is REJECTED (doctrine §3.1). 7 multi-path structures were checked; 0 non-trivial lattices found. The formalism has no operational meaning in fleet context.
2. Re-run the classification flow. The structure is almost certainly a DAG, decision tree, heterarchy, or fan-out — all of which are more precise.
3. If the structure is a total order (trivially a lattice), call it a **ladder** or **fallback chain** — the lattice label adds nothing.

## Hybrid detection

If a structure matches multiple archetypes:

1. Declare the composition explicitly: "X is a [archetype A] gated by [archetype B]" or "X is a [archetype A] with a [archetype B] at its terminal branch."
2. "It's sort of everything" is not valid (doctrine §5.2). If you cannot state the composition as a combination of named archetypes, the pattern is under-analyzed.
3. Document the composition in the receipt.

Known hybrids from the doctrine (§4):
- **Ladder + Loop**: Candidate promotion (ladder gated by a loop — citations accumulate before the ladder advances)
- **Bidirectional + Loop**: Steward↔Engineer cross-check
- **Ladder × Ladder**: Severity × gate mapping (GAP: conflicting severities — higher severity governs unless operator waives)
- **Decision tree + Fallback chain**: Team dispatch (decision tree with fallback chain at the "no match" branch)

## Output Format

Produce a classification receipt in this structure:

```
## Structure Classification Receipt

**Target**: <file path or description>
**Primary archetype**: <archetype name> (doctrine §<ref>)
**Secondary archetype**: <archetype name or "none"> (doctrine §<ref>) [if hybrid]
**Composition**: <explicit composition statement> [if hybrid]

### Evidence
- <structural feature observed> → <which archetype criterion it satisfies>
- ...

### Failure modes
- <archetype>: <failure mode from doctrine>
- ...

### Open questions flagged
- [ ] Provisional archetype (only if layered model) — single instance, recommend finding a second
- [ ] Thin boundary (only if pipeline/ladder) — may merge in future revision
- [ ] Combination guidance gap (only if heterarchy) — recommend adding combination guidance to rubric
- [ ] Conflict resolution gap (only if ladder × ladder hybrid) — higher severity governs unless operator waives
- [ ] DAG/heterarchy distinctness (only if ambiguous between the two)
- [ ] Decision-tree/fallback-chain distinctness (only if ambiguous between the two)
- [ ] None

### Lattice check
- "Lattice" proposed: <yes/no>
- If yes: redirected to <actual archetype> per doctrine §3.1

### Doctrine citation
- Classification based on: ~/.agents/rules/composition-doctrine.md v0.2 (canonical, promoted 2026-08-17)
- Archetype definition: §<ref>
- Failure mode: §<ref>
```

## Self-consistency check

After classifying, verify:
1. Does the classification cite a doctrine § reference for each archetype? (honesty-first constraint)
2. If hybrid, is the composition stated as a combination of named archetypes? (doctrine §5.2)
3. If "lattice" was considered, was it rejected and redirected? (doctrine §3.1)
4. Are open questions flagged honestly rather than papered over? (doctrine §5.4)
5. Is the evidence specific to the target structure, not generic?

If any check fails, revise the classification before emitting the receipt.

## Related

- `~/.agents/rules/composition-doctrine.md` — the canonical doctrine this skill operationalizes
- `~/.agents/rules/cross-check-protocol.md` — fallback chain archetype source
- `~/.agents/rules/admission-gate-doctrine.md` — pipeline archetype source
- `~/.agents/rules/apex-nexus-composition.md` — heterarchy archetype source
- `~/.agents/rules/skill-chains.md` — DAG archetype source
- `~/.agents/rules/scheduled-work-route-selection.md` — decision tree archetype source
- `~/.agents/_staging/bus-terminology-layers.md` — layered model archetype source (provisional, unratified)
