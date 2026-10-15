---
name: governance-scorecard
description: Traffic-light scorecard of governance posture across all domains and frameworks
version: 0.1.0
execution-mode: advisory
argument-hint: "[--org NAME] [--format compact|detailed]"
category: governance-compliance
status: candidate
---
# Governance Scorecard

Quick traffic-light scorecard of governance posture across all domains and frameworks. Provides a dashboard view showing where governance is strong, adequate, or needs attention -- suitable for executive briefings or internal health checks.

## When to Use
- Quick governance health check before a client meeting
- Executive summary of compliance posture
- Identifying which governance domains need the most attention
- Periodic (monthly/quarterly) governance review

## Execution
1. Parse `$ARGUMENTS` for `--org` (default: current project/org) and `--format` (default: `compact`)
2. Assess governance across domains:
   - **AI Safety**: kill switch, circuit breakers, agent guardrails, delegation controls
   - **Data Governance**: data handling policies, retention, access controls
   - **Security**: secret management, vulnerability scanning, access control
   - **Compliance**: framework coverage (NIST, ISO, SOC 2), evidence gaps
   - **Operations**: incident response, monitoring, alerting, on-call
   - **Agent Governance**: bus protocol, identity management, scope controls, audit trail
   - **Change Management**: branching policy, PR review, CI/CD gates
3. For each domain, score:
   - GREEN: controls in place, evidence current, no gaps
   - YELLOW: controls partially in place, some evidence gaps, minor risks
   - RED: significant gaps, missing controls, or stale evidence
4. Check evidence freshness: when was each control last verified?
5. If `--format detailed`: include per-control breakdown within each domain
6. If `--format compact`: one line per domain with score and top concern
7. Calculate overall governance score (weighted average)
8. Identify top 3 priorities for improvement

## Output Format
```
Governance Scorecard | {org} | {date}

Overall: {GREEN|YELLOW|RED} ({score}/100)

Domain Scores:
  {icon} AI Safety: {score} -- {top concern or "no issues"}
  {icon} Data Governance: {score} -- {top concern}
  {icon} Security: {score} -- {top concern}
  {icon} Compliance: {score} -- {top concern}
  {icon} Operations: {score} -- {top concern}
  {icon} Agent Governance: {score} -- {top concern}
  {icon} Change Management: {score} -- {top concern}

Top Priorities:
1. {domain}: {action needed}
2. {domain}: {action needed}
3. {domain}: {action needed}

Evidence Freshness: {oldest verification date}

Next action: {recommendation}
```

## Skill Chains

### Mandatory

- None — governance-scorecard is `advisory` mode (read-only assessment).

### Advisory

| After this skill... | Consider... |
|--------------------|-------------|
| Came from maturity assessment | `[governance-maturity]` provided the input |
| Need detailed report | `[governance-report]` for full narrative |
| Need evidence collection | `[evidence-pack]` to gather artifacts |

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (read-only assessment)
- **T3 (Medium)**: May run without restriction (read-only assessment)
- **T4 (Probationary)**: May run (read-only — no side effects)
- **Operator**: Override any restriction
