---
name: preprint-scan
description: Audit sources before or after ingestion — flag preprints, check peer-review status, detect retractions, recommend confidence adjustments
version: 1.0.0
execution-mode: advisory
argument-hint: "[<arXiv-id|SSRN-id|URL|ledger-tag>] [--ledger] [--tag <tag>]"
status: tested
category: hummbl-research
providers:
  required: [bash, python]
---
# Preprint Scan

Audit research sources for publication status before you build strategy around them.
Catches preprints, retractions, corrections, and unreproduced results — the failures
that make it into pitches, blog posts, and board decks.

**Why this exists:** We have ingested preprint findings and built strategy/content
around them before verifying peer-review status. This skill makes that check routine.

## When to Use
- **Before** `[research-ingest]` — scan sources before they enter the ledger
- **Before** `[blog-draft]` or `[pitch]` — verify every citation is what you think it is
- **After** a deep research swarm returns paper IDs — batch-check all sources
- **Periodically** — scan the ledger for preprint-tagged entries that may now be published
- When a source is SSRN, arXiv, bioRxiv, medRxiv, SSRN, or any non-journal URL

## Arguments

| Argument | Behavior |
|----------|----------|
| `<arXiv:NNNN.NNNNN>` | Check one arXiv preprint |
| `<SSRN:NNNNNNNN>` | Check one SSRN preprint |
| `<URL>` | Fetch page, detect publication venue |
| `--ledger` | Scan all ledger entries for preprint-sourced claims |
| `--ledger --tag <tag>` | Scan ledger entries matching a tag |
| *(no args)* | Interactive — paste source list |

## Source Tier Reference (for confidence calibration)

| Tier | Description | Confidence Floor | Preprint Risk |
|------|-------------|-----------------|---------------|
| S1 | Primary source (official docs, direct lab blogs) | 0.90 | Low |
| S2 | Peer-reviewed published paper | 0.85 | None |
| S2p | Preprint from credible lab (DeepMind, Anthropic, OpenAI, major university) | 0.75 | **Flag** |
| S3 | Quality journalism (TechCrunch, FT, Nature News) | 0.70 | Low |
| S4 | Trade/industry analysis | 0.55 | Low |
| S5 | Blog posts, grey literature | 0.40 | Medium |
| S6 | Social media, unverified secondary | 0.20 | High |

arXiv and SSRN are always S2p until published in a peer-reviewed venue.

## Execution

### 1. Resolve the source

For each source:

```bash
# arXiv — check publication status
# Format: https://arxiv.org/abs/XXXX.XXXXX
# Look for: "Journal-ref:" field (indicates published), submission date, v1 vs latest version
```

```bash
# SSRN — check publication status
# Format: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=XXXXXXXX
# Look for: "Journal" field, "Accepted" status, publication date
```

Use WebFetch to retrieve the abstract page. Extract:
- **Submission date** (when first posted)
- **Journal reference** (if published)
- **Version** (v1 = fresh, v4+ = significantly revised)
- **Retraction notice** (search for "retracted", "withdrawn", "correction")
- **Citation count** if available (Google Scholar via WebSearch)

### 2. Classify each source

| Status | Definition | Action |
|--------|-----------|--------|
| `PEER_REVIEWED` | Published in journal/conference proceedings | No action — S2 confidence applies |
| `PREPRINT_CREDIBLE` | arXiv/SSRN from named lab (DeepMind, Anthropic, etc.) | Downgrade to S2p, add disclosure |
| `PREPRINT_UNKNOWN` | arXiv/SSRN, affiliation unknown | Downgrade to S3, add disclosure |
| `RETRACTED` | Retraction notice found | **HOLD** — remove from any live content immediately |
| `CORRECTED` | Erratum/correction notice found | Re-read paper, verify if claims still hold |
| `UNREPRODUCED` | Results cited but no replication found | Flag; lower confidence to S3 |
| `GREY_LITERATURE` | Not on preprint server, not peer-reviewed | S5 floor |

### 3. Apply confidence adjustments

For ledger entries based on preprints:

```bash
source .venv/bin/activate

# Search for entries with preprint sources
python -m hummbl_governance.cognition search "<topic>" --limit 20

# Post a correction entry if confidence needs adjustment
python -m hummbl_governance.cognition post-verified \
  --agent "preprint-scan" \
  --type correction \
  --content "Source status update: <original claim>. Preprint status: <status>. Confidence adjusted from <old> to <new>. Peer-review status as of <date>: <status>." \
  --evidence "<preprint URL> — status verified <date>" \
  --confidence <adjusted_value> \
  --tags "<original_tags> preprint-status" \
  --supersedes <original_entry_id> \
  --assurance-level SELF
```

### 4. Flag downstream content

If a preprint-sourced claim appears in:
- A blog post draft → add footnote: *"[Paper name] is currently a preprint on [server]; peer review status is pending."*
- A pitch deck → add slide note: *"[Stat] — preprint, peer review pending"*
- A live published piece → add editorial note and re-verify

### 5. Periodic ledger audit

Run monthly or after any large research ingest:

```bash
# Find all entries tagged with 'arXiv' or 'SSRN' or 'preprint'
source .venv/bin/activate
python -m hummbl_governance.cognition search "arXiv" --limit 50
python -m hummbl_governance.cognition search "SSRN" --limit 50
```

For each hit: re-check the source URL. If it's now peer-reviewed, post a correction entry upgrading confidence and removing the preprint flag.

## Output Format

```
Preprint Scan | <source count> sources checked
═══════════════════════════════════════════════

## Summary
- PEER_REVIEWED: N
- PREPRINT_CREDIBLE: N  ← disclosure required in content
- PREPRINT_UNKNOWN: N   ← confidence adjustment required
- RETRACTED: N          ← HOLD — remove from content
- CORRECTED: N          ← re-verify claims

## Source Table
| Source | Status | Lab/Venue | Date | Version | Action |
|--------|--------|-----------|------|---------|--------|
| arXiv:XXXX | PREPRINT_CREDIBLE | DeepMind | Dec 2025 | v2 | Add disclosure |
| SSRN:XXXXXX | PREPRINT_UNKNOWN | Unknown | Mar 2026 | v1 | Downgrade S3 |

## Ledger Adjustments
[list of ledger entries needing confidence updates, with suggested corrections]

## Content Flags
[specific content pieces (blog posts, pitch decks) citing flagged sources]

## Next Check
Suggested re-scan date: <30 days from now>
```

## Disclosures (copy-paste ready)

**For blog posts / articles:**
> *[Paper name] is currently a preprint on [arXiv/SSRN]; peer review status is pending.*

**For pitch decks (slide note):**
> *Source: [paper], preprint (peer review pending). Results from [lab name] red-team studies.*

**For ledger entries:**
> *SOURCE_STATUS: PREPRINT_CREDIBLE — arXiv/SSRN, [lab], submitted [date]. Peer review pending as of [check date].*

## Chains

| After... | Consider... |
|----------|-------------|
| Any retraction found | `[incident]` — treat as a claim integrity incident |
| Source upgraded to peer-reviewed | Update ledger entry + remove disclosure from content |
| Large batch of preprints | `[evidence-grade]` to re-score the full evidence corpus |
| Before pitch or blog | Run this first, then `[content-review]` |
| Check if preprint is now published | `[free-apis]` — OpenAlex tracks publication status (`python ~/bin/free_apis.py openalex "<title-or-author>"`) |

## Base120 Context
- Primary: **IN1** (Evidence Hierarchy) — source tier determines confidence floor
- Related: **DE3** (Categorization) — preprint vs peer-reviewed is a load-bearing distinction
- Related: **SY2** (Error Detection) — catch status drift before it compounds
