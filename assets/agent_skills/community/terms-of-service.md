---
name: terms-of-service
description: Draft Terms of Service (ToS) / Terms of Use for a SaaS product or website. Covers acceptable use, IP, disclaimers, liability limits, dispute resolution. Saves to _internal/legal/. Powered by legal-counsel agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"COMPANY\" \"PRODUCT\" [--type saas|website|marketplace] [--state GA]"
category: sales-marketing
status: tested
providers:
  required: [bash, python]
---
# Terms of Service

Generate complete Terms of Service for a SaaS product, website, or marketplace.

## When to Use

- Before launching a product publicly
- Before accepting payment from users
- When adding a user signup flow
- When a prospect's legal team asks for ToS before procurement

## Required Inputs

| Field | Example |
|-------|---------|
| Company name | HUMMBL, LLC |
| Product name | HUMMBL AI Governance Platform |
| Product type | SaaS (subscription) / Website / Marketplace |
| Core functionality | AI governance assessment, monitoring, and reporting |
| Governing state | Georgia |
| Contact email | legal@hummbl.io |

## Product Types

**SaaS:**
- Subscription license (not a sale)
- Uptime/availability disclaimers
- Data processing terms
- API usage limits

**Website (informational):**
- Lighter — no subscription terms
- User-submitted content section if applicable
- Cookie and analytics disclosure

**Marketplace:**
- Three-party relationships (platform + buyers + sellers)
- Transaction fees and disbursement terms
- Dispute resolution between parties

## Key Clauses

1. **Acceptance** — by using the service, user accepts terms
2. **License grant** — limited, non-exclusive, non-transferable license to use
3. **Restrictions** — no reverse engineering, scraping, competing products, resale
4. **User accounts** — registration, security responsibility, suspension rights
5. **Acceptable use** — prohibited conduct list
6. **Intellectual property** — company owns platform; user owns their data
7. **Fees and payment** — for paid products: billing, renewal, refund policy
8. **Disclaimer of warranties** — AS IS; no uptime guarantee unless SLA exists
9. **Limitation of liability** — capped at fees paid in prior 12 months
10. **Indemnification** — user indemnifies company for user-generated content/conduct
11. **Termination** — company can suspend/terminate for ToS violations
12. **Dispute resolution** — governing law, arbitration clause, class action waiver
13. **Changes to terms** — company can update with notice; continued use = acceptance

## Human Cost Equivalent

- Simple website ToS: $500-800 attorney time
- SaaS ToS: $800-1,500 attorney time
- Marketplace ToS: $1,500-3,000 attorney time

## Skill Chains

- ToS → `[privacy-policy]` (always needed alongside ToS)
- ToS + Privacy Policy → product is legally launchable (minimum viable legal)
- ToS → `[frontend]` (embed in product footer/signup flow)
- ToS → `[nda-draft]` (enterprise clients often want NDA on top of ToS)
