---
name: epistemic-stance
description: Pre-delegation epistemic triage — names the truth-related intent before tool selection. Sits above HUAOMP and MTSMU in the apex stack. Prevents mismatched epistemic tools (e.g., truth-preserving logic applied to a truth-seeking task).
version: 1.0.0
execution-mode: advisory
argument-hint: "[task description or question to classify]"
category: dev-tools
status: tested
providers:
  required: [bash, python]
---
# Epistemic Stance

Classify the epistemic intent of a task before selecting tools. Prevents the most common
epistemic mismatch: running truth-preserving analysis on a truth-seeking problem, or
applying truth-testing rigor to a truth-transmitting task.

**Position in stack:** Run this before HUAOMP, MTSMU, or any deep-research invocation.
Apex should invoke this as its first pre-delegation gate when the task type is ambiguous.

## Stances

| Stance | Core operation | Primary tools |
|--------|---------------|---------------|
| **SEEKING** | Discover what is actually true | MTSMU, `[deep-research]`, `[root-cause]`, `[mtsmu-debug]` |
| **TESTING** | Verify claims against evidence | `[proof-check]`, `[eval-suite]`, `[hallucination-check]`, MTSMU |
| **GENERATING** | Produce new true claims via synthesis | HUAOMP (Absolute/Universal), `[brainstorm]`, `[huaomp]` |
| **BOUNDING** | Map the edges of what we know | HUAOMP (Omni), `[pre-mortem]`, `[worst-case]`, `[absence-audit]` |
| **PRESERVING** | Ensure transformations don't corrupt truth | `[proof-check]`, deductive review, logic gates |
| **TRANSMITTING** | Communicate without distortion to receiver | `[cultural-adapt]`, briefing renderers, neurotype-aware output |
| **PROTECTING** | Make truth-records immutable/unforgeable | Base4, governance receipts, append-only logs |
| **RECOVERING** | Reconstruct truth from fragments | `[git-archaeology]`, audit trails, provenance chains |
| **NEGOTIATING** | Reach intersubjective agreement | Stakeholder alignment, Habermas lens, `[discovery-call]` |

## Classification Protocol

Given `$ARGUMENTS` (a task description, question, or intent):

### Step 1 — Primary stance

Ask: **What is the task fundamentally trying to do with truth?**

- *"Find bugs / find what's wrong / discover the actual state"* → **SEEKING**
- *"Check if this claim/code/output is correct"* → **TESTING**
- *"Produce a new insight, framework, or constraint"* → **GENERATING**
- *"Understand the limits of what we know, map uncertainty"* → **BOUNDING**
- *"Make sure this logic / argument / transformation holds"* → **PRESERVING**
- *"Explain, brief, or translate for an audience"* → **TRANSMITTING**
- *"Create an audit trail, log, or immutable record"* → **PROTECTING**
- *"Reconstruct what happened from incomplete evidence"* → **RECOVERING**
- *"Align multiple agents/stakeholders on a shared understanding"* → **NEGOTIATING**

### Step 2 — Secondary stance (if compound task)

Most real tasks are compound. Name both:
- Primary stance: drives tool selection
- Secondary stance: informs how to present outputs

Example: *"Review this PR for correctness and brief the team"*
→ Primary: **TESTING** (MTSMU) | Secondary: **TRANSMITTING** (brief format)

### Step 3 — Tool recommendation

| Primary stance | Recommended lead tool | Secondary tool |
|---------------|-----------------------|----------------|
| SEEKING | MTSMU (`[mtsmu-review]`) | `[deep-research]` if knowledge gap |
| TESTING | `[proof-check]` or MTSMU | `[eval-suite]` for AI outputs |
| GENERATING | `[huaomp]` | `[brainstorm]` for lower-stakes |
| BOUNDING | `[huaomp]` (Omni+Absolute lenses) | `[pre-mortem]` for risk |
| PRESERVING | `[proof-check]` | `[contract-review]` for schemas |
| TRANSMITTING | `[cultural-adapt]` or briefing renderer | `[exec-summary]` for compression |
| PROTECTING | Base4 pattern / `[governance-audit]` | `[evidence-pack]` |
| RECOVERING | `[git-archaeology]` | `[git-blame-analysis]` |
| NEGOTIATING | Human-led — flag for `[discovery-call]` | `[stakeholder-update]` |

### Step 4 — Mismatch warning

If the user has already selected a tool, check for mismatch:

| If they're using... | But the stance is... | Warning |
|--------------------|---------------------|---------|
| MTSMU | TRANSMITTING | MTSMU will over-index on findings; consider `[exec-summary]` first |
| HUAOMP | TESTING | HUAOMP generates constraints, not verdicts; follow with `[proof-check]` |
| `[proof-check]` | SEEKING | Deductive proof can't discover unknown bugs; use MTSMU |
| `[deep-research]` | PRESERVING | Research adds knowledge; it doesn't enforce invariants |
| MTSMU | GENERATING | MTSMU finds what's wrong, not what's possible; use HUAOMP |

## Output Format

```
Epistemic Stance | <task slug> | <date>
═══════════════════════════════════════

Primary stance: <STANCE>
Secondary stance: <STANCE or none>

Why: <1-2 sentence rationale citing the task's fundamental operation>

Mismatch check: <CLEAR or WARNING: <what was wrong>>

Recommended tool chain:
1. <tool> — <why>
2. <tool> — <why> (optional secondary)

Ready for: <which apex mode or skill to invoke next>
```

## When Apex Should Auto-Invoke This

Apex should run `[epistemic-stance]` before delegating when:
- Task description is ambiguous (could be SEEKING or TESTING or GENERATING)
- User says "review", "check", "analyze", "explain", or "assess" without further qualification
- Task involves both code analysis AND communication
- Previous session used the wrong tool for the task type (recurring mismatch)

Auto-skip this gate when stance is unambiguous (e.g., "run tests" → TESTING; "write briefing" → TRANSMITTING).

## Base120 Mapping

| Stance | Primary model | Secondary model |
|--------|--------------|-----------------|
| SEEKING | DE1 (Root Cause / 5 Whys) | IN10 (Red Teaming) |
| TESTING | RE12 (Bayesian Updating) | DE14 (Variable Control) |
| GENERATING | CO4 (Interdisciplinary Synthesis) | P1 (First Principles) |
| BOUNDING | IN2 (Premortem Analysis) | SY2 (System Boundaries) |
| PRESERVING | RE7 (Self-Referential Logic) | DE12 (Constraint Isolation) |
| TRANSMITTING | P8 (Narrative Framing) | P9 (Cultural Lens Shifting) |
| PROTECTING | SY11 (Governance Patterns) | SY18 (Measurement & Telemetry) |
| RECOVERING | RE17 (Versioning & Diff) | DE1 (Root Cause) |
| NEGOTIATING | P6 (Point-of-View Anchoring) | CO1 (Synergy Principle) |

## Notes

- NEGOTIATING is the only stance that cannot be tool-automated — it requires human
  presence. Flag it immediately and route to async update or discovery call.
- Truth-preserving ≠ truth-seeking: the LLM default is preservation (consistency,
  no hallucination). SEEKING requires overriding this default by biasing toward
  uncomfortable findings. MTSMU is the explicit override.
- PROTECTING (Base4) is a meta-stance — it doesn't concern *what* is true but
  *whether the record can be trusted*. Governance receipts live here.
