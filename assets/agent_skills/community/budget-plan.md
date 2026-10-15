---
name: budget-plan
description: Monthly/quarterly budget allocation with variance tracking against actuals
version: 0.1.0
execution-mode: advisory
argument-hint: "[--period monthly|quarterly] [--action plan|review|variance]"
category: finance-legal
status: candidate
---
# Budget Plan

Create, review, and track budget allocations with variance analysis against actuals. Supports monthly and quarterly periods with category breakdowns and trend tracking.

## When to Use
- You need to create a budget for the upcoming month or quarter
- You want to review actual spend against budgeted amounts
- You need variance analysis to identify over/under-spending
- You are preparing financial reports for stakeholders

## Execution
1. Parse `$ARGUMENTS` for period (monthly/quarterly) and action (plan/review/variance)
2. If `plan`: create budget template with categories (personnel, infrastructure, tools, marketing, misc)
3. If `review`: compare budgeted vs actual spend per category
4. If `variance`: compute variance (actual - budget), variance %, and flag significant deviations (>10%)
5. Pull historical data from expense logs if available
6. Compute totals, category percentages, and month-over-month trends
7. Flag budget items that need attention (>10% over, or consistently under-utilized)

## Output Format
```
Budget Plan | <action> (<period>)

## Budget vs Actual
| Category | Budget | Actual | Variance | Var % | Status |
|----------|--------|--------|----------|-------|--------|
| Personnel | $<N> | $<N> | +$<N> | +<N>% | OVER |
| Infrastructure | $<N> | $<N> | -$<N> | -<N>% | UNDER |
| Tools/SaaS | $<N> | $<N> | $0 | 0% | ON TRACK |
| Marketing | $<N> | $<N> | +$<N> | +<N>% | WARN |
| Misc | $<N> | $<N> | -$<N> | -<N>% | OK |
| **Total** | **$<N>** | **$<N>** | **+$<N>** | **+<N>%** | |

## Trends
- <month-over-month trend observations>

## Actions Needed
- [OVER] <category>: <recommendation>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Need expense detail | `[expense-log]` to review line items |
| Need runway impact | `[runway]` to see cash position |
| factor Cloudflare Neuron consumption into budget planning | `[usage-monitor]` (`python ~/bin/usage_monitor.py status`) |
