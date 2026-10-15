---
name: scenario-plan
description: Model best/base/worst financial scenarios with configurable variables and sensitivity analysis
version: 0.1.0
execution-mode: advisory
argument-hint: "[--variables VAR=VAL...] [--months N]"
category: finance-legal
status: candidate
---
# Scenario Plan

Model three financial scenarios (best, base, worst) with configurable input variables. Includes sensitivity analysis showing which variables have the largest impact on outcomes.

## When to Use
- You need to forecast revenue, costs, or runway under different assumptions
- You want to understand which variables most affect your financial outcomes
- You are preparing for an investor meeting and need scenario ranges
- You need to stress-test a business model against adverse conditions

## Execution
1. Parse `$ARGUMENTS` for variable assignments and forecast horizon (default 12 months)
2. Define input variables with base values (revenue growth, churn, ARPU, costs, headcount)
3. Create three scenarios by adjusting variables:
   - Best: +20% on growth vars, -20% on cost vars
   - Base: provided values as-is
   - Worst: -30% on growth vars, +30% on cost vars
4. Run monthly projections for each scenario
5. Compute key outcomes: revenue, costs, cash position, runway
6. Run sensitivity analysis: vary each input +/-10% independently and measure outcome change
7. Identify the top 3 most sensitive variables

## Output Format
```
Scenario Plan | <months>-month forecast

## Input Variables
| Variable | Best | Base | Worst |
|----------|------|------|-------|
| Monthly revenue growth | 15% | 10% | 5% |
| Monthly churn | 2% | 5% | 8% |
| Monthly burn | $8K | $12K | $18K |

## Projections (Month <N>)
| Metric | Best | Base | Worst |
|--------|------|------|-------|
| Monthly revenue | $X | $X | $X |
| Monthly costs | $X | $X | $X |
| Cash position | $X | $X | $X |
| Runway (months) | N | N | N |

## Sensitivity Analysis
| Variable | +10% Impact | -10% Impact | Sensitivity |
|----------|-------------|-------------|-------------|
| <var>    | +$X revenue | -$X revenue | HIGH |

## Key Insight
<most important finding>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Scenarios ready for investors | `[investor-update]` to draft the update |
| Scenarios support a pitch | `[pitch]` to build the narrative |
| Need runway detail | `[runway]` for detailed cash analysis |
