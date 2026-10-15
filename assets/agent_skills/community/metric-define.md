---
name: metric-define
description: Define business and technical metrics with collection method, baseline, target, alert threshold, and dashboard placement
version: 0.1.0
execution-mode: advisory
argument-hint: "<metric_name> [--type counter|gauge|histogram] [--alert-threshold N]"
category: fleet-ops
status: candidate
---
# Metric Define

Formally define a metric with everything needed to collect, display, and alert on it. Covers the metric name, type, collection method, baseline value, target, alert thresholds, and where it should appear on dashboards. Produces a metric specification that can be implemented by any observability system.

## When to Use
- Adding a new KPI or operational metric to the system
- Formalizing an informal "we should track this" into a spec
- Standardizing metric definitions across teams or services
- Before implementing alerting on a new signal

## Execution
1. **Define the metric** -- specify:
   - Name (snake_case, namespaced: `domain.metric_name`)
   - Type: counter (monotonically increasing), gauge (point-in-time value), or histogram (distribution)
   - Unit (requests, seconds, dollars, percentage, count)
   - Description (one sentence, unambiguous)
2. **Collection method** -- how the metric is gathered:
   - Source system or code path
   - Collection frequency (real-time, 1m, 5m, hourly, daily)
   - Aggregation method (sum, avg, p50, p95, p99, max)
3. **Baseline** -- current value or expected starting point:
   - Measure current state if possible
   - Note if baseline is estimated vs. measured
4. **Target** -- desired value and timeframe:
   - Target value with date
   - Direction (higher is better, lower is better, closer to N is better)
5. **Alert thresholds** -- when to fire alerts:
   - Warning threshold
   - Critical threshold
   - Alert destination (console, email, bus, webhook)
   - Cooldown/dedup period
6. **Dashboard placement** -- where to display:
   - Which dashboard or view
   - Visualization type (number, line chart, bar chart, heatmap)
   - Refresh interval

## Output Format
```
Metric Define | {metric_name}

## Specification
- **Name**: {domain.metric_name}
- **Type**: {counter|gauge|histogram}
- **Unit**: {unit}
- **Description**: {one sentence}

## Collection
- **Source**: {system or code path}
- **Frequency**: {interval}
- **Aggregation**: {method}

## Targets
- **Baseline**: {current value} (measured|estimated)
- **Target**: {value} by {date}
- **Direction**: {higher|lower|closer to N} is better

## Alerting
| Level | Threshold | Destination | Cooldown |
|-------|-----------|-------------|----------|
| Warning | {value} | {dest} | {period} |
| Critical | {value} | {dest} | {period} |

## Dashboard
- **View**: {dashboard name}
- **Visualization**: {type}
- **Refresh**: {interval}

## No further action needed | Metric spec ready for implementation
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Metric defined | `[kpi-track]` to start tracking the metric |
| Observability gap found | `[observability-audit]` to find other missing metrics |
| Dashboard needed | `[chart]` to generate visualization |
