---
name: unit-economics
description: Calculate CAC, LTV, payback period, gross margins per product or service line
version: 0.1.0
execution-mode: advisory
argument-hint: "[--product NAME] [--period monthly|quarterly|annual]"
category: finance-legal
status: candidate
---
# Unit Economics

Calculate core unit economics metrics: Customer Acquisition Cost (CAC), Lifetime Value (LTV), LTV:CAC ratio, payback period, and gross margins. Breaks down by product or service line with configurable time periods.

## When to Use
- You need to evaluate the profitability of a product or service line
- You want to calculate LTV:CAC ratio for investor conversations
- You need to determine payback period for a pricing change
- You are comparing unit economics across different offerings

## Execution
1. Parse `$ARGUMENTS` for product name and reporting period
2. Collect input data: marketing spend, new customers, revenue per customer, churn rate, COGS
3. Calculate CAC = total acquisition spend / new customers acquired
4. Calculate LTV = (ARPU x gross margin) / churn rate
5. Calculate LTV:CAC ratio (healthy > 3:1)
6. Calculate payback period = CAC / (ARPU x gross margin) in months
7. Calculate gross margin = (revenue - COGS) / revenue
8. Compare against industry benchmarks if available
9. Flag any concerning metrics (LTV:CAC < 3, payback > 12 months)

## Output Format
```
Unit Economics | <product> (<period>)

## Core Metrics
| Metric | Value | Benchmark | Status |
|--------|-------|-----------|--------|
| CAC | $<N> | $<N> | OK/WARN |
| LTV | $<N> | $<N> | OK/WARN |
| LTV:CAC | <N>:1 | >3:1 | OK/WARN |
| Payback | <N> months | <12 months | OK/WARN |
| Gross Margin | <N>% | >70% | OK/WARN |
| ARPU | $<N>/mo | - | - |
| Churn | <N>%/mo | <5% | OK/WARN |

## Breakdown
- Revenue: $<N>/mo (<N> customers x $<ARPU>)
- COGS: $<N>/mo
- Gross Profit: $<N>/mo
- Acquisition Spend: $<N>/mo

## Assessment
<1-2 sentence summary of unit economics health>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Need pricing analysis | `[pricing-model]` to evaluate strategies |
| For investor materials | `[pitch]` or `[investor-update]` |
| For detailed forecast | `[scenario-plan]` with these inputs |
