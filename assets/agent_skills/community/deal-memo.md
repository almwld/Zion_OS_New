---
name: deal-memo
description: Write an internal deal memo after a promising prospect or partner conversation. Captures signal, next steps, stakeholders, and deal shape. Saves to _internal/biz-dev/. Powered by biz-dev agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"COMPANY\" \"CONTACT\" \"MEETING_DATE\" [--type prospect|partner|investor]"
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---
# Deal Memo

Write a structured internal memo after a promising first meeting, warm intro, or inbound inquiry. Captures signal quality, stakeholder map, deal shape, and next steps before the details fade.

## When to Use

- After a first discovery call with a prospect
- After a warm intro that showed meaningful interest
- After a conference conversation worth following up
- After a partner meeting where commercial terms were explored
- Before handing a deal to a co-founder or advisor for their input

## Required Inputs

| Field | Example |
|-------|---------|
| Company | Equifax |
| Contact | Raghu Kulkarni, CAIO |
| Meeting date | April 7, 2026 |
| Meeting type | Discovery call / Warm intro / Inbound inquiry / Conference |
| What was said | [Key quotes, pain points mentioned, objections raised] |
| Deal shape | Pilot → $5,500 governance assessment |
| Next step agreed | Follow-up call Apr 15 with IT security lead |

## Deal Memo Format

```
DEAL MEMO — CONFIDENTIAL
Company:    [Name]
Contact:    [Name], [Title]
Date:       [Meeting date]
Type:       [Prospect / Partner / Investor]
Stage:      [Awareness / Discovery / Evaluation / Decision / Closed]
Written by: [Author]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

HEADLINE
[One sentence: the most important thing from this meeting]
[e.g., "Raghu confirmed NIST AI RMF compliance is a board-level priority for Q3 2026
and asked us to come back with a scoped pilot proposal."]

────────────────────────────────────────────────────────
SIGNAL ASSESSMENT
Interest level:    [🔥 Hot / 🟡 Warm / 🧊 Cool / ❓ Unknown]
Budget signal:     [Confirmed / Likely / Unclear / None mentioned]
Timeline:          [Immediate / Q2 / H2 2026 / No urgency stated]
Decision authority: [This contact decides / Needs to bring in X / Committee decision]
Overall:           [Worth pursuing / Continue softly / Deprioritize / Close out]

────────────────────────────────────────────────────────
WHAT WAS SAID

Pain points raised:
- [Direct quote or close paraphrase — label as [QUOTE] or [PARAPHRASE]]
- [Pain point 2]

Questions they asked:
- [Question 1 — signals what they're evaluating]
- [Question 2]

Objections raised:
- [Objection] — [How it was handled or left open]

What resonated:
- [The thing that made them lean in]

What didn't land:
- [The thing that created confusion or skepticism]

────────────────────────────────────────────────────────
STAKEHOLDER MAP
Primary contact:   [Name, title, role in decision]
Economic buyer:    [Name or "unknown"] — [Estimated title/level]
Champion:          [Who will sell this internally if we're not in the room?]
Blockers:          [IT security / Legal / CFO / Procurement — who can kill this?]
Influencers:       [Who do they trust that we might reach?]

────────────────────────────────────────────────────────
DEAL SHAPE
Product fit:       [Which HUMMBL capability addresses their primary pain?]
Entry point:       [Governance assessment $5,500 / Pilot $X / Enterprise $Y]
Expansion path:    [If pilot succeeds, what's the natural next purchase?]
Timeline to close: [Best case / Realistic / Worst case]
Risk:              [What could kill this deal?]

────────────────────────────────────────────────────────
COMPETITIVE CONTEXT
Mentioned alternatives: [None / "We're evaluating Credo AI" / "We're building internally"]
Our positioning:        [How HUMMBL is differentiated from what they mentioned]

────────────────────────────────────────────────────────
NEXT STEPS
[ ] [Action — owner — deadline]
    e.g., Send scoped pilot proposal by Apr 10
[ ] [Action — owner — deadline]
    e.g., Book follow-up call for Apr 15 — include IT security lead
[ ] [Action — owner — deadline]
    e.g., Connect on LinkedIn with their head of AI risk

FOLLOW-UP EMAIL: [draft inline or use [email-sequence]]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BD GOVERNANCE RECEIPT
Document type:  Deal Memo
Company:        [Name]
Generated:      [Date]
Agent:          biz-dev (<model>)
Review required: Recommended — especially before sharing deal shape with co-founders or advisors
Estimated human equivalent: $100-200 (senior AE, 1-2 hrs post-call documentation)
Time saved:     1-2 hours
Confidence:     High (if inputs are accurate) — this document is only as good as your recall
⚠ Write while fresh. Signal assessment degrades after 24 hours.
```

## Signal Interpretation Guide

| Signal | What it means | Action |
|--------|--------------|--------|
| They asked about pricing | Budget thinking has started | Send pricing guide + pilot framing |
| They asked for references | Active evaluation mode | Provide case study proxy + offer reference call |
| They said "we're building it" | Not a no — they want to validate the build | Ask what they've built so far |
| They went quiet after warm intro | Either busy or lost | Single follow-up, then pause 30 days |
| They forwarded to a colleague | Internal champion is forming | Engage the colleague directly |
| They asked technical questions | Economic buyer isn't in the room yet | Ask who owns technical evaluation |

## Human Cost Equivalent

- Quick deal memo (20-min meeting): $75-150
- Full post-discovery memo: $150-250
- Complex multi-stakeholder deal: $250-400

## Skill Chains

- `[deal-memo]` → `[proposal-write]` (if signal is hot → move to proposal)
- `[deal-memo]` → `[discovery-call]` (prep for next call using this memo)
- `[deal-memo]` → `[send-email]` (send the follow-up)
- `[deal-memo]` → `[crm]` (log the contact and deal stage)
- If partner meeting → `[partnership-brief]` (update brief with learnings)
- Monthly → `[win-loss]` (analyze deals that closed or went cold)
