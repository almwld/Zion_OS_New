---
name: finance-legal-aggregator-research
description: >
  Domain research skill for Finance & Legal aggregator discovery. Catalogs canonical aggregators,
  registries, and metasearch protocols across Capital Markets, DeFi/Web3, FinTech/Open Banking,
  Real Estate/PropTech, and Legal & Regulatory domains. Produces structured 5-tuple classifications
  and feeds the Omni-Meta Aggregator Phase -1 catalog.
version: 0.1.0
execution-mode: advisory
tags:
  - research
  - finance
  - legal
  - aggregator
  - catalog
  - capital-markets
  - defi
  - fintech
  - real-estate
  - legal
category: hummbl-research
status: candidate
providers:
  required: [python]
---

# Finance & Legal Aggregator Research

Domain research skill for **Finance & Legal aggregator discovery** across 5 pillars.
Catalogs canonical aggregators, registries, and metasearch protocols, producing structured
5-tuple classifications for the Omni-Meta Aggregator Phase -1 catalog.

## When to Use

- Phase -1 Discovery for Omni-Meta Aggregator (Omni-Inform / Omni-Capital / Omni-Lex pillars)
- Building the Finance & Legal domain catalog for the 20-domain universal taxonomy
- Identifying canonical aggregators, registries, and metasearch protocols
- Producing 5-tuple classifications: ⟨Domain, Mechanism, TrustTier, LatencyClass, InterfaceMode⟩

## Domain Coverage (5 Pillars)

| Pillar | Sub-domains | Canonical Aggregators |
|--------|-------------|----------------------|
| **Capital Markets & Alternative Data** | Equities, fixed income, derivatives, alt data | Bloomberg, FactSet, S&P Capital IQ, Polygon, PitchBook, Refinitiv, Quandl |
| **Crypto, Web3 & DeFi Protocols** | DEX aggregators, yield optimizers, on-chain analytics | 1inch, CoW Swap, Jupiter, EigenLayer, DefiLlama, Dune, Nansen, Arkham |
| **FinTech, Open Banking & InsurTech** | Payment rails, lending marketplaces, insurance comparison | Plaid, Tink, Yodlee, LendingTree, The Zebra, Credible, NerdWallet |
| **Real Estate & PropTech** | Listings, valuations, rental analytics, REIT data | Zillow, Rightmove, CoStar, Regrid, AirDNA, ATTOM, RealtyMogul |
| **Legal & Regulatory** | Dockets, statutes, sanctions, corporate registries | CourtListener, GovInfo, Federal Register, OpenSanctions, OpenCorporates, UCF, LexisNexis, Westlaw |

## 5-Tuple Classification Schema

Every aggregator classified as:
```
⟨Domain, Mechanism, TrustTier, LatencyClass, InterfaceMode⟩
```

| Field | Values |
|-------|--------|
| **Domain** | Capital Markets / Crypto / FinTech / Real Estate / Legal |
| **Mechanism** | API / Web Scraping / Feed / Index / Registry / Metasearch / CLOB |
| **TrustTier** | Primary (official) / Secondary (reputable) / Tertiary (community) / Unverified |
| **LatencyClass** | Real-time (<1s) / Near-real-time (<1m) / Batch (hourly) / Daily / Static |
| **InterfaceMode** | REST API / GraphQL / WebSocket / FIX / CSV/JSON Feed / Web UI / MCP |

## Execution Procedure

1. **Enumerate sub-domains** for each of the 5 pillars
2. **Identify canonical aggregators** per sub-domain (official sources first)
3. **Classify each aggregator** using 5-tuple schema
4. **Assess trust tier** based on source authority (official > reputable > community)
5. **Determine latency class** from update frequency and delivery mechanism
6. **Map interface mode** from available access methods
7. **Cross-reference** with existing catalogs (DefiLlama, Dune, OpenAlex, etc.)
8. **Persist catalog** as structured JSON + human-readable Markdown

## Output Format

```json
{
  "pillar": "Capital Markets & Alternative Data",
  "sub_domain": "Equities",
  "aggregators": [
    {
      "name": "Bloomberg Terminal",
      "tuple": {
        "domain": "Capital Markets",
        "mechanism": "API",
        "trust_tier": "Primary",
        "latency_class": "Real-time",
        "interface_mode": "REST API|FIX|Web UI"
      },
      "canonical_sources": ["Bloomberg Professional Services"],
      "coverage": "Global equities, fixed income, derivatives, commodities",
      "access": "Subscription (institutional)"
    }
  ]
}
```

## Subagent Coordination

When dispatched as part of Omni-Meta Discovery:
- **Conversation ID**: `2f3fc24d-6ead-4eb1-91c1-8eaff65e6bc7`
- **Transcript**: `.gemini/antigravity-cli/brain/2f3fc24d-6ead-4eb1-91c1-8eaff65e6bc7/.system_generated/logs/transcript.jsonl`
- **Domains covered**: 5 (Capital Markets, Crypto, FinTech, Real Estate, Legal)

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

- `tech-cyber-aggregator-research` — parallel domain research
- `bio-energy-physical-aggregator-research` — parallel domain research
- `commerce-travel-culture-aggregator-research` — parallel domain research
- `omni-meta-aggregator-discovery` — consumes all 4 domain catalogs
- `free-apis` — executable tool for Federal Register regulatory document queries (`python ~/bin/free_apis.py fedreg "<query>"`)

## Evidence Sources

- Subagent transcript: `.gemini/antigravity-cli/brain/2f3fc24d-6ead-4eb1-91c1-8eaff65e6bc7/.system_generated/logs/transcript.jsonl`
- Phase -1 spec: `hummbl_governance/docs/research/2026-08-16_omni_meta_aggregator_huaomp_mtsmu_discovery.md` (Section 3.1, Pillars 1, 5)
- Coordination bus receipt: `033a94d968ed448089aa9a756b8e2ac7`