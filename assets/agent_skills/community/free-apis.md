---
name: free-apis
description: Free API wrappers for OpenAlex, NVD, OSV, PubMed, and other no-cost data sources. Use when you need citation metadata, CVE/vulnerability data, or biomedical literature lookups without paid API keys.
version: 0.1.0
execution-mode: advisory
argument-hint: "[openalex|nvd|osv|pubmed] <query>"
category: bio-science
status: candidate
---

# Free APIs

Wrapper script for free, no-auth-required public APIs. Provides a unified
interface for citation metadata, vulnerability data, and biomedical literature.

## When to Use

- OpenAlex queries (publication metadata, citation counts, author data)
- NVD/OSV vulnerability lookups (CVE details, package vulnerabilities)
- PubMed literature searches (biomedical abstracts, MeSH terms)
- Any task requiring free, no-cost API access to public data sources

## Usage

```bash
# OpenAlex — publication metadata, citation graphs
python ~/bin/free_apis.py openalex "<query>"
python ~/bin/free_apis.py openalex lookup --doi <doi>

# NVD — CVE vulnerability details
python ~/bin/free_apis.py nvd "<cve-id>"

# OSV — package vulnerability data
python ~/bin/free_apis.py osv "<package>"

# PubMed — biomedical literature
python ~/bin/free_apis.py pubmed "<query>"
```

## Data Sources

| Source | API | Auth | Rate Limit | Use For |
|--------|-----|------|------------|---------|
| OpenAlex | REST | None (polite pool with email) | 100K/day | Publications, citations, authors, venues |
| NVD | REST | None (API key recommended) | 50 req/30s without key | CVE details, CVSS scores, references |
| OSV | REST | None | Generous | Package vulnerabilities, ecosystem coverage |
| PubMed (E-utilities) | REST | None (API key recommended) | 3 req/s without key | Biomedical abstracts, MeSH terms |

## Prerequisites

The wrapper script `~/bin/free_apis.py` must exist. If missing, call the APIs
directly with `curl` per the patterns below.

## Notes

- All sources are free with no API key required (keys improve rate limits)
- OpenAlex polite pool: add `mailto=you@example.com` parameter
- NVD API key: request at https://nvd.nist.gov/developers/request-an-api-key
- PubMed API key: request at https://www.ncbi.nlm.nih.gov/account/settings/

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| `[bibliometric]` | Bibliometric analysis using OpenAlex data |
| `[citation-network]` | Build citation graphs from OpenAlex results |
| `[evidence-grade]` | Grade evidence quality from retrieved publications |
| `[container-scan]` | Enrich container scan with NVD/OSV data |
