---
name: service-agreement
description: Draft a Master Service Agreement (MSA) or standalone Service Agreement. Covers scope, payment, IP, confidentiality, liability, termination. Saves to _internal/legal/. Powered by legal-counsel agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"PROVIDER\" \"CLIENT\" \"SERVICES\" [--rate \"$X/hr or $X flat\"] [--state GA]"
category: sales-marketing
status: tested
providers:
  required: [bash, python]
---
# Service Agreement

Generate a complete Service Agreement (MSA or standalone) for client engagements.

## When to Use

- Before starting paid work with any client
- When a client sends their own MSA (use as basis for comparison or redline)
- When SOW references an existing MSA that doesn't exist yet
- For recurring engagements where a framework agreement is preferable to per-project contracts

## Required Inputs

| Field | Example |
|-------|---------|
| Provider (your company) | HUMMBL, LLC |
| Client name | Acme Corp |
| Services description | AI governance consulting and assessment services |
| Fee structure | $3,500/month retainer or $7,500 project flat fee |
| Payment terms | NET 15 (default) |
| Term | 3 months, auto-renewing |
| Governing state | Georgia |

## Key Clauses

1. **Services** — defined scope; out-of-scope work triggers a change order
2. **Compensation** — rate, invoicing schedule, late payment (1.5%/month default)
3. **Ownership of work product** — client owns deliverables upon full payment; provider retains tools/frameworks
4. **Confidentiality** — embedded NDA; mutual protection
5. **Warranties** — provider warrants professional skill; no fitness-for-particular-purpose warranty
6. **Limitation of liability** — capped at fees paid in prior 3 months (standard for services)
7. **Indemnification** — each party indemnifies for their own IP infringement
8. **Termination** — 30-day notice (default); for-cause immediate
9. **Governing law** — provider's home state default
10. **Dispute resolution** — negotiation → mediation → arbitration (litigation as last resort)

## MSA vs Standalone

**MSA (Master Service Agreement):**
- Use when multiple projects or SOWs are anticipated
- Sets the legal framework; each SOW just adds scope + price
- Best for recurring client relationships

**Standalone Service Agreement:**
- Use for one-off projects
- Self-contained; no need for separate SOW
- Faster to execute with new clients

## Human Cost Equivalent

- Simple standalone SA: $200-400 attorney time
- Full MSA: $500-1,200 attorney time

## Skill Chains

- Before SA → `[nda-draft]` (if confidentiality needed before MSA is signed)
- SA signed → `[sow-generate]` (define first project scope)
- SA signed → `[time-track]` (start billing), `[invoice-generate]` (at milestones)
- SA + SOW = client ready to engage
