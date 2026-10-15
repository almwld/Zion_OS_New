---
name: growth-model
description: Analyze network effects, growth loops, and go-to-market dynamics. Maps to CO7.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"PRODUCT or FEATURE to model growth for\""
category: fleet-ops
status: candidate
---
# Growth Model (CO7: Network Effects)

Analyze how value increases with adoption and design growth loops.

## When to Use
- GaaS go-to-market strategy
- Base120 API adoption planning
- Open-source community growth
- Agent ecosystem expansion
- Any product where more users = more value per user

## Execution

### 1. Identify the network
What gets more valuable as it grows?

| Network Type | Example | Value Driver |
|--------------|---------|-------------|
| **Direct** | More agents on bus = richer coordination | Each agent adds signal |
| **Indirect** | More skills in registry = more useful platform | Skill creators attract skill users |
| **Data** | More ledger entries = better boot context | Knowledge compounds |
| **Marketplace** | More GaaS customers = more shared learnings | Cross-pollination |

### 2. Map the growth loop
Every sustainable growth has a loop:

```
Action -> Value Created -> Attracted Users -> More Action
```

Example for GaaS:
```
Customer deploys agents -> Governance data generated ->
  Base120 models refined -> Better recommendations ->
    More customers attracted -> More governance data
```

### 3. Identify cold start problems
- Who provides value before there's a network? (seed users)
- What's the minimum viable network size?
- How do you get the first 10 customers? First 100?

### 4. Find the growth bottleneck
- **Supply-side**: Not enough skill creators / integrations?
- **Demand-side**: Not enough users / customers?
- **Chicken-and-egg**: Both sides waiting for the other?
- **Onboarding friction**: Users sign up but don't activate?

### 5. Design growth accelerators
| Accelerator | Mechanism |
|-------------|-----------|
| **Content loop** | Research docs attract developers who become users |
| **Tool loop** | Free Base120 API attracts builders who become GaaS customers |
| **Integration loop** | MCP servers expand capability, attracting more agents |
| **Community loop** | Open-source contributors become advocates |

## Output Format
```
Growth Model | <product>
═══════════════════════════

## Network Type
<direct/indirect/data/marketplace>

## Growth Loop
<diagram: action -> value -> attraction -> action>

## Cold Start Strategy
<how to seed the initial network>

## Current Bottleneck
<supply/demand/chicken-egg/onboarding>

## Accelerators (prioritized)
1. <highest leverage growth action>
2. <second>
3. <third>

## Metrics to Track
- <leading indicator>
- <lagging indicator>
- <network health metric>
```

## Base120 Context
- Primary: **CO7** (Network Effects)
- Related: **RE10** (Compounding Cycles), **SY16** (Ecosystem Strategy), **CO14** (Platformization)
