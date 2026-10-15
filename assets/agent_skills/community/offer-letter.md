---
name: offer-letter
description: Draft an employment offer letter. Covers title, comp, equity, start date, benefits, at-will status. FLSA-aware with equity plain-English explanation. Saves to _internal/hr/. Powered by hr-specialist agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"CANDIDATE_NAME\" \"TITLE\" \"COMP\" [--equity \"X options\"] [--start \"DATE\"] [--state GA]"
category: sales-marketing
status: candidate
---
# Offer Letter

Generate a complete employment offer letter for a new hire.

## When to Use

- Making any job offer (full-time, part-time, exempt, non-exempt)
- Formalizing a verbal offer in writing
- Equity-bearing offers (early-stage hires, key hires)
- Before the candidate's first day — offer letter is the legal record of agreed terms

## Required Inputs

| Field | Example |
|-------|---------|
| Company name | HUMMBL, LLC |
| Candidate name | Jane Smith |
| Title | Senior AI Engineer |
| Employment type | Full-time, exempt |
| Base salary | $140,000/year |
| Start date | May 1, 2026 |
| Reports to | Reuben Bowlby, CEO |
| Equity (if any) | 50,000 ISOs, 4-year / 1-year cliff |
| Benefits | Standard package or list specific benefits |
| Governing state | Georgia |

## Offer Letter Structure

1. **Opening** — warm, specific to the candidate's contributions
2. **Position details** — title, status (exempt/non-exempt), manager, start date
3. **Compensation** — base salary, pay frequency, overtime policy if non-exempt
4. **Equity** — plain-English explanation of grant (ISO/NSO, count, vesting, exercise price pending 409A valuation, cliff, window)
5. **Benefits** — health, 401k, PTO, any perks
6. **At-will statement** — clearly stated for all US jurisdictions
7. **Conditions** — background check, I-9 authorization, NDAs/IP agreements to sign Day 1
8. **Expiration** — offer expires in 5 business days (default)
9. **Signature block** — founder signature + candidate acceptance line

## Equity Section (Plain English)

For any equity-bearing offer, the agent includes:

> "You will receive a stock option grant of [X] shares at an exercise price to be set by our board following a 409A valuation. Options vest over 4 years with a 1-year cliff: 25% vests after your first anniversary and the remaining 75% vests monthly over the following 36 months. Options are subject to the terms of our Stock Option Plan and your option agreement, which you will receive separately."

## Human Cost Equivalent

- Simple offer letter: $100-200 attorney or HR consultant time
- Equity-bearing offer letter: $200-400

## Skill Chains

- Offer accepted → `[contractor-agreement]` (if reclassifying as contractor instead)
- Offer accepted → send via `[send-email]`
- Day 1 → `[onboard-human]` (onboarding workflow)
- Equity offer → flag: need 409A valuation before options can be priced
