---
name: governance-report
description: Generate periodic governance health report for client leadership or board -- status, metrics, risk, progress.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--org NAME] [--period monthly|quarterly] [--audience board|leadership|technical]"
category: governance-compliance
status: candidate
---
# Governance Report

Periodic governance health report suitable for executive presentation. Tracks control implementation progress, risk trends, incident summary, and compliance posture. Recurring deliverable for governance consulting engagements.

## When to Use
- Monthly/quarterly client reporting
- Board-level governance updates
- Internal governance health check
- When user says "governance report" or "board report"

## Report Sections

### For Board/Leadership
1. **Executive Summary** (1 paragraph)
2. **Compliance Scorecard** (traffic lights per framework)
3. **Risk Posture** (trending up/down/stable)
4. **Key Metrics** (3-5 numbers that matter)
5. **Incidents** (summary, not detail)
6. **Recommendations** (2-3 actions)

### For Technical Audience
All of the above, plus:
7. **Control Implementation Status** (detailed table)
8. **Gap Closure Progress** (from remediation plan)
9. **Audit Findings** (if applicable)
10. **Technical Recommendations**

## Execution

1. **Gather data**: Control catalog, gap analysis, incident log, metrics
2. **Compute trends**: Compare to previous period
3. **Score compliance**: Per-framework percentage
4. **Draft narrative**: Highlight changes, risks, wins
5. **Format for audience**: Board (2 pages) vs technical (5-10 pages)

## Output Format

```
Governance Report | {org} | {period}
=====================================

## Executive Summary
{One paragraph: overall posture, key change, recommendation}

## Compliance Scorecard
| Framework | Score | Trend | Status |
|-----------|-------|-------|--------|
| NIST AI RMF | 72% | +8% | ON TRACK |
| ISO 42001 | 45% | +12% | NEEDS ATTENTION |
| SOC 2 | 88% | +2% | STRONG |

## Key Metrics
| Metric | Value | Previous | Trend |
|--------|-------|----------|-------|
| Controls implemented | 34/52 | 28/52 | Improving |
| Open risks | 7 | 11 | Improving |
| Incidents (period) | 1 | 3 | Improving |
| Mean time to remediate | 4.2 days | 7.1 days | Improving |

## Incidents Summary
| Date | Severity | Description | Status |
|------|----------|-------------|--------|

## Recommendations
1. {Most important action}
2. {Second priority}
3. {Third priority}

## Next Period Focus
{What we'll prioritize in the next reporting period}
```

## Skill Chains

### Mandatory

- None — governance-report is `advisory` mode (generates report documents).

### Advisory

| After this skill... | Consider... |
|--------------------|-------------|
| Report drafted | `[exec-summary]` (if needs condensing) |
| For email delivery | `[send-email]` (send to client, with `[content-review]` passed) |
| Trends negative | `[risk-register]` (update risks) |
| Engagement renewal | `[renewal-check]` (is contract ending?) |
| Metrics improved | `[case-study]` (capture as success story) |

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (advisory — generates report docs)
- **T3 (Medium)**: May run without restriction (advisory — generates report docs)
- **T4 (Probationary)**: May run (advisory — no side effects beyond file generation)
- **Operator**: Override any restriction
