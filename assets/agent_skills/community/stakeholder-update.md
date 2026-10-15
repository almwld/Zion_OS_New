---
name: stakeholder-update
description: Draft a stakeholder update (investor, board, partner, customer, team). Audience-calibrated register, metrics-anchored, action-oriented. Saves to _internal/comms/. Powered by exec-assistant agent.
version: 1.0.0
execution-mode: side_effecting
argument-hint: "\"AUDIENCE\" \"PERIOD\" [--tone formal|founder|direct] [--format email|doc|slack]"
category: sales-marketing
status: candidate
---
# Stakeholder Update

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=stakeholder-update] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Draft a professional update for any stakeholder group — investor, board, key partner, enterprise customer, or internal team.

## When to Use

- Monthly investor update
- Board meeting narrative (quarterly)
- Key partner check-in (not a sales call)
- Enterprise client progress update (between formal reports)
- Internal all-hands update
- Keeping a mentor or advisor in the loop

## Required Inputs

| Field | Example |
|-------|---------|
| Audience | Seed investors / Board / Equifax procurement team |
| Period | April 2026 / Q1 2026 |
| Key highlights | 2 enterprise meetings, Novo account approved |
| Key metrics | Pipeline: $X, Closed: $Y, Burn: $Z/mo |
| Challenges | GA annual registration overdue, Stripe login unclear |
| Asks | Intro to [X], feedback on pricing, investor referral |
| Tone | Confident / Direct / Formal |

## Register by Audience

| Audience | Lead with | Tone | Length |
|---|---|---|---|
| Seed investors | Metrics + momentum | Confident, honest | 300-500 words |
| Board | Performance vs plan | Data-first, no surprises | 500-800 words |
| Enterprise client | Progress + next steps | Professional, value-focused | 200-400 words |
| Strategic partner | Mutual benefit | Peer-to-peer | 150-300 words |
| Internal team | Priorities + context | Direct, energizing | 200-400 words |

## Investor Update Template

```
[COMPANY] Update — [Month/Quarter YEAR]

HEADLINE
[One sentence: the most important thing right now]

METRICS
- Revenue/ARR: $[X] ([trend])
- Pipeline: $[X] ([# deals])
- Burn: $[X]/mo | Runway: [X] months
- [1-2 product/growth metrics]

PROGRESS
- [✓ Completed milestone 1]
- [✓ Completed milestone 2]
- [🔄 In progress: milestone 3]

CHALLENGES
[Honest, brief — show you see the problems]

NEXT 30 DAYS
- [Priority 1]
- [Priority 2]

ASK
[One specific request]

[Signature]
```

## Human Cost Equivalent

- Monthly investor update: $75-150 EA time
- Board narrative package: $200-400

## Skill Chains

### Mandatory

- `[content-review]` MUST pass before sending the update externally to any stakeholder (investor, board, partner, customer, team). The draft may be generated without it, but no external delivery without a passed content review.

### Advisory

- `[stakeholder-update]` → `[send-email]` — deliver the update (requires `[content-review]` pass first)
- `[stakeholder-update]` (board version) → `[exec-summary]` — condensed 1-pager
- `[stakeholder-update]` → `[investor-update]` — formal version with full financial table
- Before writing → `[financial-model]` or `[runway]` — pull current metrics

## Authority

- **T1 (TRUSTED)**: Full run — draft and send (with `[content-review]` pass)
- **T2 (Active/High)**: Draft and send with `[content-review]` pass
- **T3 (Medium)**: Draft only; sending requires operator approval + `[content-review]` pass
- **T4 (Probationary)**: BLOCKED — may not draft or send stakeholder updates
- **Operator**: Override any restriction
