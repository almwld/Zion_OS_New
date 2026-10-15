---
name: session-metrics
description: Track token usage, tool calls, agent dispatches, and rate limit hits per session
version: 1.0.0
execution-mode: advisory
argument-hint: "[--since HH:MM] [--cost]"
category: fleet-ops
status: candidate
---
# Session Metrics

Capture per-session operational metrics for cost tracking and swarm budget optimization.

## Arguments
- `--since <HH:MM>` — Session start time (default: infer from first commit today)
- `--cost` — Include cost estimates per activity category
- No args — Show all metrics for the current day

## Procedure

### 1. Determine Session Window

```bash
# Find earliest activity today
FIRST_COMMIT=$(git log --since="midnight" --format="%ai" --reverse | head -1)
echo "Session start: ${FIRST_COMMIT:-$(date -u +%Y-%m-%dT00:00:00Z)}"
```

If `--since` is provided, use that as the start time instead.

### 2. Git Activity

```bash
# Commits this session
git log --since="<session_start>" --oneline | wc -l
git log --since="<session_start>" --format="%h %s" --reverse

# Lines changed
git log --since="<session_start>" --shortstat | grep -E "files? changed" | awk '{ins+=$4; del+=$6} END {print ins " insertions, " del " deletions"}'

# Branches touched
git log --since="<session_start>" --format="%D" | grep -v "^$" | sort -u
```

### 3. Bus Activity

```bash
# Messages today
BUS="$PROJECT_ROOT/_state/coordination/messages.tsv"
TODAY=$(date -u +%Y-%m-%d)
grep "^${TODAY}" "$BUS" | wc -l

# By agent
grep "^${TODAY}" "$BUS" | awk -F'\t' '{print $2}' | sort | uniq -c | sort -rn

# By type
grep "^${TODAY}" "$BUS" | awk -F'\t' '{print $4}' | sort | uniq -c | sort -rn
```

### 4. Agent Dispatches

```bash
# Dispatches from bus
grep "^${TODAY}" "$BUS" | grep -i "dispatch\|spawn\|delegate" | wc -l

# Active worktrees (proxy for concurrent agents)
git worktree list | wc -l
```

### 5. Governance Log Activity

```bash
# IDP events today
GOV="_state/governance/governance_bus.jsonl"
if [ -f "$GOV" ]; then
  grep "${TODAY}" "$GOV" | wc -l
fi
```

### 6. Cost Estimation (if `--cost`)

Estimate based on activity volume:
- Per commit: ~50 tool calls avg, ~$0.01 haiku / $0.06 sonnet / $0.30 opus
- Per bus scan: ~5 tool calls, ~$0.001
- Per dispatch: ~100 tool calls per agent lane

Use the model from `CLAUDE.md` or conversation context to pick the rate.

## Output Format

```
Session Metrics | <date> | <session_start> - now (<duration>)

Git Activity:
  Commits:        <N>
  Files changed:  <N>
  Insertions:     <N>
  Deletions:      <N>
  Net LOC:        <+/- N>
  Branches:       <list>

Bus Activity:
  Messages today: <N>
  By agent:       <agent>: <N>, <agent>: <N>
  By type:        STATUS: <N>, ACK: <N>, ...

Agent Dispatches:
  Dispatched:     <N>
  Active worktrees: <N>

Governance Events: <N>

Cost Estimate:
  Model:          <haiku|sonnet|opus>
  Est. API calls: <N>
  Est. tokens:    ~<N>K input, ~<N>K output
  Est. cost:      $<X.XX>
  Daily burn:     $<X.XX>/day (annualized: $<X.XX>/yr)

Session Efficiency:
  LOC per dollar: <N>
  Commits/hour:   <N>
  Bus msgs/hour:  <N>

Next action: <suggestion based on metrics>
```

## Notes

- Token estimates are approximate -- actual usage requires API dashboard
- Cost rates: Haiku 3.5 ($0.80/$4.00 per 1M tok), Sonnet 4 ($3/$15), Opus 4 ($15/$75)
- For precise billing, check: https://console.anthropic.com/settings/usage
- Session duration is wall-clock, not active time

## Skill Chains
- For track cross-runtime delegations -> `[cross-runtime-bridge]` (`python ~/bin/cross_runtime_bridge.py sessions`)
- For track Cloudflare Neuron consumption as part of session token usage -> `[usage-monitor]` (`python ~/bin/usage_monitor.py status`)

### Mandatory

- None — session-metrics is `advisory` mode (read-only metrics collection).

### Advisory

| After completing... | Consider... |
|---|---|
| High burn rate | `[cost-status]`, `[ai-cost-optimize]` |
| Many dispatches | `[swarm-collect]` (gather results) |
| Low LOC/dollar | Review task complexity, consider model downgrade |
| End of day | `[end-session]` (include metrics in closeout) |

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (read-only metrics)
- **T3 (Medium)**: May run without restriction (read-only metrics)
- **T4 (Probationary)**: May run (read-only — no side effects)
- **Operator**: Override any restriction
