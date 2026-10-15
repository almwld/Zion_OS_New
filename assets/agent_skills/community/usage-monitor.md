---
provider-specific: true
name: usage-monitor
description: Track Cloudflare Neuron consumption against the 10K/day free-tier ceiling. Log inference calls, check status, view trends, and set alerts. Auto-logs from reasoning-router.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[status|log|trend|alert|reset]"
category: backend-infra
status: candidate
---
# Usage Monitor

Track Cloudflare Workers AI Neuron consumption against the 10,000 Neurons/day free-tier ceiling. The ceiling is shared across ALL Cloudflare models.

## When to Use
- After running inference via `reasoning-router` or direct Cloudflare calls
- Before starting a long batch job to check remaining budget
- Periodically to monitor consumption trends
- When setting up alerts for budget thresholds

## Operations

### Check today's status
```bash
python ~/bin/usage_monitor.py status
```
Output shows: total Neurons used, remaining, % of ceiling, breakdown by model and provider.

### Log a manual entry
```bash
python ~/bin/usage_monitor.py log --provider cloudflare --model glm-5.2 --neurons 83.6 --tokens 228 --task code-review
```

### View 7-day trend
```bash
python ~/bin/usage_monitor.py trend --days 7
```

### Check alert threshold
```bash
python ~/bin/usage_monitor.py alert --threshold 8000
```
Returns exit code 1 if CRITICAL (>=90% of ceiling).

### Reset today's log (CAUTION)
```bash
python ~/bin/usage_monitor.py reset
```

### Prune old entries
```bash
python ~/bin/usage_monitor.py cleanup --keep-days 30
```

## Auto-Logging

The `reasoning-router` skill automatically logs every successful inference call to the usage monitor. No manual logging needed when using the router.

## Data Storage

- Log file: `~/_state/usage/neuron_log.jsonl` (override with `HUMMBL_USAGE_LOG` env var)
- Format: append-only JSONL with timestamp, provider, model, neurons, tokens, task_type
- One entry per inference call

## Alert Levels

| Level | Trigger | Action |
|-------|---------|--------|
| OK | < 80% of ceiling | Continue normally |
| MODERATE | >= 50% of ceiling | Monitor closely |
| WARNING | >= 80% of ceiling | Conserve, route to cheaper models |
| CRITICAL | >= 90% of ceiling | Stop non-essential inference, exit 1 |

## Integration

- **reasoning-router**: Auto-logs every call
- **stream-inference**: Auto-logs Neuron consumption after each successful stream
- **freemodel-generate**: Can log manually after each generation
- **Cron/scheduled**: Run `usage_monitor.py alert --threshold 8000` daily to check budget

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| Usage high (WARNING) | `[reasoning-router]` with `--task quick-lookup` to use cheaper models |
| Usage CRITICAL | Switch to `[freemodel-generate]` with OpenRouter `:free` models |
| Need cost analysis | `[ai-cost-optimize]` for broader cost optimization |
| Export usage data | `python ~/bin/usage_monitor.py export --format json|csv` for reporting |

## Mandatory

None — monitoring is read-only; logging is append-only telemetry.

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction
- **T3 (Medium)**: May run without restriction
- **T4 (Probationary)**: May run
- **Operator**: Override any restriction
