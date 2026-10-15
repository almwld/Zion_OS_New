---
name: outreach-strategy
description: Build a 30/60/90-day outreach strategy for a segment — channel selection, message architecture, cadence, and success metrics. Saves to _internal/biz-dev/. Powered by biz-dev agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"SEGMENT\" \"GOAL\" [--horizon 30|60|90] [--channel email|linkedin|both|event]"
category: dev-tools
status: tested
providers:
  required: [bash, python]
---
# Outreach Strategy

Build a complete outreach strategy for a target segment — channel selection, message architecture, cadence map, objection handling, and success metrics.

## When to Use

- Launching a new pipeline sprint for a segment
- Before writing an email sequence or LinkedIn campaign
- After completing an ICP profile for a new vertical
- Planning conference or event-based outreach

## Required Inputs

| Field | Example |
|-------|---------|
| Target segment | Enterprise AI compliance officers at ATL FS companies |
| Campaign goal | 3 discovery calls booked in 30 days |
| Channels available | Cold email (hummbl.io SPF/DKIM live), LinkedIn |
| Current traction | 0 clients, warm intro to Equifax CAIO |
| Trigger event | NIST AI RMF now guidance, EU AI Act risk tiers published |
| Horizon | 30-day sprint |

## Outreach Strategy Format

```
OUTREACH STRATEGY: [Segment] | [Horizon] | [Goal]
Version: 1.0 | Created: [Date]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CAMPAIGN THESIS
[One sentence: Why this segment, why now, why this message?]
[The regulatory/market trigger that makes this the right moment to reach out]

────────────────────────────────────────────────────────
GOAL & SUCCESS METRICS
Primary goal:   [e.g., 3 discovery calls booked]
Secondary:      [e.g., 2 warm intros, 5 LinkedIn connections with CAIO-level titles]
Volume target:  [# prospects in list]
Expected rates: [~X% open, ~Y% reply, ~Z% book — set realistic expectations]
Win criteria:   [What does "success" look like at end of horizon?]

────────────────────────────────────────────────────────
CHANNEL STRATEGY
Primary:    [Email / LinkedIn / Event]
Secondary:  [LinkedIn / Warm intro network / Conference]
Avoid:      [Cold calls — not appropriate for this buyer / Mass blast — kills deliverability]

CHANNEL RATIONALE
Email:      [Why email works or doesn't for this buyer]
LinkedIn:   [InMail vs connection request vs comment → DM funnel]
Events:     [Upcoming conferences, ATL AI events, Diligent Elevate, FS-specific events]

────────────────────────────────────────────────────────
MESSAGE ARCHITECTURE
Hook:       [The external trigger that earns the right to reach out]
Bridge:     [How HUMMBL connects to the trigger — without pitching]
Ask:        [One specific, low-friction ask — 20-minute call, not "schedule a demo"]

SUBJECT LINE VARIANTS (A/B test)
A: [Curiosity — question or surprising stat]
B: [Specificity — their company name, role, or recent event]
C: [Pain — the thing they're afraid of]

────────────────────────────────────────────────────────
CADENCE MAP (touches per prospect)

Day 1:   Email 1 — Hook + bridge + ask
Day 4:   LinkedIn connection request (no pitch — personalized note)
Day 8:   Email 2 — Different angle, shorter, add value (link to resource or insight)
Day 14:  LinkedIn DM — Reference email thread, different ask (share article, request)
Day 21:  Email 3 — Final follow-up — break-up frame, door open
Day 28:  LinkedIn like/comment on their content (stay warm, no direct ask)

Total touches: 6 over 28 days. Stop after touch 5 unless signal received.

────────────────────────────────────────────────────────
OBJECTION HANDLING
"We're building internally" → [Response frame]
"Not a priority right now" → [Response frame]
"We already have a vendor" → [Response frame]
"Send me more info"        → [Response — avoid the info dump trap]
No reply after 3 touches   → [What signal to infer, next action]

────────────────────────────────────────────────────────
30-DAY SPRINT PLAN

Week 1: Foundation
  - Finalize prospect list ([N] names, all [title] at [vertical])
  - Verify emails with Hunter.io / LinkedIn
  - Send Email 1 to Wave 1 ([N] prospects)
  - Connect with all on LinkedIn same day

Week 2: Follow-up
  - Send Email 2 to non-openers from Week 1
  - DM anyone who connected on LinkedIn
  - Research specific trigger events for non-responders

Week 3: Final push
  - Email 3 (break-up) to silent prospects
  - Reach out to anyone who opened but didn't reply
  - Identify top 3 warm intro paths from network

Week 4: Learn + adjust
  - Score campaign: opens, replies, calls booked
  - Update ICP with learnings
  - Plan Wave 2 (new segment or retargeted Wave 1)

────────────────────────────────────────────────────────
PROSPECT LIST CRITERIA
Included:   [Title, seniority, vertical, company size]
Excluded:   [Competitors, investors, companies already in pipeline]
Sources:    [LinkedIn Sales Navigator, Apollo, Hunter.io, event attendee lists]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BD GOVERNANCE RECEIPT
Document type:  Outreach Strategy
Generated:      [Date]
Agent:          biz-dev (<model>)
Review required: YES — validate channel selection and cadence before executing
Estimated human equivalent: $400-800 (senior BDR strategy session, 4-6 hrs)
Time saved:     4-6 hours
Confidence:     Medium — reply rates are estimates; calibrate after first 20 sends
⚠ Do not execute at scale before sending 5-10 test emails and reviewing reply quality.
```

## Human Cost Equivalent

- 30-day single-channel strategy: $300-500
- 60-day multi-channel with cadence map: $500-900
- Full 90-day campaign with A/B plan: $800-1,500

## Skill Chains

- `[outreach-strategy]` → `[email-sequence]` (write the actual emails)
- `[outreach-strategy]` → `[icp-profile]` (if ICP not yet defined)
- `[outreach-strategy]` → `[landing-page-copy]` (build the destination page)
- After campaign → `[win-loss]` (analyze what worked)
- After calls booked → `[discovery-call]` (prep for each call)
