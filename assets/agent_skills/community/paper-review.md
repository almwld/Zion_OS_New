---
name: paper-review
description: Structured review of research papers — methodology, findings, relevance, limitations
version: 1.0.0
execution-mode: advisory
argument-hint: <paper-path-or-url>
category: hummbl-research
status: candidate
---
# Paper Review

Structured review of a research paper. Reads the paper (PDF or text), scores on 6 dimensions, extracts key findings, and produces a review card with action items.

## Arguments
- `<paper-path>` — Absolute path to PDF or text file (use Read tool)
- `<url>` — URL to fetch (use WebFetch tool)
- `--focus <topic>` — Relevance lens (default: AI governance)

## Procedure

### 1. Read the Paper

For PDFs:
- Use the Read tool with `pages` parameter for large documents
- Read abstract + introduction first (pages 1-3)
- Then methodology and results sections
- Finally discussion and references

For URLs:
- Use WebFetch to retrieve content
- Extract main body text

### 2. Extract Metadata

Record:
- **Title**: Full paper title
- **Authors**: All authors with affiliations
- **Published**: Date and venue (journal, conference, preprint server)
- **DOI/URL**: Permanent identifier
- **Pages**: Total page count

### 3. Score on 6 Dimensions

Each dimension scored 1-5 with brief justification:

| Dimension | 1 (Poor) | 3 (Adequate) | 5 (Excellent) |
|-----------|----------|--------------|---------------|
| **Methodology** | No clear method, anecdotal | Standard method, some gaps | Rigorous, reproducible, well-justified |
| **Sample/Scale** | N<10 or single case | N=30-100 or 3-5 orgs | N>1000 or comprehensive survey |
| **Statistical Rigor** | No stats or misapplied | Basic stats, some p-values | Pre-registered, effect sizes, corrections |
| **Reproducibility** | No data/code shared | Partial artifacts | Full code, data, environment |
| **Relevance** | Tangential to our work | Related domain, some overlap | Directly applicable to your organization/governance |
| **Limitations Honesty** | No limitations discussed | Brief mention | Thorough, identifies threats to validity |

**Composite Score**: Average of 6 dimensions, graded:
- 4.5-5.0: A (Must-cite, high-confidence reference)
- 3.5-4.4: B (Useful reference, note caveats)
- 2.5-3.4: C (Background only, verify claims independently)
- 1.5-2.4: D (Weak evidence, do not cite without corroboration)
- 1.0-1.4: F (Unreliable, do not use)

### 4. Extract Key Findings

Identify 3-5 key findings with:
- The claim (one sentence)
- The evidence (what supports it)
- The confidence (high/medium/low based on methodology)

### 5. Identify Limitations

- What the authors acknowledge
- What they missed (your assessment)
- Threats to external validity (would results generalize?)

### 6. Determine Action Items

Based on relevance score:
- **5 (Direct)**: Ingest to ledger, cite in specs, update positioning
- **4 (Strong)**: Add to bibliography, reference in research docs
- **3 (Moderate)**: Note for background, monitor author's future work
- **2 (Weak)**: File but do not cite
- **1 (None)**: No action

## Output Format

```
Paper Review | <short-title>

Metadata:
  Title:     <full title>
  Authors:   <authors>
  Published: <date, venue>
  DOI:       <doi or url>

Scores:
  Methodology:       <N>/5  <one-line justification>
  Sample/Scale:      <N>/5  <one-line justification>
  Statistical Rigor: <N>/5  <one-line justification>
  Reproducibility:   <N>/5  <one-line justification>
  Relevance:         <N>/5  <one-line justification>
  Limitations:       <N>/5  <one-line justification>
  ---
  Composite:         <N.N>/5 (Grade: <A-F>)

Summary:
  <1-paragraph summary of the paper's contribution>

Key Findings:
  1. <claim> — Evidence: <evidence> — Confidence: <H/M/L>
  2. <claim> — Evidence: <evidence> — Confidence: <H/M/L>
  3. <claim> — Evidence: <evidence> — Confidence: <H/M/L>

Limitations:
  - Acknowledged: <what authors noted>
  - Unacknowledged: <what you identified>
  - Generalizability: <assessment>

Action Items:
  [ ] <action based on relevance score>
  [ ] <action>

Next action: <suggestion>
```

## Notes

- For preprints (arXiv, bioRxiv): note lack of peer review in the assessment
- For conference papers: note page limits may constrain methodology detail
- Always check if a newer version exists (v2, v3, journal publication)
- Cross-reference claims against our existing ledger entries

## Skill Chains

| After completing... | Consider... |
|---|---|
| Grade A paper | `[research-ingest]` (persist to ledger), `[deep-research]` (follow citations) |
| Grade B paper | `[research-digest]` (add to digest), `[competitive-intel]` (if competitor work) |
| Multiple reviews | `[concept-map]` (visualize research landscape) |
| Actionable finding | `[decision-log]` (if it changes our approach) |
