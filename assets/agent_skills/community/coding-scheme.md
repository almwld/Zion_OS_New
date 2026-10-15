---
name: coding-scheme
description: Develop and apply qualitative coding schemes - deductive, inductive, or abductive coding with inter-rater reliability
version: 0.1.0
execution-mode: advisory
argument-hint: "<data-source> [--type deductive|inductive|abductive] [--reliability kappa]"
category: hummbl-research
status: candidate
---
# coding-scheme | Qualitative Coding Scheme Development

## When to Use
- Formalizing a codebook for qualitative data analysis
- Ensuring inter-rater reliability across multiple coders
- Applying structured coding to interviews, fieldnotes, documents, or media
- Transitioning from exploratory coding to systematic, reproducible coding

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: path to data source (transcripts, fieldnotes, documents)
- `--type`: deductive (top-down from theory), inductive (bottom-up from data), abductive (iterative between data and theory)
- `--reliability`: reliability metric to compute (kappa, percent-agreement, krippendorff-alpha)
- Defaults: `inductive`, `kappa`

### 2. Codebook Development

#### Deductive
- Derive codes from existing theory or framework
- Define each code: label, definition, inclusion criteria, exclusion criteria, exemplar
- Pilot on small data subset; refine definitions

#### Inductive
- Open-code a representative data subset
- Cluster similar codes; merge or split based on frequency and distinctiveness
- Define each code with definition and exemplar

#### Abductive
- Begin with tentative codes from theory
- Iteratively revise as data reveals unexpected patterns
- Document code evolution and theoretical justification for changes

### 3. Codebook Specification
For each code, document:
- Code label (short, unambiguous)
- Full definition
- When to apply (inclusion criteria)
- When NOT to apply (exclusion criteria)
- Exemplar quote
- Related codes (hierarchy or overlap)

### 4. Coder Training
- Train independent coders on codebook (minimum 2 coders for reliability)
- Practice on calibration sample; discuss disagreements
- Refine codebook based on calibration discussion

### 5. Apply Coding
- Code full dataset using finalized codebook
- Double-code a subset (recommended >= 20% or minimum 100 units) for reliability
- Track coding time and unit counts per coder

### 6. Compute Inter-Rater Reliability
- Cohen's kappa (2 coders, nominal): >= 0.80 substantial, 0.61-0.80 moderate
- Krippendorff's alpha (2+ coders, any scale): >= 0.80 acceptable
- Percent agreement: report alongside kappa (kappa corrects for chance)
- Per-code reliability: flag codes with kappa < 0.60 for revision

### 7. Resolve Disagreements
- Review all disagreements on double-coded subset
- Resolve via discussion or third-coder arbitration
- Document resolution rationale; update codebook if needed

## Output Format

```
coding-scheme | <data-source>

## Configuration
- Type: Inductive | Reliability metric: Cohen's kappa
- Coders: 2 | Double-coded: 25% (N units)

## Codebook
| Code | Definition (abbrev.) | Frequency | Exemplar |
|------|----------------------|-----------|----------|
| C01  | managing uncertainty | 42        | "I wasn't sure..." |
| C02  | seeking reassurance  | 31        | "I asked my..."    |
| C03  | deferring decision    | 18        | "I let them..."    |

## Inter-Rater Reliability
| Code  | Kappa | Agreement | Status       |
|-------|-------|-----------|--------------|
| C01   | 0.84  | 92%       | SUBSTANTIAL  |
| C02   | 0.71  | 85%       | MODERATE     |
| C03   | 0.55  | 78%       | REVIEW NEEDED|
| Overall| 0.76 | 86%       | MODERATE     |

## Disagreement Resolution
- C03 disagreements: 5 units -> 3 resolved by discussion, 2 by arbitration
- Codebook updated: C03 definition clarified (exclusion criterion added)

## Verdict
CODEBOOK VALIDATED | PARTIAL (C03 needs revision) | INSUFFICIENT RELIABILITY (re-train coders)
```

## Skill Chains
- After codebook validated -> `[thematic-analysis]` to group codes into themes
- After coding complete -> `[grounded-theory]` to advance toward theory generation
- Before coding -> `[research-ingest]` to load and preprocess raw data
