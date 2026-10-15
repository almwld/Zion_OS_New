---
name: dimension-reduce
description: Simplify complex data by finding the few variables that matter most. Maps to DE5.
version: 0.1.0
execution-mode: advisory
argument-hint: <complex dataset or decision with many variables>
category: dev-tools
status: candidate
---
# Dimension Reduce (DE5: Dimensional Reduction)

When facing too many variables, find the 2-3 that explain 80% of the outcome. Discard the noise.

## When to Use
- Sprint planning with 30 possible tasks (which 3 matter?)
- Debugging with 10 possible causes (which 2 are likely?)
- Performance analysis with many metrics (which ones actually predict user value?)
- Agent evaluation with many signals (which few predict trust?)

## Execution

### 1. List all dimensions
Enumerate every variable, factor, or consideration:

```
Task priority factors: urgency, impact, effort, risk, dependencies,
  stakeholder pressure, technical debt, learning value, team morale,
  strategic alignment, customer demand, revenue impact...
```

### 2. Identify the vital few
Apply the Pareto filter (DE7): which 2-3 variables explain most of the variance?

**Technique: Pairwise elimination**
Compare every pair of variables. For each pair, ask: "If I could only know ONE of these, which tells me more about the outcome?"

Winner advances. Losers are noise.

### 3. Validate the reduction
- Does the reduced model still predict the same decisions as the full model?
- Are there edge cases where a dropped dimension would flip the decision?
- What's the cost of being wrong about the dropped dimensions?

### 4. Create the simplified model

```
Full model: f(urgency, impact, effort, risk, deps, pressure, debt, learning, morale, alignment, demand, revenue)
Reduced model: f(impact, effort, urgency)
Explanation: Impact x Urgency / Effort predicts 85% of our actual prioritization decisions.
```

## Practical Applications

| Domain | Full Dimensions | Reduced To |
|--------|----------------|-----------|
| **Agent trust** | Bus volume, error rate, scope violations, revert count, review pass rate, tenure | **Error rate + scope violations** |
| **Feature priority** | RICE (4 dims) | **Impact / Effort** (2 dims) |
| **Health status** | 12 probes | **Adapter status + bus freshness** (predict overall) |
| **Sprint velocity** | Commits, LOC, PRs, tests, bus msgs | **Commits/day** (strongest correlate) |

## Output Format
```
Dimension Reduce | <domain>
═══════════════════════════

## All Dimensions (N)
<full list>

## Vital Few (2-3)
<the dimensions that matter>

## Dropped (with reasoning)
<what was removed and why it's safe to ignore>

## Simplified Model
<the reduced decision rule>

## Validation
<does the reduced model match historical decisions?>

## Risk
<when the simplification would fail>
```

## Base120 Context
- Primary: **DE5** (Dimensional Reduction)
- Related: **DE7** (Pareto 80/20), **DE9** (Signal Separation), **IN1** (Subtractive Thinking)
