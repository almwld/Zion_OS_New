---
name: velocity-tune
description: Measure and iteratively improve development velocity -- find bottlenecks, remove friction. Maps to RE13.
version: 0.1.0
execution-mode: advisory
argument-hint: "[measure | bottleneck | compare PERIOD1 PERIOD2]"
category: data-science
status: candidate
---
# Velocity Tune (RE13: Gradient Descent Heuristic)

Iteratively adjust toward faster, smoother development by measuring, finding the bottleneck, and making one targeted improvement.

## Execution

### 1. Measure current velocity
```bash
echo "=== Commits per day (last 14 days) ==="
git log --oneline --since="14 days ago" | wc -l | awk '{print $1/14, "commits/day"}'

echo "=== Lines changed per day ==="
git log --since="14 days ago" --shortstat | grep "changed" | awk '{s+=$4+$6} END {print s/14, "lines/day"}'

echo "=== PRs merged (last 14 days) ==="
gh pr list --state merged --limit 50 --json mergedAt --jq '[.[] | select(.mergedAt > (now - 14*86400 | todate))] | length' 2>/dev/null || echo "(gh unavailable)"

echo "=== Test count growth ==="
echo "Current: $(source .venv/bin/activate && python -m pytest tests/ --co -q 2>&1 | tail -1)"

echo "=== Bus activity ==="
tail -2000 _state/coordination/messages.tsv | grep "$(date -v-14d +%Y-%m)" | wc -l | awk '{print $1/14, "bus msgs/day"}'
```

### 2. Find the bottleneck
What's the ONE thing slowing you down most?

| Category | Symptom | Bottleneck |
|----------|---------|-----------|
| **Waiting** | CI takes 45 min | Test suite too large |
| **Context switching** | Multiple PRs in flight | Too many parallel branches |
| **Rework** | Same bug class recurring | Missing test coverage for category |
| **Ceremony** | Long review cycles | No automated review skill |
| **Environment** | "Works on my machine" | Missing env parity |
| **Knowledge** | "How does X work again?" | Stale documentation |

### 3. Make ONE targeted improvement
Don't fix everything. Fix the bottleneck. Measure again next sprint.

The gradient descent heuristic: you don't need to know the global optimum. Just move in the direction that reduces the most friction RIGHT NOW.

### 4. Compare periods
```bash
echo "=== Period 1: 2 weeks ago ==="
git log --oneline --since="28 days ago" --until="14 days ago" | wc -l

echo "=== Period 2: last 2 weeks ==="
git log --oneline --since="14 days ago" | wc -l
```

## Output Format
```
Velocity Report | <period>
═══════════════════════════

## Metrics
- Commits/day: <N>
- Lines/day: <N>
- PRs merged: <N>
- Test growth: <N>
- Bus activity: <N> msgs/day

## Bottleneck
<the ONE thing slowing us down most>

## Recommended Fix
<specific, measurable action>

## Comparison (if available)
| Metric | Previous | Current | Delta |
```

## Base120 Context
- Primary: **RE13** (Gradient Descent Heuristic)
- Related: **RE1** (Kaizen), **DE7** (Pareto 80/20), **DE12** (Constraint Isolation)
