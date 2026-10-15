---
name: plausibility-audit
description: >
  Adversarial self-audit that stress-tests uniqueness and capability claims
  against the external market and academic literature. Decomposes the claim,
  inspects own assets, searches for competitors and prior art, maps the
  competitive zone, scores plausibility + defensibility, identifies what IS
  distinctive as falsifiable conditions, and proposes ranked action paths.
  Use when anyone claims "no one else has built this", "we're the first",
  "we're the only", "this is unique", or before using a capability claim in
  external communication. [Maps to IN6, IN8.]
version: 0.1.0
status: candidate
execution-mode: advisory
argument-hint: "<claim to audit>"
category: governance-compliance
---

# Plausibility Audit

An adversarial self-audit pattern for uniqueness and capability claims.
Distinct from `/claim-verify` (is this fact true?), `/competitive-intel`
(research a competitor), and `/report-card` (did I do what I said). This
skill answers: **is this claim about our uniqueness actually true against
the external world?**

## When to Use

- Someone claims "no one else has built this" or "we're the first to X"
- A positioning document asserts uniqueness before external communication
- An agent or team member makes a capability claim that sounds too good
- Before publishing a comparison matrix, landing page, or pitch deck
- When the operator asks "how plausible is that claim?"

## Gates (non-negotiable)

| Gate | Rule | Origin |
|------|------|--------|
| No search, no score | Plausibility score cannot be given without external web + arxiv search | MIRROR (2604.19809): self-prediction fails universally without external input |
| Adversarial posture | Assume the claim is false; look for disconfirming evidence first | Frontier AI Auditing (2601.11699): self-assessment is structurally biased |
| Independent sources | At least 3 independent sources before scoring | Auditing Discovery Claims (2608.00981): single oracle inflates 43x |
| Falsifiable distinctions | What IS distinctive must be stated as a falsifiable condition | Falsifiable Release Gates (2607.13070): opinions ≠ evidence |
| Dual scoring | Score both plausibility (is it true?) AND defensibility (can we hold it?) | A true claim can be indefensible if competitors replicate easily |

## Execution

### 1. Decompose the claim

Split into (Subject, Predicate, Object) triples per AutoVerifier (2604.02617).
"We built X that no one else has" → (We, built, X) + (No one else, built, X).
Each triple is auditable independently.

### 2. Inspect own assets

Read the actual code, data, or evidence. Do not trust summaries — read files.
Enumerate the evidence chain: what proof do we have that we built it? What
proof do we have that it works? The evidence chain is separate from the claim.
Suggested verification commands:
- Code/data: `wc -l`, `cat pyproject.toml`, `python -c "import X; print(len(X))"`
- PyPI: `pip show <package>`, `pip index versions <package>`
- Tests: `python -m pytest --collect-only -q tests/ | tail -1`
- Fleet deployment: `grep -rl "<code>" ~/.agents/skills/ | wc -l`
Chain to `/report-card` if self-reported completion claims need verification.

### 3. Search for direct competitors (web)

Web search for the claim's domain + "open source" + "framework" + "library".
Search GitHub, PyPI, npm. Assume the claim is false and look for evidence
of that. Record: project name, stars, feature overlap (full/partial/adjacent).
Chain to `/competitive-intel` for deep competitor profiles if needed.

### 4. Search for academic prior art (arxiv)

Search arxiv for the claim's domain + governance/runtime/agent/enforcement.
The academic literature may have formal versions of what we built informally.
Record: paper title, year, key overlap, formal rigor (TLA+, Verus, etc.).
This step is mandatory, not optional.

### 5. Map the competitive zone

Classify the position per category theory. Apply these criteria in order —
the first match wins:

- **Owned**: a competitor has >1000 stars or >10 citations AND direct feature
  overlap (full or partial). Challenging an owned position is structurally
  unwinnable without a fundamentally different approach.
- **Contested**: 2+ competitors exist with partial or adjacent overlap, none
  with dominant market share. The position is claimable but not guaranteed.
- **Unoccupied**: no competitor has the specific combination of features in
  the claim. Adjacent players exist but none directly overlaps. This is the
  strongest position — but verify it's unoccupied because it's valuable, not
  because no one wants it.

### 6. Score the claim

Score on two axes (1-10):
- **Plausibility**: is the claim true? (1 = clearly false, 10 = clearly true)
- **Defensibility**: can we hold the position if true? (1 = trivially replicated, 10 = structural moat)

Include explicit unknowns: what we DON'T know matters as much as what we do.

### 7. Identify what IS distinctive

State distinctions as falsifiable conditions, not opinions.
- Falsifiable: "We run 100+ agents 24/7 with 0 failures" (verifiable from bus data)
- Not falsifiable: "We're the best" (no verification condition)

### 8. Propose action paths

At least 3 paths ranked by leverage (impact / cost). Cost is measured in
estimated days of work. For "free" actions, use 0.5 as the cost denominator
to avoid divide-by-zero. Leverage = impact_score / cost_in_days.
- **A: Change the claim** (0.5 days, immediate) — shift to what's actually true
- **B: Build what's missing** (weeks, ~15 days) — close the gap between claim and reality
- **C: Prove the distinction empirically** (days, ~3 days) — publish a comparison matrix
- **D: Get external validation** (weeks, ~20 days) — third-party audit, academic citation, external adoption

## Output Format

```
Plausibility Audit | <claim>
══════════════════════════════════════════════════

## Decomposed Claims
| # | Subject | Predicate | Object |
|---|---------|-----------|--------|

## Own Assets Verified
| Asset | Evidence | Verification |
|-------|----------|-------------|

## External Landscape
| Source | Type | Overlap | Stars/Citations |
|--------|------|---------|-----------------|

## Academic Prior Art
| Paper | Year | Key overlap | Formal rigor |
|-------|------|-------------|-------------|

## Competitive Zone
| Zone | Assessment |
|------|-----------|
| Owned | <who owns what> |
| Contested | <what's contested> |
| Unoccupied | <what's genuinely open> |

## Scores
| Axis | Score | Justification |
|------|-------|---------------|
| Plausibility | X/10 | <one sentence> |
| Defensibility | X/10 | <one sentence> |

## What IS Distinctive (falsifiable)
- <falsifiable distinction>

## Action Paths
| Path | Cost | Impact | Leverage |
|------|------|--------|----------|
| A: <change claim> | free | X/10 | X |
| B: <build missing> | <weeks> | X/10 | X |
| C: <prove empirically> | <days> | X/10 | X |
| D: <external validation> | <weeks> | X/10 | X |

## Recommended Order
1. <highest leverage first>

## Gates Passed
- [ ] External web search performed
- [ ] Academic prior art search performed
- [ ] Adversarial posture maintained
- [ ] 3+ independent sources found
- [ ] Distinctions stated as falsifiable
- [ ] Competitive zone mapped
- [ ] Dual scoring (plausibility + defensibility)
- [ ] Action paths with cost estimates
```

## Base120 Context

- Primary: **IN6** (Proof by Contradiction — search for evidence that contradicts the claim)
- Related: **IN8** (Proof by Contrapositive — if the claim were false, what would we find?), **IN5** (Absence Audit — what's missing from our own evidence?)

## Skill Chains

### Advisory

- Before `/plausibility-audit` → `/report-card` (verify we actually built what we claim)
- During step 2 → `/claim-verify` (verify factual sub-claims within the main claim)
- During step 3 → `/competitive-intel` (deep competitor profiles if web search surfaces serious overlap)
- During step 4 → `/evidence-grade` (grade the quality of competitor/prior-art evidence)
- After `/plausibility-audit` → `/claims-review` (internal consistency check on the revised claim set)
- After `/plausibility-audit` with high plausibility → `/arcana-review` (multi-agent peer review before external publication)

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run (notify operator)
- **T4 (Probationary)**: May run with operator approval
- **Operator**: Override any restriction

## Prior Art

This skill encodes an applied version of academic claim verification and
capability auditing, adapted for internal fleet use against self-serving
capability claims. Key academic grounding:

- AutoVerifier (2604.02617): claim decomposition into (Subject, Predicate, Object) triples
- MIRROR (2604.19809): compositional self-prediction fails universally; external metacognitive control reduces confident failure 76%
- Frontier AI Auditing (2601.11699): self-assessment is structurally insufficient; external auditing provides healthy skepticism against groupthink
- Auditing Discovery Claims (2608.00981): a single fallible oracle inflates capability claims 43x vs 1x under independent predictors
- Falsifiable Release Gates (2607.13070): every capability claim must pass a pre-declared, machine-checkable acceptance suite
- Stripping the Shells (Zenodo 19223017): quantitative analysis of AI industry claims vs verified capability; four AI systems self-audited their own claims

The novel distinction: academic papers verify claims about *other people's
systems*. This skill verifies claims about *our own system*. The adversarial
posture is directed inward, not outward.
