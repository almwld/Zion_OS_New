---
name: nda-draft
description: Draft a Non-Disclosure Agreement (NDA). Mutual or one-way. Covers confidentiality, term, governing law, remedies. Saves to _internal/legal/. Powered by legal-counsel agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"PARTY_A\" \"PARTY_B\" [--type mutual|one-way] [--purpose \"PURPOSE\"] [--state GA]"
category: fleet-ops
status: candidate
---
# NDA Draft

Generate a complete Non-Disclosure Agreement.

## When to Use
- Before sharing business plans, financials, or IP with a prospect or partner
- Before a discovery call where sensitive product details will be discussed
- Before hiring a contractor (embed in contractor agreement or use standalone)
- Before any investor conversation (though VCs rarely sign them)

## Required Inputs

| Field | Example |
|-------|---------|
| Disclosing party | HUMMBL, LLC |
| Receiving party | Acme Corp / Jane Smith |
| Purpose | Evaluation of potential consulting engagement |
| Type | Mutual (both share) or One-Way (one discloses) |
| Term | 2 years (default) |
| Governing state | Georgia |

## NDA Types

**Mutual NDA** — both parties may share confidential information. Use for:
- Partnership discussions
- Joint ventures
- M&A exploration

**One-Way NDA** — only one party discloses. Use for:
- Client engagements where you share your methodology
- Vendor relationships where vendor accesses your data
- Job candidate interviews

## Key Clauses

1. Definition of Confidential Information (broad; carve-outs for public domain, prior knowledge, required disclosure)
2. Obligations of receiving party (protect with reasonable care; no disclosure; limited use)
3. Term (2 years default for information; IP obligations survive)
4. Return or destruction of materials
5. No license granted
6. Remedies (injunctive relief without bond)
7. Governing law and dispute resolution

## Human Cost Equivalent

- Mutual NDA: $200-500 attorney time
- One-Way NDA: $150-300 attorney time

## Skill Chains
- Before NDA → `[discovery-call]` (prep for the conversation the NDA enables)
- After NDA signed → `[contractor-agreement]` or `[proposal-write]`
- NDA + proposal accepted → `[sow-generate]`
