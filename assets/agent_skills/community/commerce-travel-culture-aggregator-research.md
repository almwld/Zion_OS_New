---
name: commerce-travel-culture-aggregator-research
description: >
  Domain research skill for Commerce, Travel & Culture aggregator discovery. Catalogs canonical aggregators,
  registries, and metasearch protocols across E-Commerce, Travel/Mobility, Jobs/Talent,
  Entertainment/Gaming, Reviews/Critics, News/Fact-Check, and Prediction Markets domains.
  Produces structured 5-tuple classifications for the Omni-Meta Aggregator Phase -1 catalog.
version: 0.1.0
execution-mode: advisory
tags:
  - research
  - commerce
  - travel
  - culture
  - ecommerce
  - jobs
  - entertainment
  - reviews
  - prediction-markets
category: hummbl-research
status: candidate
providers:
  required: [python]
---

# Commerce, Travel & Culture Aggregator Research

Domain research skill for **Commerce, Travel & Culture aggregator discovery** across 7 pillars.
Catalogs canonical aggregators, registries, and metasearch protocols, producing structured
5-tuple classifications for the Omni-Meta Aggregator Phase -1 catalog.

## When to Use

- Phase -1 Discovery for Omni-Meta Aggregator (Omni-Inform, Omni-Capital, Omni-Vox pillars)
- Building the Commerce/Travel/Culture domain catalog for the 20-domain universal taxonomy

## Domain Coverage (7 Pillars)

| Pillar | Sub-domains | Canonical Aggregators |
|--------|-------------|----------------------|
| **E-Commerce & Brand Rollups** | Shopping comparison, coupon/discount, brand aggregators | Google Shopping, Idealo, Keepa, Rakuten, Thrasio, ChannelEngine, PriceGrabber, Shopzilla |
| **Travel & Mobility Metasearch** | Flights, hotels, trains, multi-modal | Skyscanner, Google Flights, Trivago, Trainline, Citymapper, Rome2rio, Kayak, Hopper |
| **Jobs, Talent & Compensation** | Job boards, salary data, freelance marketplaces | Indeed, Wellfound, Levels.fyi, Upwork, GLG, Toptal, Hired, Glassdoor, LinkedIn Jobs |
| **Entertainment, Gaming & Odds** | Streaming search, game prices, mods, sports odds | JustWatch, IsThereAnyDeal, Nexus Mods, Podcast Index, Flashscore, OddsPortal, Betfair |
| **Reviews, Critics & Sentiment** | Review aggregators, critic scores, sentiment analysis | Rotten Tomatoes, Goodreads, Yelp, G2, Trustpilot, Brandwatch, Metacritic, OpenCritic |
| **Global News & Fact-Checkers** | News aggregation, bias analysis, fact-checking | Ground News, AllSides, Euro\|Topics, PolitiFact, Reuters, AP, NewsGuard, Media Bias/Fact Check |
| **Prediction Markets & Open Data** | Forecasting, event contracts, open datasets | Polymarket, Kalshi, Metaculus, Data.gov, Wikidata, PredictIt, Good Judgment, Manifold |

## 5-Tuple Classification Schema

Every aggregator classified as:
```
⟨Domain, Mechanism, TrustTier, LatencyClass, InterfaceMode⟩
```

| Field | Values |
|-------|--------|
| **Domain** | E-Commerce / Travel / Jobs / Entertainment / Reviews / News / Prediction |
| **Mechanism** | API / Metasearch / Feed / Index / Registry / CLOB / Marketplace / Crowdsource |
| **TrustTier** | Primary (official) / Secondary (reputable) / Tertiary (community) / Unverified |
| **LatencyClass** | Real-time (<1s) / Near-real-time (<1m) / Batch (hourly) / Daily / Static |
| **InterfaceMode** | REST API / GraphQL / WebSocket / Web UI / CLI / MCP / CSV/JSON Feed |

## Execution Procedure

1. **Enumerate sub-domains** for each of the 7 pillars
2. **Identify canonical aggregators** per sub-domain (official sources first)
3. **Classify each aggregator** using 5-tuple schema
4. **Assess trust tier** based on source authority (official > reputable > community)
5. **Determine latency class** from update frequency and delivery mechanism
6. **Map interface mode** from available access methods
7. **Cross-reference** with existing catalogs (Polymarket, Data.gov, Indeed, etc.)
8. **Persist catalog** as structured JSON + human-readable Markdown

## Output Format

```json
{
  "pillar": "Prediction Markets & Open Data",
  "sub_domain": "Event Contracts & Forecasting",
  "aggregators": [
    {
      "name": "Polymarket",
      "tuple": {
        "domain": "Prediction",
        "mechanism": "CLOB",
        "trust_tier": "Secondary",
        "latency_class": "Real-time",
        "interface_mode": "REST API|Web UI|WebSocket"
      },
      "canonical_sources": ["Polymarket"],
      "coverage": "Crypto-native prediction markets; sports, politics, crypto, culture",
      "access": "Free (US restricted); API via Polygon"
    }
  ]
}
```

## Subagent Coordination

When dispatched as part of Omni-Meta Discovery:
- **Conversation ID**: `dd2364d1-345b-4102-ab36-95dd7dd188e4`
- **Transcript**: `.gemini/antigravity-cli/brain/dd2364d1-345b-4102-ab36-95dd7dd188e4/.system_generated/logs/transcript.jsonl`
- **Domains covered**: 7 (E-Commerce, Travel, Jobs, Entertainment, Reviews, News, Prediction Markets)

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
- `bio-energy-physical-aggregator-research` — parallel domain research
- `omni-meta-aggregator-discovery` — consumes all 4 domain catalogs
- `free-apis` — executable tool for Wikidata entity queries (`python ~/bin/free_apis.py wikidata "<query>"`)

## Evidence Sources

- Subagent transcript: `.gemini/antigravity-cli/brain/dd2364d1-345b-4102-ab36-95dd7dd188e4/.system_generated/logs/transcript.jsonl`
- Phase -1 spec: `hummbl_governance/docs/research/2026-08-16_omni_meta_aggregator_huaomp_mtsmu_discovery.md` (Section 3.1, Pillars 13, 14, 15, 16, 17, 18, 19)
- Coordination bus receipt: `033a94d968ed448089aa9a756b8e2ac7`