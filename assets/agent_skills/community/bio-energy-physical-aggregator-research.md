---
name: bio-energy-physical-aggregator-research
description: >
  Domain research skill for Bio, Energy & Physical aggregator discovery. Catalogs canonical aggregators,
  registries, and metasearch protocols across Global News/Fact-Checking, Open Science/Preprints,
  Healthcare/Genomics, Energy/Grids, Geospatial/IoT, and Freight/Logistics domains.
  Produces structured 5-tuple classifications for the Omni-Meta Aggregator Phase -1 catalog.
version: 0.1.0
execution-mode: advisory
tags:
  - research
  - bio
  - energy
  - physical
  - healthcare
  - genomics
  - geospatial
  - logistics
  - news
category: hummbl-research
status: candidate
providers:
  required: [python]
---

# Bio, Energy & Physical Aggregator Research

Domain research skill for **Bio, Energy & Physical aggregator discovery** across 6 pillars.
Catalogs canonical aggregators, registries, and metasearch protocols, producing structured
5-tuple classifications for the Omni-Meta Aggregator Phase -1 catalog.

## When to Use

- Phase -1 Discovery for Omni-Meta Aggregator (Omni-Inform, Omni-Scientia, Omni-Capital pillars)
- Building the Bio/Energy/Physical domain catalog for the 20-domain universal taxonomy

## Domain Coverage (6 Pillars)

| Pillar | Sub-domains | Canonical Aggregators |
|--------|-------------|----------------------|
| **Global News & Fact Checkers** | News aggregators, bias analysis, fact-checking | Ground News, AllSides, Euro\|Topics, PolitiFact, Reuters, AP, Snopes, FactCheck.org, NewsGuard |
| **Open Science / Preprints** | Preprint servers, scholarly graphs, citation analysis | arXiv, bioRxiv, medRxiv, OpenAlex, Semantic Scholar, Dimensions, Crossref, DOI.org |
| **Healthcare & Genomics** | Clinical trials, genomic data, drug pricing, interoperability | ClinicalTrials.gov, GenBank, UniProt, TEFCA, Epic Cosmos, GoodRx, RxNav, PharmGKB, ClinVar |
| **Energy & Grids** | Wholesale markets, VPPs, renewables, carbon registries | PJM, CAISO, ENTSO-E, Tesla VPP, Voltus, Verra, Hubject, EPEX SPOT, GME |
| **Geospatial & IoT** | Satellite imagery, weather, maritime, aviation | ECMWF, NOAA, Copernicus, Planet Labs, MarineTraffic, Flightradar24, Spire, Windy |
| **Freight & Logistics** | Spot rates, container tracking, supply chain visibility | Freightos, Flexport, Project44, DAT One, ImportYeti, FourKites, Ocean Insights |

## 5-Tuple Classification Schema

Every aggregator classified as:
```
⟨Domain, Mechanism, TrustTier, LatencyClass, InterfaceMode⟩
```

| Field | Values |
|-------|--------|
| **Domain** | News / Science / Healthcare / Energy / Geospatial / Logistics |
| **Mechanism** | API / Feed / Index / Registry / Metasearch / Satellite / Sensor Network |
| **TrustTier** | Primary (official) / Secondary (reputable) / Tertiary (community) / Unverified |
| **LatencyClass** | Real-time (<1s) / Near-real-time (<1m) / Batch (hourly) / Daily / Static |
| **InterfaceMode** | REST API / GraphQL / WebSocket / FIX / CSV/JSON Feed / Web UI / MCP / Satellite Downlink |

## Execution Procedure

1. **Enumerate sub-domains** for each of the 6 pillars
2. **Identify canonical aggregators** per sub-domain (official sources first)
3. **Classify each aggregator** using 5-tuple schema
4. **Assess trust tier** based on source authority (official > reputable > community)
5. **Determine latency class** from update frequency and delivery mechanism
6. **Map interface mode** from available access methods
7. **Cross-reference** with existing catalogs (OpenAlex, ClinicalTrials.gov, PJM, etc.)
8. **Persist catalog** as structured JSON + human-readable Markdown

## Output Format

```json
{
  "pillar": "Healthcare & Genomics",
  "sub_domain": "Clinical Trials & Drug Data",
  "aggregators": [
    {
      "name": "ClinicalTrials.gov",
      "tuple": {
        "domain": "Healthcare",
        "mechanism": "Registry|API",
        "trust_tier": "Primary",
        "latency_class": "Near-real-time",
        "interface_mode": "REST API|Web UI|RSS Feed"
      },
      "canonical_sources": ["NIH/NLM"],
      "coverage": "400k+ studies across 220 countries",
      "access": "Free public access"
    }
  ]
}
```

## Subagent Coordination

When dispatched as part of Omni-Meta Discovery:
- **Conversation ID**: `78a14e4f-70af-49e9-b121-a2ecbc7f72c2`
- **Transcript**: `.gemini/antigravity-cli/brain/78a14e4f-70af-49e9-b121-a2ecbc7f72c2/.system_generated/logs/transcript.jsonl`
- **Domains covered**: 6 (News/Fact-Check, Open Science, Healthcare/Genomics, Energy/Grids, Geospatial/IoT, Freight/Logistics)

## Deliverables

- Structured catalog (JSON) with 5-tuple classifications for all identified aggregators
- Human-readable Markdown summary with pillar/sub-domain organization
- Gap analysis: domains with insufficient aggregator coverage
- Trust tier distribution statistics
- Latency class distribution statistics

## AIP Scope Compliance

- Outputs confined to `hummbl_governance/docs/research/` or agent brain directory
- Zero unauthorized mutations
- Read-only research operations

## Related Skills

- `finance-legal-aggregator-research` — parallel domain research
- `tech-cyber-aggregator-research` — parallel domain research
- `commerce-travel-culture-aggregator-research` — parallel domain research
- `omni-meta-aggregator-discovery` — consumes all 4 domain catalogs
- `free-apis` — executable tool for OpenAlex scholarly graph queries (`python ~/bin/free_apis.py openalex "<query>"`)

## Evidence Sources

- Subagent transcript: `.gemini/antigravity-cli/brain/78a14e4f-70af-49e9-b121-a2ecbc7f72c2/.system_generated/logs/transcript.jsonl`
- Phase -1 spec: `hummbl_governance/docs/research/2026-08-16_omni_meta_aggregator_huaomp_mtsmu_discovery.md` (Section 3.1, Pillars 7, 9, 10, 11)
- Coordination bus receipt: `033a94d968ed448089aa9a756b8e2ac7`