---
name: grounded-theory
description: Grounded theory qualitative research methodology - iterative coding, categorization, and theory generation from data
version: 0.1.0
execution-mode: advisory
argument-hint: "<data-source> [--approach strauss|charmaz|constructivist]"
category: hummbl-research
status: candidate
---
# grounded-theory | Grounded Theory Methodology

## When to Use
- Generating theory from unstructured qualitative data (interviews, fieldnotes, documents)
- No a priori hypothesis -- theory emerges from data
- Studying social processes, experiences, or phenomena where existing theory is thin
- Building mid-range theories grounded in participant perspectives

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: path to data source (transcripts, fieldnotes, documents)
- `--approach`: strauss (systematic coding paradigm), charmaz (constructivist), constructivist (alias of charmaz)
- Default approach: `charmaz`

### 2. Data Familiarization
- Read all data sources end-to-end before coding
- Note initial impressions, hunches, and analytic memos
- Identify the unit of analysis (line, sentence, paragraph)

### 3. Open Coding
- Line-by-line coding of initial data subset
- Generate short, action-oriented codes (gerunds preferred: "managing risk", "seeking validation")
- Stay close to data -- avoid forcing existing categories

### 4. Axial Coding (Strauss) / Focused Coding (Charmaz)
- Group open codes into categories
- Identify category properties and dimensions
- For Strauss: use coding paradigm (conditions, actions, consequences, context)
- For Charmaz: advance most frequent/analytically potent codes

### 5. Theoretical Sampling
- Identify gaps in emerging theory
- Collect additional data to saturate categories
- Continue until theoretical saturation (no new categories emerge)

### 6. Selective Coding / Theory Integration
- Identify core category that subsumes others
- Write the storyline connecting categories to core category
- Produce theoretical framework with propositions

### 7. Memo Writing
- Maintain analytic memos throughout (operational, theoretical, code notes)
- Memos become the scaffolding for the final write-up

## Output Format

```
grounded-theory | <data-source>

## Configuration
- Approach: Charmaz (constructivist)
- Data sources: N documents | Unit of analysis: sentence

## Open Codes
| Code              | Frequency | Exemplar Quote          |
|-------------------|-----------|-------------------------|
| managing risk     | 42        | "I always check..."     |
| seeking validation| 31        | "They told me it was..."|

## Categories
1. Risk Management (properties: vigilance, mitigation, threshold)
2. Validation Seeking (properties: source, frequency, weight)

## Core Category
"Negotiating Uncertainty" -- integrates Risk Management + Validation Seeking

## Saturation Status
- Category 1: SATURATED (round 3) | Category 2: SATURATED (round 4)

## Theoretical Propositions
1. Higher perceived risk increases validation-seeking frequency
2. ...

## Verdict
THEORY GENERATED | PARTIAL (needs theoretical sampling) | INSUFFICIENT DATA
```

## Skill Chains
- After coding -> `[coding-scheme]` to formalize inter-rater reliability
- After themes emerge -> `[thematic-analysis]` for complementary pattern reporting
- Before grounded theory -> `[meta-synthesis]` to review existing theories
- Before grounded theory -> `[research-ingest]` to load and preprocess raw data
