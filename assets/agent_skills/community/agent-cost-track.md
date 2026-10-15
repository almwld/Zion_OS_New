---
name: agent-cost-track
description: Track per-agent token usage and API costs with budget alerts and cost attribution
version: 0.1.0
execution-mode: advisory
argument-hint: "[--agent <name>] [--period daily|weekly|monthly] [--budget <usd>]"
category: fleet-ops
status: candidate
---
# agent-cost-track | Agent Cost Tracker

## When to Use
- Monitoring token spend across agents and sessions
- Setting budget alerts to prevent runaway costs
- Attributing costs to teams, projects, or features
- Forecasting spend for capacity planning

## Execution

### 1. Parse Arguments
- `--agent <name>`: restrict tracking to a single agent (default all)
- `--period daily|weekly|monthly`: aggregation window (default daily)
- `--budget <usd>`: budget threshold for alerting

### 2. Collect Usage Events
- Read token-usage logs from `_state/costs/` or agent telemetry
- Capture per-call: agent, model, prompt tokens, completion tokens, tool calls
- Record timestamp, session ID, and task label for attribution

### 3. Compute Costs
- Apply pricing table per model (input/output token rates)
- Sum costs by agent, model, session, and period
- Compute averages: cost per task, tokens per task, cost per session

### 4. Budget Alerts
- Compare period total against `--budget` threshold
- Flag agents exceeding 80% of budget (warning) and 100% (critical)
- Project end-of-period spend based on current run rate

### 5. Cost Attribution
- Group costs by task label, team, or project tag
- Identify top-cost agents and most expensive task types
- Flag anomalous spikes (>3x rolling average)

### 6. Emit Report
- Write report to `_state/costs/report_<period>.md`
- Write machine-readable summary to `_state/costs/summary_<period>.json`

## Output Format

```
agent-cost-track | period=daily budget=50.00

## Summary
- Period: 2024-11-08 | Agents tracked: 5
- Total cost: $32.47 | Budget: $50.00 | Utilization: 64.9%

## Per-Agent Costs
| Agent       | Calls | Tokens (in/out)   | Cost    | Budget % |
|--------------|-------|-------------------|---------|----------|
| researcher   | 142   | 1.2M / 340k       | $18.22  | 36.4%    |
| coder        | 88    | 680k / 210k       | $9.81   | 19.6%    |
| reviewer     | 34    | 210k / 95k        | $4.44   | 8.9%     |

## Top Tasks by Cost
| Task Label      | Agent       | Cost    | Calls |
|-----------------|-------------|---------|-------|
| refactor-auth   | coder       | $6.12   | 22    |
| deep-research   | researcher  | $5.88   | 18    |

## Alerts
- WARNING: researcher at 36.4% of daily budget (projected: 81%)
- No critical alerts

## Verdict
PASS | $32.47 spent, 1 warning, 0 critical alerts
```

## Skill Chains
- After tracking -> `[cost-status]` to report current spend status
- After tracking -> `[cost-forecast]` to project future spend
- Before tracking -> `[runway]` to determine budget runway
- For Cloudflare Neuron spend -> `[usage-monitor]` via `python ~/bin/usage_monitor.py status` or `python ~/bin/usage_monitor.py export --format csv`
