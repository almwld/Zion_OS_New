---
name: alert-digest
description: Summarize and deduplicate recent alerts, identify fatigue patterns
version: 0.1.0
execution-mode: advisory
argument-hint: "[--period 24h|7d|30d] [--source ci|health|bus|all]"
category: governance-compliance
status: candidate
---
# Alert Digest

Summarize and deduplicate recent alerts, identify fatigue patterns, and recommend consolidation. Helps distinguish signal from noise in alerting systems and prevents alert blindness.

## When to Use
- Morning review of overnight alerts
- Weekly alerting health check
- After noticing many similar alerts firing
- When alert fatigue is causing important alerts to be missed

## Execution
1. Parse `$ARGUMENTS` for `--period` (default: `24h`) and `--source` (default: `all`)
2. Collect alerts from configured sources:
   - `ci`: GitHub Actions workflow failures and warnings
   - `health`: health probe alerts from `services/health.py`
   - `bus`: coordination bus BLOCKED and error messages
   - `all`: all sources
3. Deduplicate: group identical or near-identical alerts (same source, same message template)
4. For each group: count occurrences, first/last seen, affected services
5. Identify fatigue patterns:
   - **Flapping**: alerts that fire and resolve repeatedly (>3 cycles in period)
   - **Noisy**: single alert firing >10 times in period
   - **Stale**: alert that has been continuously firing for >7 days with no action
   - **Correlated**: multiple alerts that always fire together (should be one alert)
6. Recommend consolidation actions for each pattern
7. Compute alert-to-action ratio: how many alerts led to actual human action

## Output Format
```
Alert Digest | period: {period} | source: {source}

Total Alerts: {N} ({unique} unique)
Actionable: {N} | Noise: {N} | Ratio: {percent}%

Top Alert Groups:
1. {alert_name} -- {count}x -- {source} -- {status}
2. {alert_name} -- {count}x -- {source} -- {status}

Fatigue Patterns:
- Flapping: {list or "none"}
- Noisy: {list or "none"}
- Stale: {list or "none"}
- Correlated: {list or "none"}

Recommendations:
1. {action}

Next action: {recommendation}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Noise identified | `[alert-rule]` to tune thresholds |
| Observability gaps found | `[observability-audit]` for full review |
| Stale alerts found | `[stale-cleanup]` to remove dead alerts |
