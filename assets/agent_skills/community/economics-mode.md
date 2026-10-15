---
name: economics-mode
description: Governed financial decision support — every allocation has thesis, downside, and exit.
version: 0.1.0
execution-mode: advisory
status: approved
category: finance-legal
protected_variable: capital_preservation
composition:
  - crisis-mode
  - deep-research-mode
conflicts: []
---

# Economics-Mode Skill

## Invocation

```
/economics-mode
```

Or implicit when any decision involves money, capital, or resource allocation.

## What This Skill Does

Activates economics-mode for the current session. All financial recommendations
must include thesis, downside, exit, position size, and opportunity cost.

## Inputs

- **Decision context**: What financial decision is being considered?
- **Capital available**: How much capital is available for allocation?
- **Risk tolerance**: Operator's stated risk tolerance (conservative / moderate / aggressive)
- **Time horizon**: Short-term (< 1 year) / medium-term (1-5 years) / long-term (> 5 years)

## Output

```markdown
# Economics-Mode Analysis

**Decision**: <what is being considered>
**Capital at risk**: <$amount or % of total>
**Risk tolerance**: conservative / moderate / aggressive
**Time horizon**: short / medium / long

## Options

### Option A: <name>
- **Thesis**: <why this allocation makes sense>
- **Expected return**: <what we expect to gain>
- **Downside**: <max loss if thesis is wrong>
- **Exit**: <when to close/stop/reverse>
- **Position size**: <% of capital recommended (Kelly-sized)>
- **Opportunity cost**: <what we can't do instead>
- **Reversibility**: reversible / irreversible
- **Risk budget consumed**: <% of risk budget>

### Option B: <name>
...

## Recommendation

<which option and why, with confidence level>

## Receipt

<economics-mode receipt per doctrine template>
```

## Composition

- **economics-mode + crisis-mode**: Financial crisis response. Crisis-mode stabilizes; economics-mode evaluates financial impact.
- **economics-mode + deep-research-mode**: Research investment opportunities before allocating.

## Cost

~10K-20K tokens per analysis (depends on number of options and complexity).
