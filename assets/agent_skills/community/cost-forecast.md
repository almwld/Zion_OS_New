---
name: cost-forecast
description: Predict next month API spend from usage trends — daily burn rate, projections, budget exhaustion
version: 1.0.0
execution-mode: advisory
argument-hint: "[--days 30] [--budget N]"
category: fleet-ops
status: candidate
---
# Cost Forecast

Project future API spend from historical usage data. Reads from costs.db (SQLite), cost JSONL files, or MCP cost-governor. Outputs burn rate, trend, projection, and budget exhaustion date.

## Arguments

- `$ARGUMENTS` parsed as: `[--days N] [--budget AMOUNT]`
- Default lookback: 30 days
- Default budget: read from cost governor config or use $200/month

## Context Gathering

Before executing this skill, gather the following context:
- **!`python3 -c "import sqlite3, os; p='state/costs.db'; print('costs.db**: Run `', 'EXISTS' if os.path.exists(p) else 'MISSING')" 2>/dev/null`
- Run `ls -la _state/costs/ 2>/dev/null || echo "No _state/costs/ directory"`

## Workflow

### 1. Collect Cost Data

Try sources in order of preference:

#### Option A: SQLite costs.db

```bash
python3 -c "
import sqlite3, json, os

db_paths = [
    'state/costs.db',
    'state/costs.db',
    '_state/costs/costs.db'
]

for p in db_paths:
    if os.path.exists(p):
        conn = sqlite3.connect(p)
        tables = conn.execute(\"SELECT name FROM sqlite_master WHERE type='table'\").fetchall()
        print(f'Database: {p}')
        for t in tables:
            cols = conn.execute(f'PRAGMA table_info({t[0]})').fetchall()
            count = conn.execute(f'SELECT COUNT(*) FROM {t[0]}').fetchone()[0]
            print(f'  Table: {t[0]} ({count} rows)')
            for c in cols:
                print(f'    {c[1]} ({c[2]})')
        conn.close()
        break
else:
    print('No costs.db found')
"
```

#### Option B: JSONL cost records

```bash
# Find and read cost JSONL files
find . -name "cost*.jsonl" -o -name "spend*.jsonl" | head -5
# Sample recent entries
tail -20 PATH_TO_COST_JSONL | python3 -c "
import sys, json
for line in sys.stdin:
    entry = json.loads(line.strip())
    print(json.dumps(entry, indent=2))
" | head -40
```

#### Option C: MCP Cost Governor

Use `mcp__cost-governor__cost_history` tool to retrieve recent cost data.

### 2. Calculate Daily Burn Rate

```bash
python3 -c "
import json, os, datetime
from collections import defaultdict

# Adjust based on actual data source from step 1
# This example reads JSONL; adapt query for SQLite
records = []

daily = defaultdict(float)
for r in records:
    day = r['timestamp'][:10]
    daily[day] += r.get('cost', r.get('amount', r.get('spend', 0)))

days = sorted(daily.keys())
if len(days) < 2:
    print('Insufficient data for forecast')
else:
    values = [daily[d] for d in days]
    avg = sum(values) / len(values)
    recent_7 = values[-7:] if len(values) >= 7 else values
    avg_7 = sum(recent_7) / len(recent_7)

    mid = len(values) // 2
    first_half = sum(values[:mid]) / max(mid, 1)
    second_half = sum(values[mid:]) / max(len(values) - mid, 1)
    trend_pct = ((second_half - first_half) / max(first_half, 0.01)) * 100

    print(f'Daily avg (all):  \${avg:.2f}')
    print(f'Daily avg (7d):   \${avg_7:.2f}')
    print(f'Trend:            {trend_pct:+.1f}%')
    print(f'30-day projection: \${avg_7 * 30:.2f}')
"
```

### 3. Trend Analysis

```bash
python3 -c "
# Sparkline from daily values
values = []  # populate from step 2
blocks = list('▁▂▃▄▅▆▇█')
if values:
    mn, mx = min(values), max(values)
    rng = mx - mn if mx != mn else 1
    sparkline = ''.join(blocks[min(7, int((v - mn) / rng * 7))] for v in values)
    print(f'Spend trend: {sparkline}')

    # 7-day moving average
    for i in range(6, len(values)):
        window = values[i-6:i+1]
        ma = sum(window) / 7
        print(f'  Day {i-5:2d}: \${values[i]:.2f}  (7d MA: \${ma:.2f})')
"
```

### 4. Budget Exhaustion

```bash
python3 -c "
import datetime

budget = 200.00  # from args or config
spent_so_far = 0.0  # from cost data
daily_burn = 0.0  # from step 2
remaining = budget - spent_so_far

if daily_burn > 0:
    days_left = remaining / daily_burn
    exhaust_date = datetime.date.today() + datetime.timedelta(days=days_left)
    print(f'Budget:     \${budget:.2f}')
    print(f'Spent:      \${spent_so_far:.2f} ({spent_so_far/budget*100:.1f}%)')
    print(f'Remaining:  \${remaining:.2f}')
    print(f'Burn rate:  \${daily_burn:.2f}/day')
    print(f'Days left:  {days_left:.0f}')
    print(f'Exhaustion: {exhaust_date.isoformat()}')
    if days_left < 7:
        print('*** CRITICAL: Budget exhaustion within 7 days')
    elif days_left < 14:
        print('** WARNING: Budget exhaustion within 14 days')
else:
    print('No recent spend detected')
"
```

## Output Format

```
Cost Forecast | YYYY-MM-DD

## Current Burn Rate
  Period          Daily Avg    Monthly Projection
  ────────────────────────────────────────────────
  All time        $4.82        $144.60
  Last 30 days    $5.21        $156.30
  Last 7 days     $6.47        $194.10
  Last 24 hours   $8.12        $243.60

  Spend trend (30d): ▁▁▂▂▃▃▄▃▃▅▄▅▅▆▅▅▆▆▇▆▇▇▆▇█▇██▇█

## Trend Analysis
  Direction:      INCREASING (+24.2% month-over-month)
  Acceleration:   7-day burn 1.24x above 30-day average
  Driver:         [e.g., "Swarm sessions 3x frequency since Mar 22"]

## Budget Status
  Monthly budget:    $200.00
  Spent this month:  $143.27 (71.6%)
  Days remaining:    8
  Projected total:   $194.10
  Status:            ON TRACK (within budget)

## Exhaustion Forecast
  At current rate:   Budget lasts through Apr 28
  At 7-day rate:     Budget lasts through Apr 22
  At peak rate:      Budget lasts through Apr 15

## Cost by Category (if available)
  Category        Spend     % of Total
  ────────────────────────────────────
  Claude API      $98.40    68.7%
  Swarm sessions  $31.20    21.8%
  Research        $8.50     5.9%
  Other           $5.17     3.6%

## Recommendation
[Based on trend — e.g., "Reduce swarm frequency from daily to 3x/week to
stay within budget" or "Current trajectory is sustainable, no action needed"]

No further action needed | Action: [specific adjustment if needed]
```

## Thresholds

| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Budget utilization | <70% | 70-90% | >90% |
| Days to exhaustion | >14 | 7-14 | <7 |
| Trend direction | Flat/decreasing | +10-25% | >+25% |
| Daily spike | <2x avg | 2-3x avg | >3x avg |

## Skill Chains

- If Red: `[cost-status]` (detailed governor state)
- If increasing trend: `[ai-cost-optimize]` (reduction strategies)
- After forecast: `[budget-plan]` (adjust allocations)
- For swarm costs: `[session-metrics]` (per-session breakdown)
- Weekly: include in `[weekly-digest]` summary
