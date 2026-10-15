---
name: churn-analysis
description: Analyze client churn signals including engagement drops, support spikes, and renewal risk scoring
version: 0.1.0
execution-mode: advisory
argument-hint: "[--client NAME|all] [--period 90d] [--signals engagement|support|renewal]"
category: fleet-ops
status: candidate
---
# Churn Analysis

Detect early warning signs of client churn by analyzing engagement frequency, support interaction patterns, and renewal timeline proximity. Produces a risk score per client with actionable recommendations to improve retention.

## When to Use
- Quarterly review of client health across the portfolio
- Before a renewal conversation to understand risk level
- When engagement frequency with a client drops noticeably
- After a support escalation to assess broader relationship health

## Execution
1. Parse `$ARGUMENTS` for client filter (default: `all`), lookback period (default: `90d`), and signal types.
2. Gather engagement data from available sources:
   - CRM interactions (`_state/crm/` or Google Sheets via `[crm]`)
   - Email/meeting frequency (calendar, sent emails)
   - Bus messages and deliverable history
   - Invoice and payment patterns (`_state/billing/`)
3. For each client, compute signal scores:
   - **Engagement**: Compare current-period interaction frequency to baseline. Flag drops > 30%.
   - **Support**: Count support requests, escalations, and unresolved issues. Flag volume spikes > 2x.
   - **Renewal**: Days until contract end, renewal discussion status, competitor mentions.
4. Calculate composite churn risk score (0-100, where 100 = highest risk).
5. Classify each client: GREEN (0-30), YELLOW (31-60), RED (61-100).
6. Generate specific retention recommendations per at-risk client.

## Output Format
```
Churn Analysis | period | client_filter

## Portfolio Summary
- Clients analyzed: N
- GREEN: N | YELLOW: N | RED: N

## Risk Scores
| Client | Risk Score | Trend | Top Signal | Days to Renewal |
|--------|-----------|-------|------------|-----------------|
| {name} | {0-100} | {up/down/stable} | {signal} | {N or N/A} |

## At-Risk Details
### {Client Name} -- {YELLOW|RED}
- Engagement: {trend description with data}
- Support: {volume and severity}
- Renewal: {timeline and status}
- Recommendation: {specific action}

Next action: {suggestion or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Identifying at-risk clients | `[engagement-tracker]` for detailed interaction history |
| Finding upcoming renewals | `[renewal-check]` to draft renewal proposals |
| Drafting retention outreach | `[follow-up]` to send targeted communication |
