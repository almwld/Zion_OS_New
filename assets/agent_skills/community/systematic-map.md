---
name: systematic-map
description: Systematic evidence mapping - breadth-first evidence inventory across a research question without quality appraisal
version: 0.1.0
execution-mode: advisory
argument-hint: "<question> [--sources pubmed|scopus|gs] [--years 2015-2026]"
category: fleet-ops
status: candidate
---
# systematic-map | Systematic Evidence Mapping

## When to Use
- Mapping the breadth of evidence on a research question (not depth)
- Identifying evidence clusters and gaps to inform future systematic reviews
- Inventorying diverse study designs without quality appraisal (unlike systematic review)
- Scoping a topic before committing to a full systematic review or meta-analysis

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: research question or topic statement
- `--sources`: comma-separated databases to search (pubmed, scopus, gs, embase, cochrane)
- `--years`: publication year range (default 2015-2026)
- Defaults: `pubmed,scopus`, `2015-2026`

### 2. Define Scope
- Frame the research question (PCC: Population, Concept, Context for mapping)
- Define inclusion criteria: topic relevance, study design (all designs accepted), language, year range
- Explicitly exclude quality appraisal -- mapping is about breadth, not quality

### 3. Search Strategy
- Develop search terms with synonyms and MeSH terms
- Execute searches across specified databases
- Export results (RIS/BibTeX) and deduplicate
- Document search dates, terms, and hit counts per database

### 4. Screening
- Title/abstract screening against inclusion criteria
- Use dual screening where possible (two reviewers, resolve conflicts)
- Document exclusion reasons at full-text stage
- PRISMA flow diagram: identified, screened, included

### 5. Data Extraction and Coding
- Extract per study: citation, year, design, population, setting, outcomes reported
- Code studies into categories (design type, topic sub-area, population, geography)
- Do NOT extract effect sizes or quality ratings (that is for systematic review)

### 6. Evidence Map Construction
- Create visual map: matrix of topic sub-areas vs. study designs
- Identify evidence clusters (well-populated cells) and gaps (empty cells)
- Generate summary charts: publications per year, per design, per population

### 7. Gap Analysis and Reporting
- Report evidence clusters suitable for future systematic review or meta-analysis
- Report evidence gaps requiring primary research
- Provide recommendations for next steps (depth review vs. primary study)

## Output Format

```
systematic-map | <question>

## Configuration
- Sources: PubMed, Scopus | Years: 2015-2026
- Studies identified: M | After dedup: K | Included: N

## PRISMA Flow
- Identified: M records (PubMed: A, Scopus: B)
- Duplicates removed: D
- Screened: K | Excluded at T/A: E | Full-text assessed: F
- Included: N

## Evidence Map (Topic Sub-area x Design)
| Sub-area        | RCT | Cohort | Qual | Mixed | Total |
|-----------------|-----|--------|------|-------|-------|
| Prevalence      | 2   | 15     | 0    | 1     | 18    |
| Interventions   | 12  | 8      | 3    | 5     | 28    |
| Experiences     | 0   | 0      | 9    | 2     | 11    |
| Policy          | 0   | 1      | 2    | 0     | 3     |

## Summary Charts
- Publications/year: 2015 (4) -> 2026 (18) | Trend: INCREASING
- Designs: RCT (14), Cohort (24), Qualitative (14), Mixed (8)
- Populations: adults (40), pediatric (12), elderly (8)

## Gap Analysis
- Clusters: Interventions/RCT (12 studies) -> candidate for meta-analysis
- Gaps: Policy/Qualitative (0 studies) -> primary research needed
- Gaps: Experiences/RCT (0 studies) -> expected, design mismatch

## Verdict
MAP COMPLETE | PARTIAL (screening incomplete) | INSUFFICIENT HITS (broaden search)
```

## Skill Chains
- After map complete -> `[meta-analysis]` for depth analysis of evidence clusters
- Before mapping -> `[research-ingest]` to load existing reviews and avoid duplication
- For PubMed literature searches (biomedical abstracts, MeSH terms) -> `[free-apis]` (`python ~/bin/free_apis.py pubmed "<query>"`)
