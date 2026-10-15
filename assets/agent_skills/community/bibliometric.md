---
name: bibliometric
description: Bibliometric analysis - publication counts, h-index, citation impact, co-authorship networks, and journal impact factors
version: 0.1.0
execution-mode: advisory
argument-hint: "<author-or-topic> [--metrics h-index|impact-factor|co-citation]"
category: dev-tools
status: candidate
---
# bibliometric | Bibliometric Analysis

## When to Use
- Quantifying research output and impact for an author, group, or topic
- Evaluating citation metrics (h-index, i10-index, citation totals) for tenure or grant reviews
- Mapping co-authorship or co-citation networks to reveal collaboration structures
- Assessing journal impact factors and publication venue quality

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: author name (with ORCID if available) or research topic
- `--metrics`: comma-separated metrics to compute (h-index, impact-factor, co-citation, co-authorship)
- Defaults: `h-index,impact-factor`

### 2. Data Retrieval
- Resolve author identity (ORCID, Scopus Author ID, Google Scholar profile)
- For topic: construct search query and retrieve publication set from database(s)
- Sources: Google Scholar, Scopus, Web of Science, Crossref, OpenAlex
- Collect per-publication: title, year, venue, citation count, co-authors, DOI

### 3. Publication Productivity Metrics
- Total publications (all, first-author, last-author, corresponding)
- Publications per year (productivity trend)
- Output type breakdown (journal article, conference, review, book chapter)

### 4. Citation Impact Metrics
- Total citations
- h-index: largest h where author has h papers with >= h citations each
- i10-index: number of papers with >= 10 citations (Google Scholar)
- Citations per paper (mean, median) and citation distribution
- Most-cited papers (top 10)

### 5. Journal Impact Factor Analysis
- Map publications to journal venues
- Retrieve journal impact factor (JCR, Scopus CiteScore) for each venue
- Compute weighted impact factor (sum of IF / number of publications)
- Identify top venues by frequency and impact

### 6. Co-Authorship Network
- Build graph: nodes = authors, edges = co-publication (weighted by collaboration count)
- Compute centrality: degree (collaboration breadth), betweenness (bridge role)
- Detect clusters (research groups, institutional collaborations)
- Identify frequent collaborators and core-periphery structure

### 7. Co-Citation Analysis (if requested)
- Build co-citation matrix for retrieved publications
- Cluster frequently co-cited references (intellectual base)
- Map to research fronts via author co-citation or document co-citation

### 8. Reporting
- Present metrics in summary table with trend charts
- Provide context (field norms, career stage benchmarks)
- Flag metric limitations (self-citations, database coverage, field differences)

## Output Format

```
bibliometric | <author-or-topic>

## Configuration
- Target: <author/topic> | Metrics: h-index, impact-factor, co-citation
- Source: Scopus + Google Scholar | Publications retrieved: N

## Productivity
| Metric              | Value |
|---------------------|-------|
| Total publications  | 87    |
| First-author        | 32    |
| Publications/year   | 7.3 (avg) |
| Trend (2015-2026)   | INCREASING |

## Citation Impact
| Metric              | Value |
|---------------------|-------|
| Total citations     | 2,415 |
| h-index             | 24    |
| i10-index           | 38    |
| Citations/paper     | 27.8 (mean), 12 (median) |

## Top-Cited Papers
| Rank | Title                | Year | Citations | Venue      | IF    |
|------|----------------------|------|-----------|------------|-------|
| 1    | <title>              | 2018 | 312       | <journal>  | 8.2   |
| 2    | <title>              | 2020 | 198       | <journal>  | 5.1   |

## Journal Impact
- Weighted average IF: 6.4 | Top venue: <journal> (IF 12.3, 8 publications)
- Venue distribution: 60% Q1, 25% Q2, 15% Q3-Q4

## Co-Authorship Network
- Unique co-authors: 142 | Largest cluster: 38 (research group A)
- Most frequent collaborator: <name> (22 joint publications)

## Metric Caveats
- Self-citations: 8.2% of total (within normal range)
- Database coverage: Scopus may miss non-indexed venues

## Verdict
METRICS COMPUTED | PARTIAL (co-citation incomplete) | INSUFFICIENT DATA (author unresolved)
```

## Skill Chains
- After metrics computed -> `[citation-network]` for structural citation graph analysis
- After analysis -> `[research-ingest]` to archive publication set and metrics
- Before bibliometric analysis -> `[evidence-grade]` to contextualize metrics within evidence assessment
- For OpenAlex queries (publication metadata, citation counts, author data) -> `[free-apis]` (`python ~/bin/free_apis.py openalex "<query>"`)
