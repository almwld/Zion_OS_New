---
name: sla-track
description: Define and monitor SLAs/SLOs/SLIs with burn rate calculation, error budget tracking, and breach alerting
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action define|status|burn-rate] [--slo NAME]"
category: governance-compliance
status: candidate
---
# SLA Track

Define, monitor, and report on Service Level Agreements (SLAs), Service Level Objectives (SLOs), and Service Level Indicators (SLIs). Tracks error budgets, calculates burn rates, and alerts on approaching or breached thresholds. Stores definitions in `_state/sla/definitions.jsonl` and measurements in `_state/sla/measurements.jsonl`.

## When to Use
- Defining SLOs for a new service or client engagement
- Checking current SLO compliance status before a client meeting
- Investigating whether error budget is being consumed too fast
- Setting up proactive alerting before SLA breaches occur

## Execution
1. Parse `$ARGUMENTS` for action (default: `status`) and optional SLO name filter.
2. For `define` action:
   - Prompt for SLI (what to measure), SLO (target percentage), SLA (contractual commitment), and measurement window.
   - Write definition to `_state/sla/definitions.jsonl`.
3. For `status` action:
   - Read all SLO definitions and recent measurements.
   - Calculate current compliance percentage for each SLO.
   - Compare against targets and flag any breaches or near-breaches (< 10% error budget remaining).
4. For `burn-rate` action:
   - Calculate the rate at which error budget is being consumed.
   - Project when the error budget will be exhausted at current burn rate.
   - Flag if burn rate exceeds 1x (budget will be exhausted before window ends).
5. Generate alerts for any SLO with < 20% error budget remaining.

## Output Format
```
SLA Track | action | slo_filter

## SLO Status
| SLO | SLI | Target | Current | Error Budget | Status |
|-----|-----|--------|---------|-------------|--------|
| {name} | {metric} | {99.9%} | {99.7%} | {30% remaining} | {OK|WARN|BREACH} |

## Burn Rate Analysis
- {SLO name}: {Nx} burn rate, budget exhausted in {N days} at current pace

## Error Budget History
- {SLO name}: {trend over last 7/30 days}

## Alerts
- {any SLOs approaching or in breach}

Next action: {suggestion or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Defining new SLOs | `[kpi-track]` to align SLOs with business KPIs |
| Detecting high burn rate | `[alert-rule]` to set up proactive notifications |
| SLA breach detected | `[incident]` to begin triage and response |
