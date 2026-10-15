---
name: kpi-track
description: Define and track KPIs with thresholds, trend direction, and alerting
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action define|update|dashboard] [--domain dev|business|ops]"
category: fleet-ops
status: candidate
---
# KPI Tracker

Define and track Key Performance Indicators with configurable thresholds, trend analysis, and threshold-based alerting. Supports development, business, and operations domains with visual dashboard output.

## When to Use
- When establishing measurable indicators for a new initiative or engagement
- During periodic reviews to assess performance against targets
- When building a dashboard view of operational or business health
- When a KPI crosses a threshold and needs attention

## Execution
1. Parse `$ARGUMENTS` for action (define, update, dashboard) and domain filter
2. For `define`: create a new KPI with name, target, threshold (warning/critical), unit, and owner
3. For `update`: record a new data point for a KPI with timestamp
4. For `dashboard`: render all KPIs (or filtered by domain) with current value, trend, and status
5. Calculate trend direction from last 5 data points (improving, stable, declining)
6. Flag any KPI in WARNING (within 20% of threshold) or CRITICAL (beyond threshold) state
7. Store all data in `_state/kpis.jsonl`

## Output Format
```
KPI Dashboard | <domain>
=========================

| KPI | Current | Target | Trend | Status |
|-----|---------|--------|-------|--------|
| ... | ... | ... | UP/STABLE/DOWN | GREEN/YELLOW/RED |

## Alerts
- [CRITICAL] <KPI>: <value> exceeds threshold <threshold>
- [WARNING] <KPI>: <value> approaching threshold

## Trend Details
- <KPI>: <last 5 values> — <interpretation>

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| KPI data ready for stakeholders | `[investor-update]` to include KPI trends |
| Need visual representation | `[chart]` to generate trend graphs |
| KPIs inform governance reporting | `[governance-report]` for client-facing metrics |
