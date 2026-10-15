---
name: icp-profile
description: Build a detailed Ideal Customer Profile with firmographic, psychographic, and trigger event data. Includes persona card, pain map, and outreach angle. Saves to _internal/biz-dev/. Powered by biz-dev agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"SEGMENT\" \"VERTICAL\" [--depth quick|full] [--persona title]"
category: dev-tools
status: candidate
---
# ICP Profile

Build a detailed Ideal Customer Profile for a target segment — firmographic filters, buyer persona, pain map, trigger events, and first-contact angle.

## When to Use

- Starting a new outreach campaign to a new segment
- Handing off to a BDR or SDR for prospecting
- Aligning messaging before writing email sequences
- Before building a landing page targeting a specific ICP

## Required Inputs

| Field | Example |
|-------|---------|
| Segment name | Enterprise AI compliance officers at regulated FS companies |
| Vertical | Financial services — banking, insurance, wealth management |
| Geography | US, Southeast focus (ATL ecosystem) |
| Company size | $500M–$5B revenue, 500–5,000 employees |
| Known pain points | Can't prove AI compliance, NIST AI RMF mandate pressure |
| Competitive context | None / Credo AI / Holistic AI / internal audit teams |

## ICP Profile Format

```
ICP PROFILE: [Segment Name]
Version: 1.0 | Created: [Date]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FIRMOGRAPHIC FILTERS
Industry:      [SIC/NAICS codes or plain English]
Revenue:       [Range — companies below this don't have budget; above are too slow]
Headcount:     [Range]
Tech stack:    [Cloud providers, AI tools, governance tools they likely use]
Regulatory:    [Which regulations they're subject to — NIST, ISO, EU AI Act, HIPAA, etc.]
Geography:     [Regions / cities]
Signals:       [LinkedIn keywords, job postings, news events that flag readiness]

────────────────────────────────────────────────────────
BUYER PERSONA: PRIMARY
Title:         [Most common title for decision-maker]
Alt titles:    [VP AI, Chief Data Officer, Head of AI Governance, etc.]
Reporting to:  [CTO / CRO / General Counsel / Board Risk Committee]
Goals:         [What they're measured on — compliance, risk reduction, AI velocity]
Fears:         [What keeps them up at night — audit failure, AI incident, regulatory fine]
Budget owner:  [Yes / Shared / No — do they control spend or just influence?]
Buy horizon:   [Typical decision timeline for a tool like this]

────────────────────────────────────────────────────────
BUYER PERSONA: CHAMPION (economic buyer is above, but this person sells it internally)
Title:         [AI Risk Manager / Compliance Analyst / AI Governance Lead]
Motivation:    [Career protection, proving ROI, reducing manual audit work]
Objections:    [Budget, IT approval, "we're building internally", "not a priority yet"]

────────────────────────────────────────────────────────
PAIN MAP
Pain 1 (Critical):  [Name] — [Description] — [Consequence if unresolved]
Pain 2 (High):      [Name] — [Description] — [Consequence if unresolved]
Pain 3 (Medium):    [Name] — [Description] — [Consequence if unresolved]

────────────────────────────────────────────────────────
TRIGGER EVENTS (what creates urgency)
Regulatory:    [New rule, enforcement action, public guidance]
Org:           [New CAIO hire, AI incident at peer company, board inquiry]
Tech:          [New AI tool deployed, LLM procurement, model failure]
Financial:     [Earnings call AI mention, investor scrutiny, audit cycle]

────────────────────────────────────────────────────────
COMPETITIVE LANDSCAPE
In-house:      [What they might build internally — and why it fails]
Competitor A:  [Name] — [How to position vs them]
Competitor B:  [Name] — [How to position vs them]
HUMMBL wedge:  [The specific angle that wins — what neither competitor nor in-house covers]

────────────────────────────────────────────────────────
FIRST-CONTACT ANGLE
Hook:          [The one thing that opens the door — regulatory trigger, peer incident, etc.]
Email subject: [3 subject line variants — curiosity / specificity / pain]
Message frame: [Pain-first sentence that makes them say "yes, that's us"]

────────────────────────────────────────────────────────
DISQUALIFIERS (do not pursue if...)
- [e.g., company uses only on-prem AI with no cloud exposure]
- [e.g., legal has already banned all AI tools company-wide]
- [e.g., company size below $200M — no governance budget]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BD GOVERNANCE RECEIPT
Document type:  ICP Profile
Generated:      [Date]
Agent:          biz-dev (<model>)
Review required: YES — validate against actual prospect conversations before scaling
Estimated human equivalent: $300-600 (senior BDR + market research, 3-5 hrs)
Time saved:     3-5 hours
Confidence:     Medium — accuracy improves with prospect interview data
⚠ Treat firmographics and pain points as hypotheses until validated in calls.
```

## Validation Protocol

ICPs degrade fast. Validate against real prospect calls:
- Run 5 discovery calls within the ICP
- Score each call: Did the pain map resonate? (1-5)
- Update ICP after every 3rd call
- Flag disqualifiers as soon as a pattern emerges

## Human Cost Equivalent

- Quick ICP (top firmographics + 1 persona): $150-300
- Full ICP (firmographics + 2 personas + pain map + triggers): $300-600
- ICP + competitive positioning + validated against calls: $800-1,500

## Skill Chains

- `[icp-profile]` → `[outreach-strategy]` (build the campaign)
- `[icp-profile]` → `[email-sequence]` (write the emails for this ICP)
- `[icp-profile]` → `[landing-page-copy]` (build the ICP-specific page)
- `[icp-profile]` → `[discovery-call]` (prep for first live call)
- After 5+ calls → update ICP with validated/invalidated assumptions
