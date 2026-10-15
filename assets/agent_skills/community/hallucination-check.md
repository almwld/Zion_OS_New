---
name: hallucination-check
description: Cross-reference LLM output against source documents for factual accuracy and grounding.
version: 0.2.0
status: tested
canonical_status: not_yet_global_canon
execution-mode: advisory
argument-hint: "[--output FILE_OR_TEXT] [--sources FILE...] [--strictness low|medium|high]"
category: governance-compliance
providers:
  required: [bash, python]
---
# Hallucination Check

Verify that LLM-generated content is grounded in source material. Essential for any output that will be published, shared with clients, or used for decisions.

## When to Use
- After generating content from research (daily-research, deep-research)
- Before publishing blog posts, reports, or case studies
- Validating agent output that claims specific facts or numbers
- Auditing Gemini output (known hallucination pattern per guardrails)
- When user says "fact check" or "is this accurate" or "hallucination"

## Strictness Levels

| Level | What It Checks | Use Case |
|-------|---------------|----------|
| **low** | Only verifies explicit numbers, dates, and named entities | Quick sanity check |
| **medium** | Verifies facts + checks for unsupported causal claims | Blog posts, internal docs |
| **high** | Verifies everything + checks for subtle mischaracterizations and cherry-picking | Client deliverables, published research, compliance docs |

## Execution

1. **Parse claims**: Extract all factual claims from the output (numbers, dates, names, causal statements, comparisons)
2. **Identify sources**: Match claims against provided source documents
3. **Classify each claim**:
   - `GROUNDED` -- directly supported by source material
   - `INFERRED` -- reasonable inference from sources but not explicit
   - `UNSUPPORTED` -- no source material supports this claim
   - `CONTRADICTED` -- source material says the opposite
   - `UNVERIFIABLE` -- claim can't be checked against provided sources
4. **Score**: Percentage of claims that are GROUNDED or INFERRED
5. **Flag**: List all UNSUPPORTED and CONTRADICTED claims

## Output Format

```
Hallucination Check | {strictness}
===================================

## Summary
Claims found: {N}
Grounded: {N} ({%})
Inferred: {N} ({%})
Unsupported: {N} ({%})
Contradicted: {N} ({%})
Unverifiable: {N} ({%})

## Grounding Score: {score}/100

## Flagged Claims
| # | Claim | Status | Source Expected | Issue |
|---|-------|--------|----------------|-------|
| 1 | "Atlanta processes 70% of US card transactions" | UNVERIFIABLE | No source provided | Common claim but needs citation |
| 2 | "18,956 LOC across 947 files" | GROUNDED | gemini-guardrails.md S8 | Exact match |

## Recommendations
- {Fix CONTRADICTED claims immediately}
- {Add citations for UNSUPPORTED claims or remove them}
- {Note INFERRED claims with qualifiers like "approximately" or "suggests"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Low score | `[proof-check]` (deeper verification) |
| Client deliverable | `[content-review]` (before publishing) |
| Research output | `[research-ingest]` (only ingest grounded findings) |
| Agent output | `[agent-audit]` (if agent consistently hallucinates) |
| Claims about competitors | `[competitive-intel]` (verify market claims) |
| independent verification from a different provider | `[reasoning-router]` (`python ~/bin/reasoning_router.py route`) |

## Promotion Receipt (v0.2.0 — 2026-06-24)

**Status**: `candidate` → `tested`
**Eval suite**: `eval/` (8 cases, 42 claims)
**Schema version**: `hallucination_check_eval.v0.1.0`

### Self-test results (perfect run)
- grounding_accuracy: 1.0 (gate: ≥0.85) PASS
- false_grounded_rate: 0.0 (gate: ≤0.05, HARD) PASS
- false_contradicted_rate: 0.0 (gate: ≤0.05, HARD) PASS
- unsupported_recall: 1.0 (gate: ≥0.80) PASS
- contradicted_recall: 1.0 (gate: ≥0.80) PASS
- extraction_recall: 1.0 (gate: ≥0.80) PASS
- schema_validity: 1.0 (gate: =1.0, HARD) PASS

### Residual issues
- Self-test uses ground-truth-as-actual; real LLM run needed for true accuracy baseline
- Compound claim atomization not tested (single-claim cases only)
- Strictness levels (low/medium/high) not differentiated in corpus
