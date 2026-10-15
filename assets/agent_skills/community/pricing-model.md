---
name: pricing-model
description: Model pricing strategies (cost-plus, value-based, competitive) with competitor benchmarks
version: 0.1.0
execution-mode: advisory
argument-hint: "[--strategy cost-plus|value|competitive|tiered] [--competitor NAME...]"
category: backend-infra
status: candidate
---
# Pricing Model

Model and compare pricing strategies for products or services. Supports cost-plus, value-based, competitive, and tiered pricing approaches with competitor benchmarking and margin analysis.

## When to Use
- You are setting or revising pricing for a product or service
- You need to compare your pricing against competitors
- You want to model the revenue impact of a price change
- You are designing a tiered pricing structure

## Execution
1. Parse `$ARGUMENTS` for strategy type and competitor names
2. Collect cost data: COGS, overhead, delivery cost per unit
3. Model the selected strategy:
   - Cost-plus: cost + target margin (20-50%)
   - Value-based: price anchored to customer value/ROI
   - Competitive: price relative to competitor benchmarks
   - Tiered: multiple tiers with feature gating
4. If competitors specified, research and benchmark their pricing
5. Calculate revenue projections at different price points
6. Compute price elasticity estimate (how volume changes with price)
7. Present comparison with recommendation

## Output Format
```
Pricing Model | <strategy>

## Cost Basis
| Component | Cost | % of Total |
|-----------|------|------------|
| COGS      | $<N> | <N>%       |
| Overhead  | $<N> | <N>%       |
| Delivery  | $<N> | <N>%       |
| **Total** | $<N> | 100%       |

## Price Points
| Strategy | Price | Margin | Revenue (100 units) |
|----------|-------|--------|---------------------|
| Cost-plus (30%) | $<N> | 30% | $<N> |
| Value-based | $<N> | <N>% | $<N> |
| Competitive avg | $<N> | <N>% | $<N> |

## Competitor Benchmarks
| Competitor | Price | Tier | Notes |
|------------|-------|------|-------|
| <name>     | $<N>  | <tier> | <notes> |

## Recommendation
<1-2 sentence pricing recommendation with rationale>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Competitor data needed | `[competitive-intel]` for market research |
| Pricing set for proposal | `[proposal-write]` to include pricing |
