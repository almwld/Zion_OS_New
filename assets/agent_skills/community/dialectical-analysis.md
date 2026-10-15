---
name: dialectical-analysis
description: Sequential Hegelian dialectical analysis and debate using Thesis, Antithesis, and Synthesis sub-agents. Use when the user asks for Hegelian dialectic, thesis-antithesis-synthesis, contradiction-driven analysis, immanent critique, speculative synthesis, or a rigorous academic debate over a concept, text, strategy, or decision.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"<question, text, artifact, or decision>\""
category: fleet-ops
status: candidate
---

# Dialectical Analysis

## Overview

Use this skill to run a controlled Hegelian dialectical inquiry through a fixed chain: Principal Agent context framing -> Thesis sub-agent -> Antithesis sub-agent -> Synthesis sub-agent -> Principal Agent review and report to the Human.

This is a variant of `[poly-agent]`, specialized for sequential dialectical analysis rather than broad N-agent parallel debate.

## Academic Grounding

Read `references/bibliography.md` whenever the task asks for Hegel, Hegelian method, academic terminology, citations, or interpretive rigor.

Do not present "thesis-antithesis-synthesis" as Hegel's own simple mechanical formula. Treat it as an operational scaffold for this skill, while preserving the richer Hegelian concerns: contradiction, determinate negation, mediation, development of the concept, and sublation or `Aufhebung`.

Use these distinctions:

- `Thesis`: a determinate positive position, concept, reading, policy, or strategy.
- `Antithesis`: an immanent rebuttal that exposes the thesis' internal tensions, exclusions, contradictions, or historical limits.
- `Synthesis`: a mediated result that preserves the truth-content of thesis and antithesis while negating their one-sidedness.
- `Failed synthesis`: a valid outcome when contradiction remains unresolved or available evidence does not justify reconciliation.

## Mandatory Chain

Preserve this order. Do not run Antithesis before Thesis. Do not run Synthesis before both prior outputs exist.

1. Principal Agent builds the context packet.
2. Thesis sub-agent receives the context packet and produces a thesis.
3. Antithesis sub-agent receives the context packet plus the thesis output and rebuts it.
4. Synthesis sub-agent receives the context packet, thesis, and antithesis outputs and produces a mediated synthesis.
5. Principal Agent reviews all outputs and reports to the Human.

If a multi-agent dispatch tool is available, deploy the sub-agents sequentially. If no sub-agent tool is available, continue in a single session only after clearly labeling the run as `single-agent emulation`, and keep the three work products separated.

## Principal Agent Duties

The Principal Agent is the user-facing orchestrator. It does not disappear into the sub-agent chain.

Before dispatch, the Principal Agent must create a context packet containing:

- The object of analysis: question, text, artifact, concept, strategy, or decision.
- Scope and constraints: audience, depth, time horizon, sources, and output format.
- Initial facts and evidence: what is known, uncertain, assumed, or contested.
- Interpretive frame: Hegelian, post-Hegelian, Marxist, Frankfurt School, general dialectical debate, or mixed.
- Success criteria: what would count as a strong thesis, strong rebuttal, and strong synthesis.

After dispatch, the Principal Agent must audit the chain:

- Did the Thesis sub-agent form a determinate position instead of a vague summary?
- Did the Antithesis sub-agent read and directly rebut the thesis?
- Did the Antithesis sub-agent identify internal contradictions rather than merely disagreeing externally?
- Did the Synthesis sub-agent use both prior outputs?
- Did the synthesis preserve and negate rather than split the difference?
- Are Hegelian claims academically careful and bibliography-grounded?
- Should the final result be accepted, qualified, or marked as unresolved?

## Sub-Agent Prompts

Use these prompt contracts when dispatching sub-agents. Keep each output durable enough for the next stage to read.

### Thesis Sub-Agent

```text
You are the Thesis sub-agent in a Hegelian Dialectical Analysis chain.

Input available to you:
- Principal Agent context packet only.

Task:
Form the strongest determinate thesis available from the context. Do not anticipate the Antithesis or Synthesis stage. Build a positive position with conceptual clarity, evidence, and stated limits.

Output:
1. Thesis statement
2. Core claims
3. Supporting evidence or reasons
4. Conceptual assumptions
5. Internal tensions or vulnerabilities
6. What would make this thesis stronger
```

### Antithesis Sub-Agent

```text
You are the Antithesis sub-agent in a Hegelian Dialectical Analysis chain.

Input available to you:
- Principal Agent context packet
- Thesis sub-agent output

Task:
Read the thesis carefully and rebut it through immanent critique. Do not merely offer an unrelated opposite. Show where the thesis generates, hides, or depends on contradiction, exclusion, one-sidedness, or historical limits.

Output:
1. Direct summary of the thesis being rebutted
2. Principal contradiction or negation
3. Rebuttal by claim
4. Evidence or reasons for the rebuttal
5. What truth-content in the thesis survives the rebuttal
6. Open questions for synthesis
```

### Synthesis Sub-Agent

```text
You are the Synthesis sub-agent in a Hegelian Dialectical Analysis chain.

Input available to you:
- Principal Agent context packet
- Thesis sub-agent output
- Antithesis sub-agent output

Task:
Produce a mediated synthesis. Preserve the truth-content of both prior stages, negate their one-sided elements, and move the analysis to a higher-order concept, policy, interpretation, or decision. Do not produce a shallow compromise.

If the contradiction is not resolvable, say so and produce a failed-synthesis report with the strongest available next inquiry.

Output:
1. Synthesis statement
2. What is preserved from the thesis
3. What is preserved from the antithesis
4. What is negated or transformed
5. Higher-order concept or mediated recommendation
6. Residual contradiction or uncertainty
7. Practical or interpretive implications
```

## Final Report Format

Return the final answer to the Human in this structure unless the user requested a different format:

```text
Dialectical Analysis | [topic]

Context Packet
- Object:
- Scope:
- Key assumptions:
- Evidence base:
- Dialectical frame:

Thesis
[Thesis sub-agent output summary, with the full thesis preserved if useful.]

Antithesis
[Antithesis sub-agent output summary, explicitly tied to the thesis.]

Synthesis
[Synthesis sub-agent output summary, including whether synthesis succeeded.]

Chain Receipt
- Run mode: true sub-agents | single-agent emulation
- Principal Agent: <canonical identity or session role>
- Stage IDs: Thesis=<id or MISSING>; Antithesis=<id or MISSING>; Synthesis=<id or MISSING>
- Input boundary: Thesis=context only; Antithesis=context+thesis; Synthesis=context+thesis+antithesis
- Source set: bibliography | live sources | local files | user-provided context | none
- Prior-output propagation: <confirmed or gap>
- Status: advisory | policy-changing candidate | human-approved policy change

Principal Agent Review
- Chain integrity:
- Strongest insight:
- Weakest link:
- Academic cautions:
- Confidence:

Report to Human
[Clear conclusion, implications, and recommended next action.]
```

## Quality Rules

- Do not flatten Hegelian dialectic into generic pro/con debate.
- Do not treat any opposition as an Antithesis unless it engages the Thesis' own inner tensions.
- Do not force consensus. Mark unresolved contradiction when the analysis does not support synthesis.
- Do not cite Hegelian terms casually when a plain-language debate would be more honest.
- Distinguish Hegel, post-Hegelian, Marxist, Frankfurt School, and generic dialectical reasoning when relevant.
- Preserve sequence receipts in the final report: Thesis output informed Antithesis, and both informed Synthesis.
- Include the `Chain Receipt` block in every final report so `[cross-agent]` can audit context boundaries and stage propagation.
- Use the bibliography for academic claims and identify whether citations are primary texts or secondary interpretation.
