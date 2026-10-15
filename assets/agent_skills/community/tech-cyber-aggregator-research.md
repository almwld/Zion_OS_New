---
name: tech-cyber-aggregator-research
description: >
  Domain research skill for Tech & Cyber aggregator discovery. Catalogs canonical aggregators,
  registries, and metasearch protocols across AI/Foundation Models, Compute/Inference,
  Developer Tools, FinOps/Observability, and Cyber Threat Intelligence domains.
  Produces structured 5-tuple classifications for the Omni-Meta Aggregator Phase -1 catalog.
version: 0.1.0
execution-mode: advisory
tags:
  - research
  - tech
  - cyber
  - ai
  - compute
  - devtools
  - finops
  - observability
  - cybersecurity
category: hummbl-research
status: candidate
providers:
  required: [python]
---

# Tech & Cyber Aggregator Research

Domain research skill for **Tech & Cyber aggregator discovery** across 5 pillars.
Catalogs canonical aggregators, registries, and metasearch protocols, producing structured
5-tuple classifications for the Omni-Meta Aggregator Phase -1 catalog.

## When to Use

- Phase -1 Discovery for Omni-Meta Aggregator (Omni-Scientia / Omni-Inform / Omni-Capital pillars)
- Building the Tech & Cyber domain catalog for the 20-domain universal taxonomy
- Identifying canonical aggregators for AI models, compute, devtools, FinOps, and cyber intel

## Domain Coverage (5 Pillars)

| Pillar | Sub-domains | Canonical Aggregators |
|--------|-------------|----------------------|
| **AI, Foundation Models & Compute** | Model hubs, benchmarks, inference marketplaces | Hugging Face, LMSYS Chatbot Arena, OpenRouter, Vast.ai, io.net, Lambda Labs, RunPod, Together AI |
| **Software DevTools, Packages & Cloud** | Package registries, cost optimization, observability | PyPI, npm, crates.io, Kubecost, Vantage, Datadog, New Relic, Grafana Cloud, Honeycomb |
| **Cybersecurity & Threat Intel** | Threat feeds, vulnerability DBs, attack surface | MISP, Recorded Future, NVD/CVE, HIBP, Shodan, HackerOne, AlienVault OTX, URLhaus |
| **FinOps / Observability** | Cloud cost, infrastructure monitoring, log aggregation | CloudHealth, Cloudability, Datadog, New Relic, Splunk, Elastic, Grafana Loki, Coralogix |
| **Developer Tools & Platforms** | CI/CD, feature flags, secrets, API management | GitHub, GitLab, LaunchDarkly, HashiCorp Vault, Kong, Apigee, Postman |

## 5-Tuple Classification Schema

Every aggregator classified as:
```
⟨Domain, Mechanism, TrustTier, LatencyClass, InterfaceMode⟩
```

| Field | Values |
|-------|--------|
| **Domain** | AI/Compute / DevTools / Cyber / FinOps |
| **Mechanism** | API / Index / Registry / Feed / Metasearch / Marketplace / CLOB |
| **TrustTier** | Primary (official) / Secondary (reputable) / Tertiary (community) / Unverified |
| **LatencyClass** | Real-time (<1s) / Near-real-time (<1m) / Batch (hourly) / Daily / Static |
| **InterfaceMode** | REST API / GraphQL / WebSocket / gRPC / CLI / Web UI / MCP |

## Execution Procedure

1. **Enumerate sub-domains** for each of the 5 pillars
2. **Identify canonical aggregators** per sub-domain (official sources first)
3. **Classify each aggregator** using 5-tuple schema
4. **Assess trust tier** based on source authority (official > reputable > community)
5. **Determine latency class** from update frequency and delivery mechanism
6. **Map interface mode** from available access methods
7. **Cross-reference** with existing catalogs (Hugging Face, NVD, PyPI, etc.)
8. **Persist catalog** as structured JSON + human-readable Markdown

## Output Format

```json
{
  "pillar": "AI, Foundation Models & Compute",
  "sub_domain": "Model Hubs & Benchmarks",
  "aggregators": [
    {
      "name": "Hugging Face Hub",
      "tuple": {
        "domain": "AI/Compute",
        "mechanism": "Registry|API",
        "trust_tier": "Primary",
        "latency_class": "Real-time",
        "interface_mode": "REST API|Web UI|CLI|MCP"
      },
      "canonical_sources": ["Hugging Face"],
      "coverage": "500k+ models, datasets, spaces; community + official orgs",
      "access": "Free tier + Pro/Enterprise"
    }
  ]
}
```

## Subagent Coordination

When dispatched as part of Omni-Meta Discovery:
- **Conversation ID**: `3c99a3a8-55bb-4194-9fa8-4f048b6088fc`
- **Transcript**: `.gemini/antigravity-cli/brain/3c99a3a8-55bb-4194-9fa8-4f048b6088fc/.system_generated/logs/transcript.jsonl`
- **Domains covered**: 5 (AI/Models, Compute, DevTools, FinOps/Obs, Cyber Intel)

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
- `bio-energy-physical-aggregator-research` — parallel domain research
- `commerce-travel-culture-aggregator-research` — parallel domain research
- `omni-meta-aggregator-discovery` — consumes all 4 domain catalogs
- `free-apis` — executable tool for NVD vulnerability data queries (`python ~/bin/free_apis.py nvd "<cve-id>"` or `python ~/bin/free_apis.py osv "<package>"`)

## Evidence Sources

- Subagent transcript: `.gemini/antigravity-cli/brain/3c99a3a8-55bb-4194-9fa8-4f048b6088fc/.system_generated/logs/transcript.jsonl`
- Phase -1 spec: `hummbl_governance/docs/research/2026-08-16_omni_meta_aggregator_huaomp_mtsmu_discovery.md` (Section 3.1, Pillars 4, 6)
- Coordination bus receipt: `033a94d968ed448089aa9a756b8e2ac7`