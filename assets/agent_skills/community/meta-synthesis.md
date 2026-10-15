---
name: meta-synthesis
description: Qualitative meta-synthesis - aggregate findings across qualitative studies using meta-ethnography or thematic synthesis
version: 0.1.0
execution-mode: advisory
argument-hint: "<study-paths...> [--method meta-ethnography|thematic|framework]"
category: hummbl-research
status: candidate
---
# meta-synthesis | Qualitative Meta-Synthesis

## When to Use
- Aggregating findings across multiple qualitative studies on the same phenomenon
- Building higher-order interpretations beyond individual study findings
- Translating concepts between studies (meta-ethnography)
- Informing policy or practice with synthesized qualitative evidence

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: paths to primary qualitative studies (reports, papers, theses)
- `--method`: meta-ethnography (Noblit & Hare), thematic (Thomas & Harden), framework (framework synthesis)
- Default method: `thematic`

### 2. Study Identification and Screening
- Define inclusion/exclusion criteria (topic, methodology, quality threshold)
- Screen studies against criteria
- Document PRISMA-style flow (identified, screened, included)
- Assess methodological quality (e.g., CASP qualitative checklist)

### 3. Data Extraction
- Extract findings (themes, categories, concepts) from each study
- Extract study context: setting, population, methodology, sample
- Record first-order constructs (participant quotes) and second-order constructs (author interpretations)

### 4. Synthesis -- Method-Specific

#### Meta-Ethnography (Noblit & Hare)
- Determine relationships between studies: reciprocal (similar), refutational (contradictory), line of argument (synthesis)
- Translate concepts across studies (preserve meaning across contexts)
- Produce third-order constructs (synthesized interpretations)

#### Thematic Synthesis (Thomas & Harden)
- Line-by-line code all extracted findings
- Group codes into descriptive themes
- Develop analytical themes (going beyond original studies to generate new insights)

#### Framework Synthesis
- Apply a priori framework (e.g., from policy or existing theory)
- Index extracted data into framework domains
- Identify gaps and additions to the framework

### 5. Assess Confidence (GRADE-CERQual)
- For each synthesized finding, assess: methodological limitations, coherence, adequacy, relevance
- Assign confidence level: high, moderate, low, very low

### 6. Reporting
- Present synthesized findings with supporting study references
- Include tables mapping findings to source studies
- Discuss how synthesis extends beyond individual studies

## Output Format

```
meta-synthesis | <N studies>

## Configuration
- Method: Thematic synthesis
- Studies included: N | Studies screened: M | Excluded: K

## Study Characteristics
| Study | Setting | Method | Sample | Quality |
|-------|---------|--------|--------|---------|
| A     | hospital| IPA    | 12     | High    |
| B     | clinic  | TA     | 20     | Moderate|

## Synthesized Findings
### Finding 1: <Name> (supported by K studies)
- Description: <analytical statement>
- Supporting studies: A, B, C
- CERQual confidence: MODERATE

### Finding 2: <Name> (supported by J studies)
- Description: <analytical statement>
- Supporting studies: A, D
- CERQual confidence: LOW

## Confidence Assessment (GRADE-CERQual)
| Finding | Methodological | Coherence | Adequacy | Relevance | Confidence |
|---------|---------------|-----------|----------|-----------|------------|
| 1       | No concerns   | High      | Adequate | Relevant  | MODERATE   |
| 2       | Concerns      | Moderate  | Limited  | Partial   | LOW        |

## Verdict
SYNTHESIS COMPLETE | PARTIAL (insufficient studies for Finding X) | INSUFFICIENT EVIDENCE
```

## Skill Chains
- After synthesis -> `[research-ingest]` to load and archive synthesized evidence
- Before meta-synthesis -> `[meta-analysis]` for mixed-methods integration (if quantitative studies exist)
