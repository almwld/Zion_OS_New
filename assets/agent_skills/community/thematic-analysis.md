---
name: thematic-analysis
description: Qualitative thematic analysis - identify, analyze, and report patterns (themes) in qualitative data using Braun & Clarke's 6-phase method
version: 0.1.0
execution-mode: advisory
argument-hint: "<data-source> [--approach inductive|deductive|hybrid] [--level semantic|latent]"
category: hummbl-research
status: candidate
---
# thematic-analysis | Braun & Clarke Thematic Analysis

## When to Use
- Identifying and reporting patterns (themes) across qualitative datasets
- Flexible analysis when grounded theory is too intensive or framework analysis too rigid
- Combining with survey or interview data for mixed-methods reporting
- Producing accessible qualitative findings for applied audiences

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: path to data source (transcripts, open-ended responses, documents)
- `--approach`: inductive (data-driven), deductive (theory-driven), hybrid (combined)
- `--level`: semantic (explicit content) or latent (underlying ideas)
- Defaults: `inductive`, `semantic`

### 2. Phase 1 -- Data Familiarization
- Read and re-read all data
- Transcribe (if audio) and check transcripts for accuracy
- Note initial observations and patterns in analytic memos

### 3. Phase 2 -- Generating Initial Codes
- Code the entire dataset systematically
- Code for as many potential themes as possible (over-code initially)
- Collate codes relevant to each candidate theme

### 4. Phase 3 -- Searching for Themes
- Sort codes into candidate themes
- Gather all data extracts under each candidate theme
- Visualize as thematic map (mind map or cluster diagram)

### 5. Phase 4 -- Reviewing Themes
- Level 1: Check themes against coded extracts (internal homogeneity)
- Level 2: Check themes against full dataset (external heterogeneity)
- Split, merge, or discard themes as needed

### 6. Phase 5 -- Defining and Naming Themes
- Identify the "essence" of each theme
- Write a one-paragraph analytic narrative per theme
- Ensure theme names are concise and evocative

### 7. Phase 6 -- Producing the Report
- Select vivid extract examples
- Weave analysis with extracts into a coherent narrative
- Position findings relative to existing literature

## Output Format

```
thematic-analysis | <data-source>

## Configuration
- Approach: Inductive | Level: Semantic
- Data sources: N transcripts | Codes generated: M

## Themes
### Theme 1: <Name> (K extracts)
- Essence: <one-sentence analytic statement>
- Sub-themes: A, B, C
- Exemplar: "..." (Participant 4)

### Theme 2: <Name> (J extracts)
- Essence: <one-sentence analytic statement>
- Sub-themes: D, E
- Exemplar: "..." (Participant 12)

## Thematic Map
[Theme 1] -- [Theme 2] -- [Theme 3]
     \              |              /
      [Overarching Concept]

## Saturation
- All themes supported by >= 5 extracts across >= 3 participants

## Verdict
THEMES IDENTIFIED | PARTIAL (thin evidence in Theme X) | INSUFFICIENT DATA
```

## Skill Chains
- After themes identified -> `[coding-scheme]` to formalize codebook
- After analysis -> `[meta-synthesis]` to aggregate with other studies
- Before thematic analysis -> `[research-ingest]` to load and preprocess data
