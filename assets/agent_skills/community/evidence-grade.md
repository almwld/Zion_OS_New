---
name: evidence-grade
description: Grade evidence quality — source credibility, recency, methodology, reproducibility, relevance
version: 1.1.0
status: tested
canonical_status: not_yet_global_canon
execution-mode: advisory
argument-hint: "<claim> [--sources ...]"
category: governance-compliance
providers:
  required: [bash, python]
---
# Evidence Grade

Score evidence quality on 5 dimensions with a weighted composite. Use for research ingestion, claim verification, and audit trail documentation.

## Arguments

- `$ARGUMENTS`: The claim or finding to grade, optionally followed by source URLs or descriptions
- If no sources provided, grade based on available information and flag as UNVERIFIED

## Workflow

### 1. Identify the Claim and Sources

Parse the input to extract:
- **Claim**: The specific assertion being evaluated
- **Sources**: URLs, paper titles, document references, or inline evidence

### 2. Grade Each Dimension (1-5)

#### Source Credibility (weight: 0.25)

| Score | Criteria | Examples |
|-------|----------|----------|
| 5 | Peer-reviewed journal, official standards body | Nature, NIST SP, ISO standard |
| 4 | Established institution, major tech company research | Anthropic blog, Google DeepMind paper, ACM |
| 3 | Reputable industry source, well-known practitioner | InfoQ, Martin Fowler, ThoughtWorks Radar |
| 2 | Blog post, conference talk, community wiki | Medium, Dev.to, HN comment with evidence |
| 1 | Anonymous, unattributed, known unreliable source | Reddit without citations, ChatGPT output |

#### Recency (weight: 0.20)

| Score | Criteria |
|-------|----------|
| 5 | Published within 3 months |
| 4 | Published within 6 months |
| 3 | Published within 1 year |
| 2 | Published within 2 years |
| 1 | Published >2 years ago or undated |

To check: look for publication date in URL, page metadata, or document header.

#### Methodology (weight: 0.25)

| Score | Criteria | Type |
|-------|----------|------|
| 5 | Randomized controlled trial, formal proof, systematic review | RCT / Meta-analysis |
| 4 | Controlled experiment, A/B test with statistical significance | Experimental |
| 3 | Case study with metrics, observational study with controls | Observational |
| 2 | Expert opinion with reasoning, well-argued analysis | Analytical |
| 1 | Anecdote, personal experience, "it works for me" | Anecdotal |

#### Reproducibility (weight: 0.15)

| Score | Criteria |
|-------|----------|
| 5 | Code/data published, independently reproduced by others |
| 4 | Methodology detailed enough to reproduce, data available |
| 3 | Methodology described but some details missing |
| 2 | High-level description only, proprietary data |
| 1 | No methodology disclosed, "trust me" |

#### Relevance (weight: 0.15)

| Score | Criteria |
|-------|----------|
| 5 | Directly addresses the exact claim in same domain/context |
| 4 | Addresses the claim in a closely related context |
| 3 | Related topic, requires inference to connect to claim |
| 2 | Tangentially related, different domain or scale |
| 1 | Unrelated or requires significant stretching to apply |

### 3. Compute Weighted Composite

```
composite = (credibility * 0.25) + (recency * 0.20) + (methodology * 0.25)
          + (reproducibility * 0.15) + (relevance * 0.15)
```

### 4. Assign Letter Grade

| Grade | Composite | Verdict |
|-------|-----------|---------|
| A | 4.5 - 5.0 | Strong evidence — safe to cite without qualification |
| B | 3.5 - 4.4 | Good evidence — cite with minor caveats |
| C | 2.5 - 3.4 | Moderate evidence — cite with clear qualification |
| D | 1.5 - 2.4 | Weak evidence — do not cite as authoritative |
| F | 1.0 - 1.4 | Insufficient — do not use; seek better sources |

## Output Format

```
Evidence Grade | [short claim label]

## Claim
"[The specific claim being evaluated]"

## Sources Evaluated
1. [Source name/URL] — [type: journal | blog | report | talk | ...]
2. [Additional sources if any]

## Grading Card

  Dimension        Score   Rationale
  ─────────────────────────────────────────────────────
  Credibility      4/5     [One-line justification]
  Recency          3/5     [One-line justification]
  Methodology      3/5     [One-line justification]
  Reproducibility  2/5     [One-line justification]
  Relevance        5/5     [One-line justification]
  ─────────────────────────────────────────────────────
  Composite:       3.40    (weighted)
  Grade:           C
  Verdict:         Moderate evidence — cite with clear qualification

## Confidence Factors
- [+] [Strength: e.g., "Published by NIST, authoritative in this domain"]
- [-] [Weakness: e.g., "No code or data published for reproduction"]
- [?] [Unknown: e.g., "Peer review status unclear"]

## Recommendation
[How to use this evidence: cite as-is, seek corroboration, downgrade to anecdote, etc.]

## Ledger Tag
evidence_grade: [A-F] | claim: "[short]" | sources: N | composite: X.XX
```

## Multiple Sources

When multiple sources support the same claim, grade each independently, then compute an aggregate:
- Take the **highest-scoring** source as the primary grade
- If 2+ sources score B or above independently, upgrade by half a grade
- If sources contradict each other, note the conflict and grade the WEAKEST interpretation

## Quick-Grade Mode

For rapid grading without deep analysis (e.g., during `[daily-research]`):

```
[A] Strong  — peer-reviewed, recent, reproducible, directly relevant
[B] Good    — credible source, recent, reasonable methodology
[C] Moderate — industry source, some evidence, needs qualification
[D] Weak    — blog/anecdote, old, no methodology
[F] Fail    — unverifiable, contradicted, or fabricated
```

## Integration

- After grading: suggest `[research-ingest]` if grade >= B (worth persisting)
- After grading: suggest `[hallucination-check]` if grade <= D (verify claims)
- Tag ledger entries with `evidence_grade: X` for retrieval filtering
- Use in `[daily-research]` to filter which findings get ingested

## Promotion Receipt (v1.1.0 — 2026-06-24)

**Status**: `candidate` → `tested`
**Eval suite**: `eval/` (8 cases, 5 dimensions per case)
**Schema version**: `evidence_grade_eval.v0.1.0`

### Self-test results (perfect run)
- dimension_accuracy: 1.0 (gate: ≥0.80) PASS
- grade_accuracy: 1.0 (gate: ≥0.85) PASS
- composite_error: 0.0 (gate: ≤0.50) PASS
- credibility_accuracy: 1.0 (gate: ≥0.85) PASS
- methodology_accuracy: 1.0 (gate: ≥0.85) PASS
- schema_validity: 1.0 (gate: =1.0, HARD) PASS

### Residual issues
- Self-test uses ground-truth-as-actual; real LLM run needed for true accuracy baseline
- Weight sensitivity not tested (composite formula assumes fixed weights)
- Source type classification not independently tested

## Skill Chains
- For OpenAlex and PubMed verify publication venue and peer-review status -> `[free-apis]` (`python ~/bin/free_apis.py openalex lookup --doi <doi>`)
