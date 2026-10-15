---
name: privacy-policy
description: Draft a Privacy Policy compliant with CCPA, GDPR (basic), and state privacy laws. Covers data collection, use, sharing, retention, user rights, and contact. Saves to _internal/legal/. Powered by legal-counsel agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"COMPANY\" \"PRODUCT\" [--data-types \"email,usage,payments\"] [--state GA]"
category: governance-compliance
status: tested
providers:
  required: [bash, python]
---
# Privacy Policy

Generate a Privacy Policy for a SaaS product, website, or mobile app.

## When to Use

- Before launching any product that collects user data (including just email)
- When adding a user signup or contact form
- When processing payments (PCI + privacy overlap)
- Required by Google/Apple app stores
- Required by enterprise procurement (CCPA, GDPR representations)

## Required Inputs

| Field | Example |
|-------|---------|
| Company name | HUMMBL, LLC |
| Product/website | hummbl.io — AI governance platform |
| Data collected | Email, company name, usage data, payment info |
| Third-party services | Stripe (payments), Google Analytics, Cloudflare |
| User rights supported | Access, deletion, opt-out |
| Contact email | privacy@hummbl.io |
| Governing state | Georgia |

## Data Types Covered

**Identity data**: name, email, company, job title
**Account data**: login credentials, preferences, settings
**Usage data**: pages visited, features used, session duration (often via analytics)
**Payment data**: billing address, last 4 digits (full card data goes to processor, not you)
**Communications**: support tickets, emails, chat transcripts
**Device/technical**: IP address, browser type, cookies

## Key Sections

1. **Information we collect** — explicit list of data types and how collected
2. **How we use it** — service delivery, billing, communications, analytics, legal compliance
3. **Sharing** — processors (Stripe, AWS, etc.), legal requirements, business transfers
4. **Retention** — how long data is kept; deletion triggers
5. **Your rights** — access, correction, deletion, portability, opt-out
6. **California rights (CCPA)** — right to know, delete, opt-out of sale
7. **Security** — reasonable measures; no guarantee
8. **Children (COPPA)** — under 13 not permitted
9. **Changes** — how users will be notified
10. **Contact** — privacy officer email and mailing address

## Compliance Flags

The agent will flag:
- **GDPR**: if users could be in EU, additional lawful basis and DPA requirements apply
- **CCPA**: if annual revenue >$25M or >100K California users, formal compliance program needed
- **HIPAA**: if any health data is collected — triggers major additional requirements
- **COPPA**: if any possibility of users under 13

## Human Cost Equivalent

- Basic privacy policy: $500-800 attorney time
- CCPA-compliant policy: $800-1,500
- GDPR-ready policy: $1,500-3,000

## Skill Chains

- Privacy Policy → `[terms-of-service]` (always needed together)
- Privacy Policy → `[gdpr-check]` (if EU users expected)
- Privacy Policy → `[privacy-audit]` (ongoing compliance check)
- ToS + Privacy Policy = minimum viable legal for product launch
