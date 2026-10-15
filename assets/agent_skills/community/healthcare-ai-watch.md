---
name: healthcare-ai-watch
description: Track Healthcare AI regulation — ONC HTI-1, FDA PCCP, HIPAA, EU AI Act medical-device clauses. Surfaces deltas to inform HUMMBL coverage matrix updates.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--depth quick|full] [--focus onc|fda|hipaa|eu|all]"
category: governance-compliance
status: candidate
---
# Healthcare AI Watch

Track the four regulatory surfaces governing AI in US/EU healthcare. Each is on a different update cadence; missing a delta affects HUMMBL governance positioning for medical / pharma / device clients. Feeds 3 of 5 coverage-matrix gaps (ONC HTI-1, FDA PCCP, HIPAA).

## When to Use

- Monthly cadence during any active healthcare-AI engagement
- Before HUMMBL coverage matrix update cycles
- Before any healthcare-vertical proposal, SOW, or assessment report
- On-trigger: FDA guidance publication, ONC final rule, HHS HIPAA NPRM, EU AI Act medical-device delegated act

## Sources (ranked by authority)

| Priority | Source | What to Look For |
|----------|--------|-----------------|
| P1 | `healthit.gov/topic/laws-regulation-and-policy/health-data-technology-and-interoperability-certification-program-htis` | ONC HTI-1 + HTI-2 rule text + amendments |
| P1 | `fda.gov/medical-devices/software-medical-device-samd/artificial-intelligence-and-machine-learning-software-medical-device` | FDA AI/ML SaMD + PCCP guidance |
| P1 | `fda.gov/news-events/press-announcements` (filter AI/SaMD) | FDA press on AI device clearances + recalls |
| P1 | `hhs.gov/hipaa/for-professionals/special-topics/index.html` | HIPAA AI-relevant special topics + NPRMs |
| P1 | `digital-strategy.ec.europa.eu/en/policies/ai-act-implementation` | EU AI Act implementation — medical-device delegated acts (Annex III) |
| P2 | `federalregister.gov` (filter "artificial intelligence" + healthcare agencies) | Federal Register notices, comment periods |
| P2 | `medtechdive.com` + `regulatoryfocus.org` | Industry trade press on regulatory shifts |
| P2 | `himss.org/resources` | Industry-association guidance |
| P3 | `fda.gov/about-fda/oncology-center-excellence` | OCE AI updates (oncology is FDA's most active AI surface) |
| P3 | Hacker News `site:news.ycombinator.com FDA AI` | Community reaction on enforcement actions |

## Focus Areas

| Focus | Covers | Why It Matters |
|---|---|---|
| `onc` | ONC HTI-1 (Decision Support Interventions / Predictive DSI transparency) + HTI-2 (forthcoming) | Most stringent US healthcare-AI transparency rule; in force; binding on certified EHRs |
| `fda` | FDA PCCP (Predetermined Change Control Plan) for SaMD/AI; AI/ML SaMD Action Plan | Governs continuous-learning AI in medical devices; FDA has cleared >900 AI devices as of 2025 |
| `hipaa` | HHS HIPAA modernization NPRMs, AI-specific guidance on PHI in training data | Affects HUMMBL data-handling posture for any client with PHI in scope |
| `eu` | EU AI Act medical-device classification (Annex III + MDR/IVDR intersection) | High-risk class for medical AI; conformity-assessment requirements differ from MDR alone |

## Output Format

```
## HEALTHCARE-AI-WATCH <YYYY-MM-DD>

### ONC HTI-1 / HTI-2
- Current rule state: <enforced | NPRM | proposed>
- Changes since last watch: <list>
- Coverage matrix impact: <row IDs in docs/coverage/onc-hti1.md>

### FDA PCCP
- Most recent guidance: <doc name + date>
- AI/ML SaMD clearances trend: <count + notable approvals>
- Changes since last watch: <list>
- Coverage matrix impact: <row IDs in docs/coverage/fda-pccp.md>

### HIPAA
- Active NPRMs affecting AI: <list>
- HHS guidance updates: <list>
- Coverage matrix impact: <row IDs in docs/coverage/hipaa.md>

### EU AI Act (medical)
- Implementation acts on medical devices: <state>
- MDR/IVDR intersection notes: <bullets>
- Conformity-assessment changes: <list>

### Cross-cutting observations
- <Patterns spanning multiple surfaces>

### Recommended actions
- <list, by priority>
```

## Coverage Matrix Gap Closure

Maps to coverage gaps at `PROJECTS/.agents/docs/coverage/`:
- **ONC HTI-1** — `docs/coverage/onc-hti1.md` (NEW; this skill is the upstream source)
- **FDA PCCP** — `docs/coverage/fda-pccp.md` (NEW)
- **HIPAA AI** — `docs/coverage/hipaa-ai.md` (NEW; carved out of generic HIPAA)

When a delta lands, file an issue against `hummbl-io/agents` titled `coverage: healthcare-ai <surface> delta YYYY-MM-DD`.

## Live Data Fetch

Before manual source scanning, pull live data from free APIs to surface recent publications and regulatory actions:

```bash
# PubMed — recent AI healthcare regulation literature
python ~/bin/free_apis.py pubmed search "AI healthcare regulation OR AI medical device OR AI clinical decision support" --limit 25

# PubMed — fetch full abstract for a specific PMID
python ~/bin/free_apis.py pubmed fetch --pmid <PMID>

# Federal Register — recent AI-related healthcare agency notices
python ~/bin/free_apis.py fedreg search "artificial intelligence" --agencies "food-and-drug-administration" "health-and-human-services-department" --limit 25 --since 2026-01-01

# OpenAlex — scholarly literature on AI governance in healthcare
python ~/bin/free_apis.py openalex search "AI governance healthcare medical device" --limit 25
```

These calls are keyless (no API key required) and return structured data. Use the results to identify deltas since the last watch cycle before manually scraping P1 source pages.

- Monthly: P1 sources scan (full depth, ~20 min — healthcare regs change slowly but breaking)
- Quarterly: P2/P3 sources sweep (~30 min)
- On-trigger: FDA press release on AI clearance / enforcement; ONC final-rule publication; HHS HIPAA NPRM open; EU AI Act Annex III delegated act published

## Cross-references

- `~/.agents/skills/ai-regulation/SKILL.md` — broader AI-regulation watch (this skill is the healthcare-specific specialization)
- `~/.agents/skills/c2pa-watch/SKILL.md` — sibling vertical (content authenticity; intersects with FDA on medical-imaging provenance)
- `PROJECTS/.agents/docs/coverage/README.md` — coverage-matrix governance per ADR-001-coverage-matrix-not-self-grade

## Origin

Built 2026-05-14 to substitute for opencode's phantom-deliverable SPOTREP at 15:11:53Z (opencode runtime exhausted mid-job; per audit § ERRATA in `_internal/reviews/opencode-peer-audit-2026-05-14.md`).
