---
name: cost-status
description: Query costs.db for budget, spend, and governor decisions.
version: 0.1.0
execution-mode: advisory
argument-hint: "[current | forecast | history]"
category: fleet-ops
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **DB status**: Run `test -f ~/state/costs.db && echo "DB exists ($(du -h ~/state/costs.db | cut -f1))" || echo "NO DB"`

# Cost Status Command

Query the cost tracking database for budget utilization and cost governor decisions.

## Usage

```bash
[cost-status]          # Full cost summary
```

## Execution

### 1. Check database exists
```bash
test -f state/costs.db
```
If not found, report that cost tracking is not initialized.

### 2. Query recent costs
```bash
sqlite3 state/costs.db "SELECT * FROM costs ORDER BY timestamp DESC LIMIT 20;"
```

### 3. Query daily totals
```bash
sqlite3 state/costs.db "SELECT date(timestamp) as day, SUM(amount) as total FROM costs GROUP BY day ORDER BY day DESC LIMIT 7;"
```

### 4. Query governor decisions
```bash
sqlite3 state/costs.db "SELECT * FROM governor_decisions ORDER BY timestamp DESC LIMIT 10;"
```

### 5. Check budget config
Read `state/budget.json` or equivalent config for budget limits.

## Output Format

```
Cost Status | <YYYY-MM-DD HH:MMZ>
══════════════════════════════════

## Budget
Daily limit: $X.XX
Monthly limit: $XX.XX
Current daily spend: $X.XX (XX%)
Current monthly spend: $XX.XX (XX%)

## Last 7 Days
| Date | Spend | Status |
|------|-------|--------|
| 2026-02-24 | $1.23 | OK |
| ... | ... | ... |

## Governor Decisions (Last 10)
| Time | Decision | Reason |
|------|----------|--------|
| ... | ALLOW/DENY/THROTTLE | ... |
```

## Constraints

- READ-ONLY. Do not modify costs.db or budget config.
- If tables don't exist, report the schema issue.
- Do not fabricate cost data -- always query the actual database.
- Round dollar amounts to 2 decimal places.
