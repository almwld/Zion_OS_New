---
name: partnership-brief
description: Build a one-pager partnership brief for a channel, integration, or co-sell conversation. Covers mutual value, use case fit, ask, and follow-up. Saves to _internal/biz-dev/. Powered by biz-dev agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"PARTNER\" \"PARTNERSHIP_TYPE\" [--format one-pager|detailed|email]"
category: dev-tools
status: tested
providers:
  required: [bash, python]
---
# Partnership Brief

Build a concise partnership brief — mutual value map, use case fit, commercial structure options, and specific ask — for a channel, integration, or co-sell conversation.

## When to Use

- Before a meeting with a potential reseller, channel partner, or tech integration partner
- When a warm intro to a partner is inbound and you need to prep
- After a first partnership conversation to capture alignment and next steps
- Building a leave-behind after a conference intro

## Required Inputs

| Field | Example |
|-------|---------|
| Partner name | Deloitte / Microsoft / Equifax / Workiva |
| Partnership type | Referral / Reseller / Tech integration / Co-sell / OEM |
| Partner's business | AI consulting practice at Big 4 / FS compliance platform |
| Known overlap | Both serve enterprise regulated AI governance buyers |
| What we bring | Governed AI layer, compliance receipts, NIST/ISO/EU AI Act coverage |
| What we need | Access to their client base, co-sell motion, or integration surface |
| Meeting context | Warm intro from [Name] / Conference intro / Cold outreach |

## Partnership Brief Format

```
PARTNERSHIP BRIEF
Partner:   [Name]
Type:      [Referral / Reseller / Integration / Co-sell / OEM]
Prepared:  [Date] | Prepared by: HUMMBL AI
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXECUTIVE SUMMARY
[2 sentences: why this partnership makes sense and what the shared opportunity is]

────────────────────────────────────────────────────────
WHO WE ARE
HUMMBL: [1-sentence mission statement tailored to what matters to this partner]
Stage:   [Pre-revenue / Pilot stage / Y clients in production]
Wedge:   [The specific HUMMBL capability most relevant to this partner's clients]

────────────────────────────────────────────────────────
PARTNER SNAPSHOT
[Partner name]: [What they do, who they serve, their relevant practice/product]
Why they matter: [Their market position, client access, or technology surface]

────────────────────────────────────────────────────────
MUTUAL VALUE MAP

| | What HUMMBL brings | What [Partner] brings |
|---|---|---|
| To clients | [Governed AI receipts, compliance coverage] | [Distribution, trust, client relationships] |
| To the partnership | [Differentiated product, technical depth] | [Scale, credibility, market access] |
| Revenue model | [% referral / co-sell split / OEM licensing] | [Service wrapping opportunity, platform stickiness] |

────────────────────────────────────────────────────────
USE CASE FIT
Best-fit clients:  [Description of the joint ideal client]
Example scenario:  [Concrete story: "[Partner] is deploying AI governance for a regional bank.
                    HUMMBL provides the real-time compliance receipt layer. [Partner] wraps
                    it in their managed service. Client gets audit-ready documentation automatically."]
Adjacent use cases: [Other scenarios where the partnership creates value]
Poor fit:          [Where the partnership does NOT apply — be honest]

────────────────────────────────────────────────────────
COMMERCIAL OPTIONS (propose 2-3, let partner choose)
Option A — Referral:  [Simple: partner refers, we pay X% on close]
Option B — Co-sell:   [Joint GTM: shared pipeline, coordinated demos, split revenue]
Option C — Integration: [Tech integration that makes both products stickier for shared clients]

────────────────────────────────────────────────────────
THE ASK (exactly one ask for this meeting)
[e.g., "A 30-minute call with your AI governance practice lead to explore Option A"]
[e.g., "Introduction to your 3 top regulated FS clients who are building AI governance"]
[e.g., "Pilot: run HUMMBL alongside your next engagement and share learnings"]

────────────────────────────────────────────────────────
NEXT STEPS (post-meeting)
[ ] [Partner] confirms interest level (yes / no / not yet)
[ ] If yes: schedule follow-up with decision-maker
[ ] If yes: share technical one-pager and pricing options
[ ] If not yet: agree on trigger event that would change priority
[ ] We follow up within 48 hours regardless of outcome
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BD GOVERNANCE RECEIPT
Document type:  Partnership Brief
Partner:        [Name]
Generated:      [Date]
Agent:          biz-dev (<model>)
Review required: YES — validate commercial terms with founder before presenting
Estimated human equivalent: $200-400 (senior BD lead, 2-4 hrs including meeting prep)
Time saved:     2-3 hours
Confidence:     Medium — mutual value assumptions need validation in the meeting
⚠ Do not commit to commercial terms without founder review. Revenue split %s are placeholders.
```

## Human Cost Equivalent

- Quick one-pager (meeting prep only): $150-250
- Full brief with commercial options + value map: $300-500
- Multi-partner framework (standardized): $500-900

## Skill Chains

- `[partnership-brief]` → `[discovery-call]` (partner call is a discovery call too)
- `[partnership-brief]` → `[nda-draft]` (if they want mutual NDA before sharing details)
- After meeting → `[deal-memo]` (capture what was agreed and next steps)
- If advanced → `[contractor-agreement]` or `[service-agreement]` (formalize the relationship)
