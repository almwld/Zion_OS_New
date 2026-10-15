---
name: renewal-check
description: Flag engagements approaching end date and draft renewal or upsell proposal email
version: 0.1.0
execution-mode: advisory
argument-hint: "[--horizon 30|60|90 days]"
category: sales-marketing
status: candidate
---
# Renewal Check

Scan all active engagements for contracts approaching their end date within the specified horizon. For each flagged engagement, assess renewal likelihood, identify upsell opportunities based on delivered value, and draft a renewal or upsell proposal email.

## When to Use
- During weekly or monthly business reviews to catch upcoming renewals
- When proactively managing client retention pipeline
- Before quarter-end to ensure no renewals slip through
- When looking for upsell opportunities in existing accounts

## Execution
1. Parse `$ARGUMENTS` for horizon (default: 60 days)
2. Read `_state/engagements.jsonl` for all active engagements with end dates
3. Filter engagements ending within the horizon window
4. For each flagged engagement, assess: deliverables completed, client health score, utilization rate
5. Categorize each as: RENEW (standard), UPSELL (expand scope), AT_RISK (health issues), ENDING (no renewal expected)
6. Draft a personalized renewal or upsell email for each RENEW/UPSELL engagement
7. For AT_RISK engagements, suggest a recovery action plan

## Output Format
```
Renewal Check | Horizon: <N> days
===================================

## Upcoming Renewals (<count>)
| Client | End Date | Days Left | Category | Action |
|--------|----------|-----------|----------|--------|
| ... | ... | ... | RENEW/UPSELL/AT_RISK | ... |

## Draft Emails

### <Client 1> — RENEW
Subject: ...
Body: ...

### <Client 2> — UPSELL
Subject: ...
Body: ...

## At-Risk Recovery Plans
- [CLIENT]: <issue> — <recommended action>

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Renewal confirmed, need formal proposal | `[proposal-write]` to draft the renewal proposal |
| Ready to send the renewal email | `[send-email]` to deliver |
| Need current engagement data first | `[engagement-tracker]` to refresh status |
