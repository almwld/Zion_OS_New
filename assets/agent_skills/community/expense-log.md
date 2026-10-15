---
name: expense-log
description: Track business expenses for tax and runway analysis
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<add|summary|categories> [amount] [category] [vendor] [notes]"
category: fleet-ops
status: candidate
---
# [expense-log]

## When to Use
- Recording a business expense (subscription, hardware, service, travel)
- Reviewing monthly/quarterly spend by category
- Preparing expense data for tax filing
- Checking runway impact of recurring costs

## Execution

### Storage
- Log file: `_state/expenses/log.tsv`
- Format: `date\tamount\tcurrency\tcategory\tvendor\trecurring\tnotes`
- Create directory and header row if they don't exist

### Categories (standard)
`saas`, `infrastructure`, `hardware`, `domain`, `legal`, `education`, `travel`, `contractor`, `marketing`, `misc`

### Commands

**add [amount] [category] [vendor] [notes]**
### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=expense-log] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. Validate amount is numeric, category is known (or flag as new)
2. Default date to today, currency to USD
3. Ask if recurring (monthly/annual/one-time) -- default one-time
4. Append to `_state/expenses/log.tsv`
5. Confirm entry logged

**summary [period]**
1. Read `_state/expenses/log.tsv`
2. Filter by period: `month`, `quarter`, `year`, `YYYY-MM`, or `all`
3. Group by category with subtotals
4. Flag recurring expenses separately with annualized cost
5. Show total

**categories**
1. List all categories with count and total spend
2. Flag any uncategorized entries

## Output Format

```
Expense Log | summary month
============================================================
Period: March 2026

| Category       | Count | Total    | % of Spend |
|----------------|-------|----------|------------|
| saas           | 4     | $487.00  | 62%        |
| infrastructure | 2     | $180.00  | 23%        |
| education      | 1     | $49.00   | 6%         |
| domain         | 2     | $35.00   | 4%         |
| misc           | 1     | $30.00   | 4%         |
| **Total**      | **10**| **$781.00** |         |

Recurring monthly: $617.00 ($7,404/yr annualized)
------------------------------------------------------------
Next: [runway] (check impact on runway)
```

## Skill Chains

### Mandatory

- None — expense-log is a ledger append. The `add` command validates inputs before appending.

### Advisory

- After `[expense-log] summary` -> suggest `[runway]` for burn rate
- After `[expense-log] add` with large amount -> suggest `[revenue-forecast]`
- Pair with `[time-track] summary` for complete financial picture

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (ledger append is low-risk)
- **T3 (Medium)**: May run `summary`/`categories` freely; `add` requires operator notification
- **T4 (Probationary)**: May run `summary`/`categories` only; `add` BLOCKED
- **Operator**: Override any restriction
