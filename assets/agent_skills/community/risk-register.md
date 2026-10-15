---
name: risk-register
description: Maintain and score a risk register with likelihood, impact, mitigation status, and trending
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action add|update|review|matrix] [--domain DOMAIN]"
category: governance-compliance
status: candidate
---
# Risk Register

Maintain a structured risk register with likelihood/impact scoring, mitigation status tracking, risk trending over time, and heat map visualization. Stores entries in `_state/risk-register.jsonl` for cross-session persistence.

## When to Use
- Identifying and documenting risks for a new project or engagement
- Periodic risk review to update scores and mitigation status
- Before a major release or deployment to review outstanding risks
- Generating a risk matrix for stakeholder communication

## Execution
1. Parse `$ARGUMENTS` for `--action` (default: review) and `--domain` filter.
2. For `add`: prompt for risk description, category (technical, operational, compliance, financial, reputational), likelihood (1-5), impact (1-5), mitigation plan, and owner. Append to `_state/risk-register.jsonl`.
3. For `update`: modify an existing risk's score, status (open, mitigating, accepted, closed), or mitigation notes.
4. For `review`: display all open risks sorted by risk score (likelihood x impact), highlight any trending upward.
5. For `matrix`: generate a 5x5 likelihood-impact heat map showing risk distribution.
6. Calculate aggregate risk score per domain and overall.
7. Flag risks with no mitigation plan or stale review dates (>30 days).

## Output Format
```
Risk Register | review

| ID | Risk | Domain | L | I | Score | Status | Trend | Owner |
|----|------|--------|---|---|-------|--------|-------|-------|
| R-001 | API key exposure | Security | 2 | 5 | 10 | Mitigating | -- | the owner |
| R-002 | Single point of failure ($REMOTE_HOST) | Ops | 3 | 4 | 12 | Open | UP | team lead |
| R-003 | EU AI Act compliance gap | Compliance | 4 | 3 | 12 | Open | NEW | -- |

Summary: 3 open risks | Avg score: 11.3 | Highest: R-002, R-003 (12)

Findings:
- [WARNING] R-003 has no owner assigned
- [WARNING] R-002 trending upward -- last reviewed 35 days ago

Next action: Assign owner for R-003 and update R-002 mitigation plan.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Risks identified | `[pre-mortem]` for deeper failure scenario analysis |
| Compliance risks found | `[compliance-calendar]` to track regulatory deadlines |
| Risk review complete | `[governance-report]` to include risk summary |
