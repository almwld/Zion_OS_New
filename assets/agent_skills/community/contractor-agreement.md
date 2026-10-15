---
name: contractor-agreement
description: Draft an Independent Contractor Agreement (ICA). Covers scope, rate, IP assignment, confidentiality, termination. Saves to _internal/legal/. Powered by legal-counsel agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"CONTRACTOR_NAME\" \"COMPANY\" \"SCOPE\" [--rate \"$X/hr\"] [--state GA]"
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---
# Contractor Agreement

Generate an Independent Contractor Agreement (ICA) for hiring a freelancer or consultant.

## When to Use
- Hiring a contractor, freelancer, or consultant
- Engaging a developer, designer, writer, or advisor
- Before any paid work begins with a non-employee

## Required Inputs

| Field | Example |
|-------|---------|
| Company name | HUMMBL, LLC |
| Company address | 526 Briarhill Ln NE, Atlanta GA 30324 |
| Contractor name | Jane Smith |
| Contractor address | [address] |
| Services / scope | Frontend development for hummbl.io dashboard |
| Rate and structure | $100/hr, invoiced monthly |
| Start date | [date] |
| Term / end date | 3 months or until project complete |
| Governing state | Georgia |

## Key Clauses

1. **Independent contractor status** — not an employee; no benefits, no withholding
2. **Scope of services** — specific deliverables or ongoing role
3. **Compensation** — rate, invoicing schedule, payment terms (NET 15 default)
4. **IP assignment** — all work product belongs to company
5. **Confidentiality** — embedded NDA; company information stays confidential
6. **Non-solicitation** — no poaching clients or employees (12 months default)
7. **Termination** — either party with 14 days notice; for-cause immediate
8. **Governing law** — company's home state default

## IRS Contractor vs Employee Note

The agreement alone doesn't determine classification. Flag if the engagement:
- Requires set hours / schedule → employee risk
- Provides equipment / office space → employee risk
- Exclusive relationship > 1 year → employee risk

If any flags triggered, note in governance receipt.

## Human Cost Equivalent

- Attorney drafting: 1-3 hours → $300-1,500
- Template + attorney review: $150-500

## Skill Chains
- Before ICA → `[nda-draft]` if standalone confidentiality needed first
- After ICA signed → `[time-track]` (start tracking their hours), `[invoice-generate]` (when billing)
- If relationship deepens → `[operating-agreement]` amendment (adding member)
