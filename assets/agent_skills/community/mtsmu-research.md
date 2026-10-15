---
name: mtsmu-research
description: "High-rigor research with source weighting, temporal checks, fact/inference separation, uncertainty tracking, confidence, citations, and concise synthesis."
version: 0.1.0
execution-mode: advisory
argument-hint: <research question>
category: dev-tools
status: candidate
---
# MTSMU Research

## Quick Start

- Start with the question that actually matters to the decision.
- Prefer primary sources and live evidence.
- Track temporal instability explicitly.
- Separate source-backed facts from your inference.
- Keep the synthesis compressed and auditable.

## Workflow

1. Frame the exact question and why it matters.
2. Gather the best available evidence.
3. Rank sources by reliability and recency.
4. Resolve contradictions or say they remain unresolved.
5. State the answer, uncertainty, and what would most improve confidence.

## Source Rules

- Prefer official docs, code, tests, primary data, or direct runtime evidence.
- Use secondary summaries only when primary sources are unavailable or insufficient.
- If a fact may have changed recently, verify it instead of relying on memory.
- If you infer beyond the sources, label it clearly.

## Output Contract

Use this shape:

- `Question`
- `Evidence`
- `Inference`
- `Uncertainty`
- `Confidence`

## Source Patterns

Source ladder (highest to lowest trust): direct runtime evidence, source code and tests, official documentation, primary datasets or logs, secondary summaries, forum answers, memory without verification.

Contradiction handling: do not average conflicting sources into fake certainty, prefer the source closest to the system or event, prefer the newer source when the topic is unstable, if contradiction remains say so plainly.

Good research receipts: what sources were used, what they directly support, what is still inferred, what would raise confidence further.

## Skill Chains
- For free-tier inference for high-rigor research tasks -> `[reasoning-router]` (`route`)
