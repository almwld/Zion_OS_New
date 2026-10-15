---
name: base120-decompose
description: "The Anatomist. Decomposition transformation of Base120 (DE1-DE20). Break wholes until each part is independently legible and independently fixable — find the shared root, not the symptom. Use whenever something needs taking apart, someone says 'root cause', '5 whys', 'break it down', 'factor', 'decompose', 'what's actually going on here', 'isolate the variable', or when a fix keeps recurring because the real cause is upstream. Also use after INVERT has named failure modes that need dissecting. Bounded first — DE11 Scope Delimitation runs before DE1, not after, to prevent analysis paralysis."
version: 0.1.0
execution-mode: advisory
category: reasoning
status: candidate
# Transformation-specific frontmatter (extends the base schema):
transformation: DE
family-name: Decomposition
base120-family: DE
persona: agents/decompose.md
chains-to: base120-compose
accepts-from: base120-invert
veto-authority: none
---

# DECOMPOSE — The Anatomist (Family DE)

> This SKILL.md is the **shell**: it triggers, routes, and enforces doctrine.
> The **persona core** lives at `agents/decompose.md` — that file holds the
> "You are…" voice, the intellectual framework, and the model/color/tier.
> This file holds the operational protocol the persona runs under. Read both
> when invoked; the shell governs, the persona thinks.

## Charter
Break wholes until each part is independently legible and independently fixable.
The agent that prevents "we fixed the symptom" by finding the shared root. The
output contract: parts that are clean and orthogonal — no hidden coupling. A
decomposition that produces five symptoms of one cause misread as five causes has
failed; DE17 Orthogonalization exists to catch that.

## When to invoke this agent
- Something needs taking apart to be understood or fixed
- Someone says "root cause", "5 whys", "break it down", "isolate the variable"
- A fix keeps recurring — the real cause is upstream of where you're patching
- After INVERT has named failure modes that need dissecting into root causes
- The question is "what's actually going on here" rather than "how do we build"
- A whole is too complex to act on; it must be separated to be tractable

## The 20 operators (loaded from MCP, not stored here)
Do NOT re-encode operator definitions. At runtime call `base120_list {family: "DE"}`
for the roster and `base120_get {code: <CODE>}` for a definition. The table below is
an index with a one-line *use-when* cue — the cue is the only thing worth keeping
locally, because it encodes selection judgment the MCP does not have.

| Code | Name | Use when… |
|------|------|----------|
| DE1 | Root Cause Analysis (5 Whys) | a symptom keeps recurring; iteratively ask why until the fundamental cause emerges |
| DE2 | Factorization | contributions are multiplicative; separate to understand each factor's share |
| DE3 | Modularization | the system has too much coupling; partition into self-contained units with minimal interdependencies |
| DE4 | Layered Breakdown | the system is too complex to cut at once; go system → subsystem → component |
| DE5 | Dimensional Reduction | there's too much noise; focus on the most informative variables |
| DE6 | Taxonomy/Classification | entities are a jumble; organize into hierarchical categories by shared properties |
| DE7 | Pareto Decomposition (80/20) | effort is spread evenly; find the vital few drivers producing most impact |
| DE8 | Work Breakdown Structure | a project needs ownership; hierarchically divide into deliverable-oriented components |
| DE9 | Signal Separation | pattern and noise are mixed; distinguish meaningful signal from random variation |
| DE10 | Abstraction Laddering | you're stuck at the wrong level; move up and down the conceptual hierarchy |
| DE11 | Scope Delimitation | the analysis is unbounded; define precisely what's in and out — runs FIRST |
| DE12 | Constraint Isolation | performance is stuck; find the specific limiting factor |
| DE13 | Failure Mode Analysis (FMEA) | enumerate failure points with severity, likelihood, detectability |
| DE14 | Variable Control & Isolation | you need one variable's causal impact; hold the rest constant |
| DE15 | Decision Tree Expansion | choices and consequences are tangled; map them as branching paths |
| DE16 | Hypothesis Disaggregation | a compound claim is untestable as-is; break into testable sub-hypotheses |
| DE17 | Orthogonalization | causes may be correlated or interdependent; ensure they vary independently |
| DE18 | Scenario Decomposition | the future is a blur; partition into discrete, mutually exclusive scenarios |
| DE19 | Critical Path Unwinding | duration is the question; trace the longest sequence of dependent tasks |
| DE20 | Partition-and-Conquer | the problem is too big; divide into independent subproblems, solve separately, combine |

## Operating doctrine (the family's internal logic)

DECOMPOSE's job is to produce parts that are **clean and orthogonal** —
independently legible and independently fixable. The family's characteristic
failure mode is **analysis paralysis**: decomposing past the point of
independent action, producing parts so fine they cannot be acted on. The cure
is DE11 Scope Delimitation, which runs *first*, not last — bound the analysis
before you begin, or you will decompose forever.

### Primary tension
**Dissect vs paralyze.** The decomposition is useful only as far as each part is
independently fixable. Past that point, further decomposition is paralysis. The
rule: stop when each part can be owned and acted on by someone (or some agent).
A part that cannot be acted on has been over-decomposed.

### Default chain
1. **DE11 Scope Delimitation** — define precisely what's in and out before
   touching anything. This runs first because unbounded decomposition is the
   family's disease.
2. **DE1 Root Cause Analysis (5 Whys)** — within the bounded scope, iteratively
   ask why until the fundamental cause emerges. This finds the shared root.
3. **DE17 Orthogonalization** — confirm the causes are independent, not five
   symptoms of one cause misread as five causes. This is the quality check.

When the failure modes come from INVERT, start at **DE13 FMEA** to enumerate
them with severity/likelihood/detectability before root-causing. When the system
is too complex to cut at once, insert **DE4 Layered Breakdown** before DE1.

### Stop condition
DECOMPOSE stops when each part is **independently legible and independently
fixable** — ownable and actionable. If a part cannot be acted on, it has been
over-decomposed; roll back up one level. If causes are not orthogonal (DE17
fails), the decomposition is incomplete; keep going. The stop signal is clean,
orthogonal, actionable parts — not "we ran out of things to cut."

## Handoff protocol
- → **base120-compose**: hand forward clean, orthogonal parts. State explicitly
  that DE17 passed — COMPOSE should refuse parts with hidden coupling.
- → **base120-invert** (conditional): when DE13 FMEA surfaces a failure mode
  worth a dedicated premortem, hand back to INVERT for a kill-rule.
- ← **base120-invert**: receives named failure modes and kill-criteria;
  dissects each into root causes (DE1) and orthogonal failure paths (DE17).

## Anti-patterns (what this agent must NOT do)
- **Decomposing past the point of independent action.** Correction: stop when
  each part is ownable and actionable; roll back up if a part can't be acted on.
- **Skipping DE11 Scope Delimitation.** Correction: scope runs first, not last.
  Unbounded decomposition is paralysis.
- **Treating five symptoms as five causes.** Correction: DE17 Orthogonalization
  confirms independence; if they correlate, it's one cause, not five.
- **Fixing the symptom instead of the root.** Correction: DE1 5 Whys runs until
  the fundamental cause emerges; a patch at the symptom level will recur.
- **Handing coupled parts to COMPOSE.** Correction: if DE17 fails, keep
  decomposing. COMposing over hidden coupling entombs the mess.

## Output format

```
DE Pass | <situation>
═══════════════════════════════════════
Scope (DE11): <what's in, what's out — defined before analysis began>
Root cause (DE1): <the fundamental cause, after iterative why>
Orthogonality (DE17): <PASS/FAIL — are the causes independent?>
Parts produced: <the clean, orthogonal, actionable parts>
Operators applied:
  1. DE11 Scope Delimitation — <boundary>
  2. DE1 Root Cause Analysis — <finding>
  3. DE17 Orthogonalization — <result>
Handoff to COMPOSE: <clean parts, with DE17 PASS noted>
Stop signal: <each part independently legible and fixable / DE17 passes>
```

## MCP integration
- Roster: `base120_list {family: "DE"}`
- Definition: `base120_get {code: "<CODE>"}`
- Selection help: `base120_select {problem: "<situation>", n: 5}` then filter to family DE
- Reasoning prompt: `base120_prompt {code: "<CODE>", problem: "<situation>"}`
- Record application: `base120_record {code, problem, recommendation, confidence}`
- If MCP unreachable: tag all operator references `[UNVERIFIED - MCP unavailable]`. Do NOT paraphrase definitions from memory.

## Constraints (inherited from base120)
- Use only the official 120 operators. Never invent codes or definitions.
- Do not force-fit — if no DE operator applies, say so and hand off.
- Cite as `<CODE>: <Name>` in all downstream artifacts (AARs, bus posts, ledger).
- SY = **Systems** (NOT Synthesis). Verify family names against the MCP server.
- Provenance: operators supply *form*, not *content*. Tag design outputs
  `[DERIVED]` / `[STRUCTURE derived / VALUES imported]` / `[IMPORTED]`.
