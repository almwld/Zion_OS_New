---
name: bki-evidence-flywheel
description: Search for new empirical evidence supporting BKI propositions (belonging, cognitive science, psychological safety, AI governance) and route findings to citation library and pitch materials.
version: 0.2.0
execution-mode: advisory
argument-hint: "[focus: belonging|governance|psych-safety|all|disconfirm]"
category: governance-compliance
status: candidate
---
# BKI Evidence Flywheel

Runs a daily or weekly search for new empirical evidence supporting BKI propositions, grades each result, and routes findings to the citation library and HUMMBL pitch materials.

**Updated 2026-09-04** after 10-lane evidence flywheel run (142 findings, 75 HIGH-grade). Propositions revised to qualified form based on disconfirmation evidence. Accountability integrated as co-equal variable. See `docs/research/2026-09-04_bki-evidence-flywheel-10-lane-synthesis.md` for the full evidence base.

## Usage

```
[bki-evidence-flywheel]              # Search all 6 proposition areas
[bki-evidence-flywheel] belonging    # Focus: Prop 1 + Prop 4 (cognitive scaffolding, symbolic systems)
[bki-evidence-flywheel] governance   # Focus: AI governance compliance failure (HUMMBL pitch)
[bki-evidence-flywheel] psych-safety # Focus: Prop 1 convergent (psychological safety)
```

## What This Skill Does

BKI theory rests on 4 propositions. **As of 2026-09-04, all propositions have been revised to qualified form** based on a 10-lane evidence flywheel that ran mandatory disconfirmation queries. The strong (unconditional) forms did not survive; the qualified forms did.

### Revised Propositions (P1*–P4*, effective 2026-09-04)

1. **Cognitive Scaffolding (P1*)** — Belonging *amplifies* higher-order cognition by reducing threat-mediated PFC suppression. It is **sufficient but not necessary** (HROs substitute procedure for belonging). It **requires accountability** to convert safety into performance (inverted-U boundary: very high PS without accountability reduces effort — Eldor, Hodor & Cappelli 2023, OBHDP).
2. **Relational Validation (P2*)** — Belonging **moderates the implementation effectiveness** of authority-bearing knowledge artifacts. Procedurally encoded knowledge (checklists, standards) can transfer without belonging (Pronovost 2006 NEJM; Haynes 2009 NEJM), but belonging predicts **depth of behavioral internalization** (Urbach 2014 NEJM boundary case).
3. **Embodied Knowing (P3*)** — Embodied participation *accelerates acquisition* of complex, judgment-laden expertise. For **simple procedural skills**, online/AI instruction can match or exceed in-person (Fazlollahi 2022 JAMA: AI tutor outperformed expert surgeons 2.6×). Embodied schooling matters most as a **developmental and equity scaffold** for under-resourced or not-yet-autonomous learners (Betthäuser 2023 Nature Human Behaviour).
4. **Symbolic Systems (P4*)** — Shared symbolic systems **emerge** from belonging structures (confirmed experimentally: Reagans, Burt & Liu 2026). But externally-imposed systems can be **adopted at surface level** via institutional pressure (ISO 9001: 1.3M+ orgs, no shared belonging). Belonging predicts **deep internalization**, not surface adoption. For semantically deep systems (SNOMED CT), low belonging actively impedes implementation (Højen 2014).

### The Accountability Co-Factor

The 10-lane flywheel independently confirmed across multiple lanes that **accountability is a co-equal variable with belonging, not a derivative of it**. The Broccolilly equation (S×T×I×C×D=R) should incorporate accountability explicitly. Best performance = belonging + accountability; belonging without accountability degrades into conformity, free-riding, and deviance (Pearsall & Ellis 2010 JAP; Higgins 2022 AMD).

### Original Propositions (superseded but retained for reference)

1. ~~Belonging is a neurobiological prerequisite for higher-order cognition.~~ → P1*
2. ~~Knowledge claims gain authority through belonging networks, not logical validity alone.~~ → P2*
3. ~~Wisdom transmits somatically through belonging relationships; instruction delivers propositional content only.~~ → P3*
4. ~~Shared symbolic languages emerge FROM belonging structures, not the reverse.~~ → P4*

This skill continuously feeds new evidence into the BKI corpus. Evidence quality degrades over time — this is the antidote.

## Live API Sources (Free, Keyless)

Pull structured metadata from free scholarly APIs. **Note: `~/bin/free_apis.py` may not exist on all hosts.** Use curl directly as the reliable fallback:

```bash
# OpenAlex — search 250M works for BKI-related evidence (CC0, no key)
curl -s "https://api.openalex.org/works?search=belonging+cognitive+performance+psychological+safety&per-page=25&mailto=reuben@hummbl.io" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{w[\"id\"]}|{w.get(\"doi\",\"\")}|{w[\"publication_year\"]}|{w[\"title\"][:120]}|{w[\"cited_by_count\"]}') for w in d.get('results',[])]"

# OpenAlex — fetch a specific work by DOI
curl -s "https://api.openalex.org/works/https://doi.org/10.1038/s41586-023-06647-8?mailto=reuben@hummbl.io" | python3 -m json.tool

# PubMed — biomedical evidence on belonging and health outcomes
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=social+belonging+cognitive+function&retmax=25&retmode=json" | python3 -m json.tool

# DOI verification (lighter than OpenAlex, works when OpenAlex is rate-limited)
curl -s -o /dev/null -w "%{http_code}" -L "https://doi.org/10.1145/3600211.3604674"
```

**Rate limit awareness:** OpenAlex enforces ~10 req/sec for polite pool (with mailto). If running parallel lanes (e.g., 10 subagents), use `sleep 1` between queries or you will hit 429. doi.org resolution is more reliable for batch DOI verification.

OpenAlex is the primary scholarly search source — it covers 250M works with citation counts, DOIs, and open access URLs. Use it to find evidence, then use webfetch or Supadata to fetch full text when the OA URL is unavailable.

## Supadata Sources

Use the local Supadata CLI to fetch full-text content and video transcripts for deeper evidence:

```bash
# Set key (do once per session)
export SUPADATA_API_KEY="$(cat ~/supadata\ api.txt | grep sd_)"

# Scrape papers from arXiv, PubMed, PsycInfo
python3 ~/bin/supadata.py scrape "https://arxiv.org/abs/2501.12345"

# Extract conference talks on belonging/psychological safety
python3 ~/bin/supadata.py transcript "https://youtube.com/watch?v=..." --text

# Discover new research on academic pages
python3 ~/bin/supadata.py map "https://scholar.google.com/scholar?q=belonging+cognitive+performance"

# Crawl a researcher's publications page
python3 ~/bin/supadata.py crawl "https://example.edu/~researcher/publications" --max-pages 15
```

**Free tier awareness**: 100 credits/month. Use scrape for papers that Scholar Gateway abstracts can't fully evaluate. Reserve transcript extraction for key conference talks likely to contain empirical claims.

## Stage 0: Mandatory Disconfirmation Search (run BEFORE confirmation queries)

**This stage is mandatory.** Do not skip it. The 2026-09-04 10-lane flywheel found that disconfirmation evidence is critical for honest BKI claims — without it, the flywheel becomes a confirmation engine (flagged by 4/9 peer reviewers in the original AAR).

For each proposition, run 2-3 disconfirmation queries BEFORE running confirmation queries. Tag all disconfirmation findings with `DISCONFIRMATION` in the evidence log.

### Disconfirmation Queries (Stage 0)

| Query | BKI Target | What it tests |
|-------|-----------|---------------|
| `"psychological safety groupthink conformity"` | P1* | PS can produce conformity, not cognition |
| `"psychological safety accountability performance"` | P1* | PS without accountability degrades effort |
| `"high reliability organizations psychological safety"` | P1* | HROs substitute procedure for belonging |
| `"checklist surgical safety Pronovost"` | P2* | Knowledge transfers without trust |
| `"expert authority knowledge adoption no trust"` | P2* | Expert authority works regardless of belonging |
| `"online learning effectiveness meta-analysis"` | P3* | Online/remote instruction succeeds |
| `"AI tutoring learning outcomes"` | P3* | AI tutors match or exceed in-person |
| `"ISO standards adoption diffusion organizational"` | P4* | Imposed standards adopt without belonging |
| `"regulatory vocabulary adoption healthcare"` | P4* | Mandated terminology adopts in low-belonging orgs |
| `"belonging intervention replication failure"` | Meta | Replication crisis in belonging interventions |
| `"growth mindset meta-analysis bias correction"` | Meta | Sibling literature replication failures |

### Disconfirmation Grading

Disconfirmation findings are graded the same way as confirmation findings (see Evidence Grading below). Tag them `DISCONFIRMATION` in the evidence log. A HIGH-grade disconfirmation finding that directly contradicts a BKI proposition should trigger a proposition revision recommendation in the run output.

## Stage 1: Confirmation Search Queries

Run OpenAlex/PubMed/web_search for each query below. If `$ARGUMENTS` is set, skip queries not matching the focus area.

| Query | BKI Target | Focus Tag |
|-------|-----------|-----------|
| `"psychological safety team learning meta-analysis"` | P1*: Cognitive Scaffolding | psych-safety |
| `"belonging cognitive performance workplace"` | P1*: Cognitive Scaffolding | belonging |
| `"amygdala prefrontal cortex social safety"` | P1*: Neurobiological mechanism | belonging |
| `"epistemic trust knowledge authority"` | P2*: Relational Validation | belonging |
| `"messenger effect credibility in-group"` | P2*: Relational Validation | belonging |
| `"trusted messenger vaccine hesitancy"` | P2*: Relational Validation | governance |
| `"apprenticeship embodied knowledge tacit"` | P3*: Embodied Knowing | belonging |
| `"habitus Bourdieu empirical"` | P3*: Embodied Knowing | belonging |
| `"shared mental models team cognition"` | P4*: Symbolic Systems | belonging |
| `"community of practice language emergence"` | P4*: Symbolic Systems | belonging |
| `"AI governance compliance failure implementation"` | HUMMBL pitch anchor | governance |
| `"checkbox culture compliance theater"` | HUMMBL pitch anchor | governance |
| `"AI ethics guidelines operationalization gap"` | HUMMBL pitch anchor | governance |
| `"belonging intervention meta-analysis"` | Meta-evidence | belonging |
| `"Walton Cohen belonging replication"` | Meta-evidence | belonging |

Execute all queries when no argument is provided. For focused runs, execute only queries whose Focus Tag matches `$ARGUMENTS`. The `disconfirm` argument runs ONLY Stage 0 queries.

## Evidence Grading (inline [evidence-grade] logic)

For each search result, assign a grade before routing:

| Grade | Criteria |
|-------|---------|
| **HIGH** | Peer-reviewed journal publication; DOI resolves to published article; not retracted |
| **MEDIUM** | Conference paper (peer-reviewed proceedings) or preprint with clear methodology and plausible results |
| **MEDIUM-LOW** | Preprint without clear peer-review track; working paper; industry report with named authors and methodology |
| **LOW** | Blog post; news article; press release; no named methodology |

Apply `[preprint-scan]` logic: check whether the source is arXiv/SSRN/bioRxiv — if so, flag as MEDIUM-LOW pending journal publication confirmation.

Do NOT inflate grades to satisfy narrative needs. An unsourced statistic in a peer-reviewed paper that was itself citing a blog post is LOW.

## Routing Rules

Apply these routing decisions based on grade:

### HIGH — Verified candidate
1. **Author extraction (mandatory):** Use webfetch on the DOI URL or OpenAlex metadata to extract the full author list. HIGH-grade findings with `[not provided]` authors are flagged INCOMPLETE, not VERIFIED. (Origin: 2026-09-04 flywheel — 24/31 original entries had `[not provided]` authors.)
2. Append to `$HOME/PROJECTS/arcana/bki_citation_audit.md` under the matching proposition section as `VERIFIED CANDIDATE`.
3. Add a note: `FLAG: pitch-ready — route to copywriter agent for HUMMBL pitch material update`.
4. Log to evidence log (see Output Format below).

### MEDIUM — Unverified, needs review
1. Append to `$HOME/PROJECTS/arcana/bki_citation_audit.md` as `UNVERIFIED (needs further review)`.
2. Add a note: `FLAG: BKI_01_THEORY_MASTER.md consideration — verify journal status before citing`.
3. Log to evidence log.

### MEDIUM-LOW — Preprint track
1. Log to evidence log only with note `preprint — re-check in 90 days for publication status`.
2. Do NOT route to citation audit until journal status confirmed.

### LOW — Log only
1. Log to evidence log only.
2. Do NOT route to any citation file.

## Output Format

Append findings to `$HOME/PROJECTS/arcana/bki_evidence_log.md` using this format for each result:

```
---
date: YYYY-MM-DD
query: "<exact query string>"
result_title: "<paper/article title>"
doi_or_url: "<DOI or URL>"
authors: "<author list — mandatory for HIGH grade, use webfetch if not in API response>"
venue: "<journal/conference/preprint server>"
grade: HIGH | MEDIUM | MEDIUM-LOW | LOW
tag: CONFIRMATION | DISCONFIRMATION | BOUNDARY
bki_proposition: "P1*: Cognitive Scaffolding | P2*: Relational Validation | P3*: Embodied Knowing | P4*: Symbolic Systems | HUMMBL Pitch | Meta"
routing: "citation_audit VERIFIED | citation_audit UNVERIFIED | log only (preprint) | log only (LOW)"
notes: "<any key finding, flag, or follow-up action>"
---
```

If the file does not exist, create it with a header:
```
# BKI Evidence Log

Append-only log of search findings from [bki-evidence-flywheel].
Format: one entry per result, newest at bottom.
Managed by: [bki-evidence-flywheel] skill
```

## Skill Output Header

Lead every run with:
```
BKI Evidence Flywheel | focus: <all|belonging|governance|psych-safety> | YYYY-MM-DD
════════════════════════════════════════════════════════════════
```

Then a summary table:
```
| Query | Results Found | HIGH | MEDIUM | LOW | Routed to Citation Audit |
|-------|--------------|------|--------|-----|--------------------------|
| ...   | ...          | ...  | ...    | ... | ...                      |
```

Followed by individual entries for any HIGH or MEDIUM findings (skip LOW except in the table count).

## Downstream Actions

After completing the run:

- **HIGH findings exist** → suggest `[bki-cite-audit]` to verify them in context; suggest routing to `copywriter` agent for pitch material update.
- **HUMMBL pitch anchor findings** → note: "Route governance findings to `[arcana-to-pitch]` skill for HUMMBL deck refresh."
- **3+ HIGH findings in one run** → suggest `[research-ingest]` to persist to Cognitive Ledger.
- **HIGH-grade DISCONFIRMATION findings** → flag for proposition revision review. If a disconfirmation finding directly contradicts a current proposition (P1*–P4*), recommend a revision in the run output.
- **No HIGH findings** → state "No HIGH-grade findings this run. MEDIUM candidates logged for review."

## Meta-Evidence Warning (integrated 2026-09-04)

The 10-lane flywheel found serious replication failures in the belonging intervention literature. **Any claim citing belonging intervention effects MUST be presented with boundary conditions:**

- **Alam, Oreopoulos & Petronijevic (2026, NBER WP 35230, N≈12,000):** Null effects on grades, persistence, and no subgroup heterogeneity via ML.
- **WWC Intervention Report (2021):** "Mixed effects" on achievement/progression; "no discernible effects" on enrollment.
- **Macnamara & Burgoyne (2023, Psych Bull, 63 studies, N=97,672):** Growth-mindset meta: d=0.05, non-significant after bias correction; highest-quality subset d=0.02 (ns).
- **Many Labs 2 (Klein et al. 2018):** 54% replication rate, median d shrinks 0.60→0.15.

**Rule:** Do NOT present belonging intervention effects as universal. Effects are context-dependent, group-specific, and subject to replication failure. Always cite the boundary condition (e.g., "works only when context affords belonging" — Walton 2023; "works only where peer norms align" — Yeager 2019).

## Constraints

- DO NOT fabricate DOIs, titles, or author names. If a search returns no results for a query, log "no results" for that query.
- DO NOT upgrade a grade to justify routing. Evidence quality rules are strict.
- DO NOT modify existing entries in `bki_citation_audit.md` — append only.
- DO NOT post to the coordination bus unless explicitly asked.
- DO NOT skip Stage 0 (disconfirmation). A flywheel without disconfirmation is a confirmation engine, not an evidence engine.
- DO NOT present belonging intervention effects as universal without boundary conditions (see Meta-Evidence Warning above).
- Mark any inferred journal status as `[inferred — verify]`.

## Related Skills

- `[bki-cite-audit]` — audit BKI bibliography for phantom citations and claim-source mismatch
- `[preprint-scan]` — check arXiv/SSRN source peer-review status
- `[research-ingest]` — persist HIGH findings to Cognitive Ledger
- `[evidence-grade]` — standalone evidence grading (this skill embeds the logic inline)
- `[arcana-to-pitch]` — convert research findings into HUMMBL pitch materials
- `[daily-research]` — broader daily evidence collection across 6 domains

## Changelog

- **0.2.0 (2026-09-04):** Propositions revised to P1*–P4* (qualified form). Stage 0 mandatory disconfirmation added. Accountability integrated as co-equal variable. Author extraction made mandatory for HIGH grade. Meta-evidence warning added. API instructions updated (curl fallback for missing free_apis.py). Query coverage expanded to all 4 propositions + HUMMBL pitch + meta-evidence. Based on 10-lane evidence flywheel (142 findings, 75 HIGH-grade).
- **0.1.0:** Initial version. 4 propositions in strong form. Confirmation queries only. free_apis.py as primary API path.
