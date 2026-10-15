---
name: automation-roi
description: Calculate ROI for automating a manual workflow -- time saved, break-even, payback period.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"WORKFLOW to evaluate\" (e.g., \"manual briefing compilation\", \"test result triage\")"
category: dev-tools
status: candidate
---
# Automation ROI

Quantify whether automating a manual workflow is worth the investment.

## Execution

### 1. Measure the manual workflow
| Metric | Value |
|--------|-------|
| Time per execution | <minutes> |
| Frequency | <per day/week/month> |
| Who does it | <person/role> |
| Error rate | <% of times it needs rework> |
| Monthly time cost | time_per_exec x frequency_per_month |

### 2. Estimate automation cost
| Metric | Value |
|--------|-------|
| Development effort | <sessions to build> |
| Testing effort | <sessions to validate> |
| Maintenance (monthly) | <hours per month ongoing> |
| Total build cost | <sessions> |

### 3. Calculate ROI

```
Monthly savings = (manual_time - automated_time) x hourly_value
Build cost = development_sessions x session_value
Maintenance cost = monthly_maintenance x hourly_value
Net monthly benefit = monthly_savings - maintenance_cost
Break-even = build_cost / net_monthly_benefit
Annual ROI = (net_monthly_benefit x 12 - build_cost) / build_cost x 100%
```

### 4. Qualitative factors
Not everything is time savings:
- **Consistency**: Automation doesn't have bad days
- **Speed**: Runs at machine speed, not human speed
- **Availability**: Runs at 3 AM without asking
- **Scalability**: Adding 10x work doesn't need 10x people
- **Knowledge capture**: The automation IS the documentation

### 5. Decision framework
| ROI | Decision |
|-----|----------|
| Break-even < 2 weeks | **Build immediately** |
| Break-even < 2 months | **Build this sprint** |
| Break-even < 6 months | **Plan for next sprint** |
| Break-even > 6 months | **Defer** unless qualitative factors dominate |

## Output Format
```
Automation ROI | <workflow>
══════════════════════════

## Manual Workflow
<description, time, frequency>

## Automation Estimate
<development cost, maintenance>

## ROI Calculation
Monthly savings: $<X>/mo (or <Y> hours/mo)
Build cost: <Z> sessions
Break-even: <N> weeks
Annual ROI: <X>%

## Qualitative Benefits
<consistency, speed, availability>

## Decision: [BUILD NOW | PLAN | DEFER]
<rationale>
```

## Base120 Context
- Primary: **IN13** (Opportunity Cost Focus)
- Related: **DE7** (Pareto 80/20), **RE10** (Compounding Cycles)
