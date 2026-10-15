---
name: email-sequence
description: Draft a 3-5 email nurture or outreach sequence. Goal-driven, audience-specific, with subject line variants. Saves to _internal/marketing/ or _state/outreach/. Powered by copywriter agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"GOAL\" \"AUDIENCE\" [--emails 3|5] [--tone challenger|educational|founder]"
category: sales-marketing
status: tested
providers:
  required: [bash, python]
---
# Email Sequence

Generate a complete email sequence (3-5 emails) for outreach, nurture, or onboarding.

## When to Use
- Cold outreach to a prospect segment
- Follow-up sequence after a discovery call
- Nurture sequence for leads who haven't responded
- Onboarding sequence for new clients
- Re-engagement sequence for stale leads

## Required Inputs

| Field | Example |
|-------|---------|
| Goal | Book a discovery call / Close a deal / Onboard a client |
| Audience | Enterprise AI compliance officers / Solo founders / Technical buyers |
| Product/offer | HUMMBL AI governance assessment |
| Pain point | "Don't know if their AI deployments are compliant" |
| Number of emails | 3 (short) or 5 (full nurture) |
| Tone | challenger / educational / founder |
| Sender name | Reuben Bowlby, HUMMBL |

## Sequence Structures

**3-Email Cold Outreach:**
1. The hook — lead with their pain, not your product
2. The proof — evidence, story, or insight
3. The close — direct ask with low-friction CTA

**5-Email Nurture:**
1. The relevance email — why I'm reaching out now
2. The insight email — something useful, no ask
3. The social proof email — case study or benchmark
4. The objection email — address the most common "not now"
5. The breakup email — last attempt, creates urgency

**3-Email Post-Call Follow-Up:**
1. Same-day recap — what we discussed, next steps
2. Day 3 value add — relevant resource or insight
3. Day 7 check-in — soft follow-up, keep it warm

## Output Format Per Email

```
EMAIL [N] of [TOTAL]
Subject: [primary subject line]
Subject B: [A/B variant]
Preview text: [50-90 chars]

---
[Email body]
---

Send timing: [Day X after trigger]
Goal: [What this email should achieve]
```

## Quality Standards
- Subject lines: specific, avoid spam triggers, under 50 chars preferred
- Body: under 200 words for cold; up to 400 for nurture
- One CTA per email, clear and low-friction
- No attachments in cold emails (use links)
- Personalization hooks: [COMPANY], [PAIN_POINT], [TRIGGER_EVENT]

## Human Cost Equivalent
- 3-email sequence: $150-450 copywriter time
- 5-email sequence: $300-800 copywriter time

## Skill Chains
- Before sequence → `[discovery-call]` (understand the prospect first)
- After sequence draft → `[content-review]` (check before sending)
- Sequence approved → `[send-email]` (send email 1), `[crm]` (log campaign start)
- Responses received → `[follow-up]` (manage replies)
