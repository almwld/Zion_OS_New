---
name: uncertainty-map
description: "Map a decision, project, incident, or strategy into knowns, unknowns, blind spots, assumptions, discovery agenda, intel gaps, and risk-of-surprise."
version: 0.1.0
execution-mode: advisory
argument-hint: "\"<topic>\" [--sources bus|repo|web|all] [--horizon immediate|near|strategic]"
category: governance-compliance
status: candidate
---
# Uncertainty Map

Map epistemic state before action. This skill is complementary to `knowledge-map`: use
`knowledge-map` for who-knows-what and bus-factor risk; use `uncertainty-map` for what is
known, unknown, latent, and surprising about a decision or situation.

## When To Use

- The user asks for known knowns / known unknowns / unknown knowns / unknown unknowns.
- The user asks for a knowledge map but means uncertainty, blind spots, assumptions, or discovery agenda.
- The work is consequential and hidden assumptions could change the decision.
- A fleet, PR queue, research lane, governance artifact, incident, or strategy needs a compact orientation map.
- You need to convert intel into next research, validation, or review tasks.

## Core Quadrants

| Quadrant | Meaning | Typical Evidence | Action |
|---|---|---|---|
| Known knowns | We know it, and know that we know it. | Verified source, passing test, current bus receipt, committed artifact, primary-source citation. | Use as decision foundation; cite receipts. |
| Known unknowns | We know the gap exists. | Open question, pending CI, unresolved review finding, missing source, unrun test. | Assign owner, method, deadline, and stop condition. |
| Unknown knowns | The system already has the knowledge, but it is not surfaced, canonicalized, or connected to this decision. | Stashes, parked branches, old docs, bus history, tacit agent practice, unindexed memory, local-only artifacts. | Surface, reconcile, promote, or explicitly discard. |
| Unknown unknowns | Surprise space: we do not know the gap exists yet. | Inferred from complexity, novel threat class, weak coverage, fast-changing standards, untested interactions. | Add probes, adversarial review, monitors, canaries, and revisit triggers. |

## Intel Intake

Use the lightest evidence pass that fits the stakes:

1. **Local/repo state**: branch, dirty tree, open PRs, tests, docs, schemas, issue state.
2. **Bus/ledger state**: recent decisions, blockers, review receipts, active lanes, stale assumptions.
3. **External sources**: primary or authoritative sources for changing standards, security guidance, laws, product behavior, or public claims.
4. **Tacit/local artifacts**: archives, stashes, parked branches, `_internal/`, generated reports, old runbooks, memory pointers.

If a source is not checked in the current turn, mark it `unverified-current` rather than presenting it as live fact.

## Procedure

1. Define the decision boundary: topic, time horizon, audience, and what action the map should inform.
2. Gather receipts appropriate to the stakes. Prefer current repo/bus state and primary sources.
3. Fill each quadrant with short, testable claims. Avoid vague nouns like "governance" without a concrete object.
4. Attach confidence and evidence status:
   - `verified-current`: checked in this turn.
   - `memory-derived`: from prior memory or older note.
   - `inferred`: reasoned from evidence but not directly observed.
   - `unverified`: plausible but not checked.
5. Convert each non-known-known into an action:
   - Known unknown -> research/test/review task.
   - Unknown known -> retrieval/reconciliation/canonicalization task.
   - Unknown unknown -> probe/monitor/wargame/red-team task.
6. End with the bottom line: what is safe to act on now, what must wait, and what would most reduce uncertainty.

## Output Format

```markdown
Uncertainty Map | <topic> | <horizon>
================================================

## Bottom Line
- <what is safe to act on now>
- <what must wait>
- <highest-leverage uncertainty reduction>

## Matrix
| Quadrant | Item | Evidence | Confidence | Action |
|---|---|---|---|---|
| Known known | <claim> | <receipt/source> | High | <use/maintain> |
| Known unknown | <gap> | <why known> | Med | <owner/method/stop> |
| Unknown known | <latent knowledge> | <where likely hidden> | Med | <surface/reconcile> |
| Unknown unknown | <surprise class> | <why plausible> | Low | <probe/monitor> |

## Immediate Actions
1. <action> -- addresses: <quadrant/item>
2. <action> -- addresses: <quadrant/item>

## Watch Triggers
- Re-run this map if <condition changes>.
```

## Quality Bar

- Do not use the four quadrants as decoration. Every row should change what the operator does next.
- Distinguish "unknown because not checked" from "unknown because unknowable right now."
- Treat unknown knowns as retrieval work, not speculation: name the archive, branch, person, bus lane, or habit where the latent knowledge may live.
- Treat unknown unknowns as a probe design problem. Add sensors or adversarial checks instead of pretending to enumerate all surprises.
- If current facts may have drifted, verify them before using them as known knowns.

## Skill Chains

| Before / After | Consider |
|---|---|
| Need who-knows-what / bus factor | `knowledge-map` |
| Need current source research | `deep-research`, `web-research`, `research-digest` |
| Need adversarial surprise discovery | `wargame`, `redline`, `threat-model` |
| Need persistent risk tracking | `risk-register` |
| Need evidence bundle | `evidence-pack` |
