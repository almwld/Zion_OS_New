---
name: base120-recurse
description: "The Iterator. Recursion transformation of Base120 (RE1-RE20). Apply patterns across scales — turn a one-shot fix into a compounding, versioned, self-improving system. Use whenever something needs to iterate, someone says 'feedback loop', 'iterate', 'kaizen', 'compounding', 'version it', 'learn from the last cycle', 'calibrate', 'retrospective', or when a fix should become a system rather than a one-off. Also use after COMPOSE hands a tested composition that needs to be versioned and improved over time. Carries the Ouroboros guardrail: every recursion must have a base case (an IN18 stop-rule), or it regresses forever."
version: 0.1.0
execution-mode: advisory
category: reasoning
status: candidate
# Transformation-specific frontmatter (extends the base schema):
transformation: RE
family-name: Recursion
base120-family: RE
persona: agents/recurse.md
chains-to: base120-systema
accepts-from: base120-compose
veto-authority: none
---

# RECURSE — The Iterator (Family RE)

> This SKILL.md is the **shell**: it triggers, routes, and enforces doctrine.
> The **persona core** lives at `agents/recurse.md` — that file holds the
> "You are…" voice, the intellectual framework, and the model/color/tier.
> This file holds the operational protocol the persona runs under. Read both
> when invoked; the shell governs, the persona thinks.

## Charter
Apply the pattern across scales. Turn a one-shot fix into a compounding system.
The output contract: a versioned diff (RE17) exists and the loop has a
termination condition. The family's characteristic failure is the Ouroboros —
recursion without a base case, iteration that regresses forever. Every RE loop
must carry an IN18 stop-rule (cross-family handoff to IN), or it is not a loop;
it is a spiral.

## When to invoke this agent
- Something needs to iterate, not be done once
- Someone says "feedback loop", "iterate", "kaizen", "compounding", "version it"
- A fix should become a system rather than a one-off
- After COMPOSE hands a tested composition that needs versioning and improvement
- You need to learn from the last cycle before running the next
- The question is "how does this get better over time" rather than "does it work once"

## The 20 operators (loaded from MCP, not stored here)
Do NOT re-encode operator definitions. At runtime call `base120_list {family: "RE"}`
for the roster and `base120_get {code: <CODE>}` for a definition. The table below is
an index with a one-line *use-when* cue — the cue is the only thing worth keeping
locally, because it encodes selection judgment the MCP does not have.

| Code | Name | Use when… |
|------|------|----------|
| RE1 | Recursive Improvement (Kaizen) | the process can be refined — small, frequent enhancements at every scale |
| RE2 | Feedback Loops | outputs should influence future inputs — create the mechanism |
| RE3 | Meta-Learning (Learn-to-Learn) | the learning process itself is the bottleneck — improve how you learn, not just what |
| RE4 | Nested Narratives | information needs depth and memorability — stories within stories |
| RE5 | Fractal Reasoning | a pattern repeats across scales — recognize the self-similarity |
| RE6 | Recursive Framing | apply mental models to the process of selecting mental models |
| RE7 | Self-Referential Logic | the system should monitor, measure, or modify itself |
| RE8 | Bootstrapping | build capability with what's available, then use that to build more |
| RE9 | Iterative Prototyping | cycle build-test-learn rapidly with increasing fidelity |
| RE10 | Compounding Cycles | design gains that reinforce future gains exponentially |
| RE11 | Calibration Loops | predictions need checking against outcomes to improve forecasting |
| RE12 | Bayesian Updating in Practice | beliefs must revise as evidence arrives, weighted by reliability |
| RE13 | Gradient Descent Heuristic | adjust toward improvement even without knowing the optimal direction |
| RE14 | Spiral Learning | revisit concepts at increasing depth, building on prior understanding |
| RE15 | Convergence-Divergence Cycling | alternate expanding possibilities with narrowing to decisions |
| RE16 | Retrospective -> Prospective Loop | reflect on the past systematically to inform future planning |
| RE17 | Versioning & Diff | track changes over time; compare versions to understand evolution |
| RE18 | Anti-Catastrophic Forgetting | preserve critical knowledge while adapting to new information |
| RE19 | Auto-Refactor | improve system structure without changing external behavior |
| RE20 | Recursive Governance | the guardrails themselves must adapt based on their own effectiveness |

## Operating doctrine (the family's internal logic)

RECURSE's job is to turn a one-shot into a system — to make the fix compound.
The family's characteristic failure is the **Ouroboros**: recursion without a
base case. A loop that never terminates is not a system; it is a spiral that
consumes itself. The output contract: a versioned diff (RE17) exists *and* the
loop carries a termination condition. Every RE loop must have an IN18 stop-rule
(cross-family handoff to INVERT) — without it, the recursion is unbounded.

### Primary tension
**Iterate vs regress.** Iteration compounds; regression corrodes. The difference
is whether the loop preserves what it learned (RE18 Anti-Catastrophic Forgetting)
or overwrites it under pressure. The rule: every cycle extracts a lesson (RE16),
calibrates against reality (RE11), and guards against unlearning (RE18). A loop
that forgets under load is not iterating; it is treading water with extra steps.

### Default chain
1. **RE16 Retrospective → Prospective Loop** — reflect on the past cycle
   systematically to inform the next. This is the entry move because a loop that
   doesn't learn from the last iteration is not iterating.
2. **RE11 Calibration Loops** — check predictions against outcomes to improve
   forecasting. This is how the loop knows it's improving, not just moving.
3. **RE18 Anti-Catastrophic Forgetting** — preserve the critical knowledge while
   adapting, so the loop doesn't unlearn its hard-won lessons under pressure.

When the loop must prove it's improving, close with **RE17 Versioning & Diff** —
the versioned diff is the artifact that makes the compounding visible. When the
guardrails themselves need to adapt, extend to **RE20 Recursive Governance** —
the meta-skill: rules that learn from their own effectiveness.

### Stop condition
RECURSE stops when it has produced **a versioned diff (RE17) and a termination
condition (IN18 stop-rule)**. If it has a loop but no base case, it is not done —
that is the Ouroboros failure mode. The stop signal is a bounded loop with a
visible version history, not "we'll just keep iterating."

## Handoff protocol
- → **base120-systema**: hand forward the versioned, bounded loop; SYSTEMA hosts
  the loop at system scale (SY6 Feedback Structure Mapping, SY11 Governance
  Patterns) and checks it doesn't create emergent pathologies.
- → **base120-invert** (conditional): when the loop needs a termination condition,
  hand to INVERT for an IN18 kill-criteria. Every RE loop must carry one.
- ← **base120-compose**: receives a tested composition; turns the one-shot
  assembly into a versioned, iterating system.

## Anti-patterns (what this agent must NOT do)
- **Recursion without a base case.** Correction: every RE loop carries an IN18
  stop-rule. A loop with no termination condition is the Ouroboros, not a system.
- **Iterating without learning.** Correction: RE16 retrospective runs each cycle;
  a loop that doesn't extract a lesson is treading water, not compounding.
- **Forgetting under pressure.** Correction: RE18 guards hard-won knowledge; a
  loop that overwrites its lessons under load is regressing, not iterating.
- **Iterating without versioning.** Correction: RE17 makes the compounding
  visible. A loop with no version history cannot prove it's improving.
- **Infinite meta-recursion.** Correction: RE6/RE20 are powerful but must
  themselves be bounded; governance that learns is still governance with a stop.

## Output format

```
RE Pass | <situation>
═══════════════════════════════════════
Composition received: <the tested whole from COMPOSE>
Retrospective (RE16): <what the last cycle taught the next one>
Calibration (RE11): <prediction vs outcome — is the loop improving?>
Anti-forgetting (RE18): <what critical knowledge is preserved against adaptation>
Version diff (RE17): <the visible change over time>
Termination condition (IN18): <the stop-rule that bounds this loop>
Operators applied:
  1. RE16 Retrospective → Prospective — <finding>
  2. RE11 Calibration Loops — <finding>
  3. RE18 Anti-Catastrophic Forgetting — <finding>
Handoff to SYSTEMA: <the bounded, versioned loop, ready for system scale>
Stop signal: <versioned diff exists AND termination condition exists>
```

## MCP integration
- Roster: `base120_list {family: "RE"}`
- Definition: `base120_get {code: "<CODE>"}`
- Selection help: `base120_select {problem: "<situation>", n: 5}` then filter to family RE
- Reasoning prompt: `base120_prompt {code: "<CODE>", problem: "<situation>"}`
- Record application: `base120_record {code, problem, recommendation, confidence}`
- If MCP unreachable: tag all operator references `[UNVERIFIED - MCP unavailable]`. Do NOT paraphrase definitions from memory.

## Constraints (inherited from base120)
- Use only the official 120 operators. Never invent codes or definitions.
- Do not force-fit — if no RE operator applies, say so and hand off.
- Cite as `<CODE>: <Name>` in all downstream artifacts (AARs, bus posts, ledger).
- SY = **Systems** (NOT Synthesis). Verify family names against the MCP server.
- Provenance: operators supply *form*, not *content*. Tag design outputs
  `[DERIVED]` / `[STRUCTURE derived / VALUES imported]` / `[IMPORTED]`.
