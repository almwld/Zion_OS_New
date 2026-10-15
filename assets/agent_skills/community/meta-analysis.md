---
name: meta-analysis
description: PRISMA-compliant systematic review pipeline — search, screen, extract, synthesize. Produces a full meta-analysis or scoping review paper draft.
version: 0.1.0
execution-mode: advisory
argument-hint: "<topic> [--type systematic|scoping|meta] [--venue <venue>] [--n <target-inclusions>]"
category: fleet-ops
status: candidate
---
# [meta-analysis]

Run a PRISMA 2020-compliant systematic review pipeline on a given topic. Produces:
1. A documented search protocol (PRISMA-searchable)
2. A screening decision table (inclusions/exclusions with reasons)
3. A data extraction table (structured per-paper findings)
4. A full paper draft (systematic review or scoping review format)

## Arguments

```
[meta-analysis] "benchmark contamination in LLM evaluation"
[meta-analysis] "kill switches in AI systems" --type systematic --venue "ACM Computing Surveys"
[meta-analysis] "prompt injection taxonomy" --type scoping --n 30
[meta-analysis] "multi-agent governance" --type systematic --venue "IEEE TNNLS"
```

- `--type systematic` (default) — PRISMA systematic review with quality assessment
- `--type scoping` — Arksey & O'Malley scoping review (broader, no quality gate)
- `--type meta` — quantitative meta-analysis (requires effect sizes in included studies)
- `--venue` — target venue (default: ACM Computing Surveys)
- `--n` — target number of included studies (default: 20)

## Five-Stage Pipeline

### Stage 1: PROTOCOL — Define the Review

Generate a PRISMA-compliant search protocol:

```
Population/Problem: <who or what is being studied>
Intervention: <what intervention, technology, or approach>
Comparison: <what it's compared to, if any>
Outcome: <what is measured or synthesized>
Study type: <empirical / theoretical / grey literature>
```

Generate Boolean search strings for:
- **ACM Digital Library**: `"<term1>" AND "<term2>" NOT "<exclusion>"`
- **IEEE Xplore**: same structure
- **arXiv**: `ti:"<term>" OR abs:"<term>"`
- **Google Scholar**: natural language + citation count filter
- **Semantic Scholar**: use Scholar Gateway MCP

Inclusion criteria:
- [ ] Published after <year> (default: 2020)
- [ ] Primary research or grey literature with evidence
- [ ] Topic directly addresses the PICO question
- [ ] English language (or includes English abstract)

Exclusion criteria:
- [ ] Purely theoretical without empirical or formal claim
- [ ] Duplicate (earlier version of included paper)
- [ ] No abstract/insufficient detail to screen

### Stage 2: SEARCH — Execute the Literature Search

Dispatch parallel search agents — one per database. Each agent:
1. Runs the search string
2. Returns: title, authors, year, venue, abstract, URL/DOI
3. Deduplicates against other agents' results

**Agent prompt template (copy for each database):**
```
Search <DATABASE> for papers on: <TOPIC>

Search string: <BOOLEAN_STRING>

For each result, return a row in this table format:
| ID | Title | Authors | Year | Venue | Abstract (50 words) | URL |

Return at minimum 15 results, maximum 50.
Stop at 50 even if more exist — flag the count.
Report in under 800 words.
The LAST thing in your response must be a ## FINDINGS section — write nothing after it.
FINDINGS format: "N results found in <DATABASE>"
```

For Scholar Gateway MCP, call:
```python
mcp__claude_ai_Scholar_Gateway__semanticSearch(query="<topic>", limit=20)
```

For arXiv, use WebSearch:
```
site:arxiv.org "<term1>" "<term2>" after:2020
```

### Citation Verification Gate (between Stage 2 and Stage 3)

Before screening, verify all agent-sourced citations are real:

For each arXiv ID returned by search agents:
1. If arXiv YYMM > current month → **REJECT** (future ID = fabricated)
2. If author name is a project/acronym, not a person → **FLAG**
3. For remaining: WebSearch `arxiv.org/abs/<ID>` to confirm title matches

Produce a verification table before proceeding to Stage 3:
```
| arXiv ID | Claimed Title | Verified | Status |
|----------|--------------|----------|--------|
| 2406.14644 | Survey on Data Contamination... | Title matches | VERIFIED |
| 2603.24775 | Agent Identity Protocol | Not found | FABRICATED — EXCLUDE |
```

Only VERIFIED and PLAUSIBLE papers proceed to screening. This gate was added after the Apr 14 2026 paper sprint found 0/24 fabricated citations in M1 (which used live search), but 3 fabricated citation families in paper drafts that relied on agent memory.

### Stage 3: SCREEN — Inclusion/Exclusion Decisions

After search agents return, produce a PRISMA flow diagram count:

```
Records identified: N_total
  After deduplication: N_dedup
  After title/abstract screening: N_title
  Excluded (reasons):
    - Out of scope: N_oos
    - Insufficient evidence: N_ie
    - Duplicate: N_dup
  Full text assessed: N_fulltext
  Excluded after full text:
    - Methodology too weak: N_meth
    - Wrong outcome measure: N_outcome
  INCLUDED: N_included
```

For each candidate paper, apply screening rubric:

| Criterion | Pass | Fail |
|-----------|------|------|
| Addresses PICO question | Directly or substantially | Tangentially only |
| Has evidence | Empirical data, formal proof, or case study | Opinion only |
| Sufficient detail | Abstract has extractable claims | No abstract |
| Not a duplicate | First or final version | Preprint of included published paper |

### Stage 4: EXTRACT — Data Extraction

For each included study, fill this extraction form:

```markdown
## Paper [ID]: <Title>

**Citation**: Author(s), Year, Venue, DOI
**Study type**: Empirical / Theoretical / System description / Survey
**N**: Sample size or system scale (N/A if not applicable)
**Methods**: <1-2 sentence description of methods>
**Key Finding 1**: <claim> — Evidence: <what supports it> — Confidence: High/Med/Low
**Key Finding 2**: (repeat)
**Key Finding 3**: (repeat)
**Quality score**: <1-5 using paper-review rubric>
**Relevance to PICO**: Direct / Partial / Background
**Limitations**: <what authors acknowledge + your assessment>
**Tags**: <thematic codes, e.g., #benchmark-decay #evaluation #contamination>
```

Dispatch one extraction agent per 8-10 papers (parallel). Each agent reads the paper (WebFetch for URL, Read for local file) and fills the form.

### Stage 5: SYNTHESIZE — Write the Paper

With extraction tables complete, dispatch the synthesis agent:

**For systematic reviews (ACM Computing Surveys format):**
```
Sections:
1. Abstract (250 words — state PICO, N included, main findings, implications)
2. Introduction (research question, why this review now, contribution)
3. Background (key concepts, prior reviews)
4. Methodology (PRISMA protocol, search strings, dates, screening criteria)
5. Results (organize by theme, not by paper — cite extraction table)
6. Discussion (answer the PICO question, compare to prior reviews, limitations)
7. Future Directions
8. Conclusion
9. References (all N_included studies + additional methodological refs)
10. Appendix A: PRISMA Flow Diagram (text table)
11. Appendix B: Full Extraction Table
```

**For scoping reviews (Arksey & O'Malley / PRISMA-ScR format):**
Same structure but no quality assessment gate; Stage 3 screen is less strict.

**For quantitative meta-analysis:**
Additional requirements before Stage 5:
- Extract effect sizes (d, r, OR, RR) from each included study
- Compute pooled estimate + 95% CI (report formula, not just result)
- Produce forest plot data table (study label, effect, CI, weight)
- Report heterogeneity (I² statistic, Q test)
- Funnel plot assessment for publication bias

## Output Format

```
[meta-analysis] | <topic> | <YYYY-MM-DD>
════════════════════════════════════════

## Protocol
PICO: <statement>
Search string (Semantic Scholar): <string>
Date range: <from>–present
Inclusion: <criteria list>
Exclusion: <criteria list>

## PRISMA Flow
Identified: N | Deduplicated: N | Screened: N | Included: N

## Included Studies (N)
| ID | Authors | Year | Venue | Type | Quality | Key Finding |
|----|---------|------|-------|------|---------|-------------|
| P01 | ... | ... | ... | ... | 4.2 | ... |

## Thematic Synthesis
### Theme 1: <name>
<synthesis paragraph citing P01, P07, P12...>

### Theme 2: <name>
...

## Answer to PICO
<direct answer to the research question, graded by evidence strength>

## Gaps Identified
- <gap 1 — no papers address X>
- <gap 2 — conflicting evidence on Y>

## Paper Status
Draft: <YES/NO — has synthesis agent been dispatched?>
Draft path: <file path if written>

## Next Actions
- [ ] Dispatch paper-writing agent
- [ ] Peer review with [paper-review]
- [ ] Update dashboard META
```

## Skill Chains

After `[meta-analysis]`:
- Draft produced → `[paper-review]` for internal peer review
- High-value findings → `[research-ingest]` to persist to ledger
- Ready for venue → `[paper]` (LaTeX conversion) or `[pr-summary]`

Before `[meta-analysis]`:
- For OpenAlex/PubMed literature searches (scholarly works, biomedical literature) -> `[free-apis]` (`python ~/bin/free_apis.py openalex "<query>"` or `python ~/bin/free_apis.py pubmed "<query>"`)
- For free-tier inference for meta-analysis synthesis -> `[reasoning-router]` (`route`)

## Pre-Built Search Strings

### M1 — Benchmark Decay / Evaluation Validity in LLMs
```
Semantic Scholar: "benchmark" AND ("contamination" OR "saturation" OR "Goodhart" OR "decay") AND "language model"
arXiv: ti:("benchmark" "contamination") OR ti:("evaluation" "validity" "language model")
ACM DL: "benchmark contamination" OR "evaluation validity" AND "large language model"
```

### M2 — Prompt Injection Attacks
```
Semantic Scholar: "prompt injection" AND ("attack" OR "defense" OR "mitigation")
arXiv: ti:"prompt injection" OR abs:"indirect prompt injection"
```

### M3 — Kill Switch / Corrigibility in AI
```
Semantic Scholar: "corrigibility" OR ("kill switch" AND "AI") OR "shutdown problem"
arXiv: ti:("corrigibility" OR "shutdown" OR "interruptibility") AND "artificial intelligence"
```

### M4 — Multi-Agent AI Governance
```
Semantic Scholar: "multi-agent" AND ("governance" OR "coordination" OR "safety") AND ("LLM" OR "language model")
```

### M5 — Delegation / Authorization in Agentic Systems
```
Semantic Scholar: "delegation" AND ("agentic" OR "AI agent") AND ("authorization" OR "access control")
```

## PRISMA Template Pointer

For the full PRISMA 2020 checklist and paper template, see:
`~/.agents/skills/meta-analysis/PRISMA_TEMPLATE.md`

## Notes

- Never fabricate paper counts, effect sizes, or inclusion/exclusion decisions
- Every excluded paper should have a documented reason
- Mark uncertain quality scores [UNCERTAIN] — do not inflate
- If N_included < 10, downgrade from meta-analysis → narrative review
- Report publication bias risk (grey literature, language bias)
- This skill is advisory — it produces drafts for human review before submission
