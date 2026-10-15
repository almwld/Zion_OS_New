---
name: ai-regulation
description: Track AI-specific regulations -- EU AI Act, US executive orders, state bills, sector-specific rules
version: 0.1.0
execution-mode: advisory
argument-hint: "[--jurisdiction us|eu|state|all] [--focus risk-classification|transparency|governance]"
category: governance-compliance
status: candidate
---
# AI Regulation

Track and analyze AI-specific regulations across jurisdictions, including the EU AI Act, US executive orders, state-level AI bills, and sector-specific rules (healthcare, finance, hiring). Maps regulatory requirements to product features and governance controls.

## When to Use
- Assessing regulatory exposure for an AI product or feature
- Tracking new AI legislation that may affect operations
- Preparing compliance documentation for a client engagement
- Evaluating risk classification of an AI system under the EU AI Act

## Execution

### Live Data Fetch (Free APIs)

Before scraping regulatory sites, pull structured data from free APIs to identify recent regulatory actions:

```bash
# Federal Register — recent AI-related rules, notices, and proposed rules
python ~/bin/free_apis.py fedreg search "artificial intelligence" --limit 50 --since 2026-01-01

# Federal Register — filter by specific agencies
python ~/bin/free_apis.py fedreg search "AI machine learning" --agencies "national-institute-of-standards-and-technology" "department-of-commerce" --limit 25

# OpenAlex — scholarly analysis of AI regulation
python ~/bin/free_apis.py openalex search "EU AI Act regulation compliance" --limit 25

# Wikidata — structured data on AI regulations (e.g., EU AI Act)
python ~/bin/free_apis.py wikidata search "EU Artificial Intelligence Act" --limit 5
```

These calls are keyless and return structured data. Use them to surface recent regulatory publications before manual source scraping.

### Supadata Source Fetch

Regulatory texts change. Fetch the canonical source before analysis:

```bash
export SUPADATA_API_KEY="$(cat ~/supadata\ api.txt | grep sd_)"

# EU AI Act — fetch the actual regulation text
python3 ~/bin/supadata.py scrape "https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689"

# NIST AI RMF — fetch the latest framework
python3 ~/bin/supadata.py scrape "https://www.nist.gov/itl/ai-ri[REDACTED_API_KEY]"

# US state bills — scan active legislation
python3 ~/bin/supadata.py scrape "https://leg.colorado.gov/bills/sb24-205"  # Colorado AI Act

# ISO 42001 — check for updates
python3 ~/bin/supadata.py scrape "https://www.iso.org/standard/81230.html"

# Map regulatory sites to find new pages/amendments
python3 ~/bin/supadata.py map "https://digital-strategy.ec.europa.eu/en/policies/european-approach-artificial-intelligence"
```

**When to use**: Before every compliance assessment. Regulations are updated quarterly. Stale regulation text = stale compliance advice.

### Analysis

1. Parse `$ARGUMENTS` for `--jurisdiction` (default: all) and `--focus` area.
2. For EU: map the AI system against EU AI Act risk tiers (unacceptable, high, limited, minimal), check transparency obligations, and conformity assessment requirements.
   **Source**: scrape `eur-lex.europa.eu` for the current consolidated text.
3. For US federal: review applicable executive orders (EO 14110 and successors), NIST AI RMF alignment, and sector-specific guidance (FDA for health AI, SEC for financial AI).
   **Source**: scrape `nist.gov`, `federalregister.gov`, `whitehouse.gov` for latest EOs.
4. For US state: scan active state AI bills (CO SB24-205, IL AI Video Interview Act, NYC Local Law 144, etc.) for applicability.
   **Source**: scrape state legislature sites for bill status and text.
5. For each applicable regulation, identify: obligations, deadlines, penalties, and current compliance status.
6. Map regulations to existing governance controls where available.

## Output Format
```
AI Regulation | all jurisdictions | governance focus

| Regulation | Jurisdiction | Status | Applicability | Deadline |
|-----------|-------------|--------|---------------|----------|
| EU AI Act | EU | In force | HIGH risk (Art. 6) | Aug 2026 |
| EO 14110 | US Federal | Active | Applies (dual-use) | Ongoing |
| CO SB24-205 | Colorado | Enacted | HIGH risk deployer | Feb 2026 |
| NYC LL 144 | New York City | Active | N/A (no hiring AI) | -- |

Obligations:
- [EU AI Act] Risk management system, data governance, transparency, human oversight
- [EO 14110] Safety testing, red-teaming results reporting for dual-use models
- [CO SB24-205] Impact assessment, consumer notification, opt-out mechanism

Gaps:
- [WARNING] No formal risk management system documented (EU AI Act Art. 9)
- [OK] NIST AI RMF mapping covers EO 14110 requirements

Next action: Document risk management system to satisfy EU AI Act Article 9.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Regulations mapped | `[nist-map]` for NIST AI RMF alignment detail |
| Inherits context from | `[daily-research]` for latest legislative developments |
| Deadlines identified | `[compliance-calendar]` to track regulatory deadlines |
