---
name: mental-model
description: Catalog and apply mental models (Occam's razor, second-order thinking, inversion, etc.) to problems
version: 0.1.0
execution-mode: advisory
argument-hint: "<problem> [--model occam|inversion|second-order|hanlon|map-territory|mcnamara]"
category: fleet-ops
status: candidate
---
# mental-model | Mental Model Application to Problems

## When to Use
- Breaking down a complex problem with a structured thinking framework
- Avoiding common reasoning errors by applying established mental models
- Generating alternative perspectives before committing to a solution
- Building a reusable catalog of mental models for a team or project

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: problem statement (text, file path, or issue description)
- `--model occam|inversion|second-order|hanlon|map-territory`: specific model to apply
- If no model specified, select and apply the top 3 relevant models

### 2. Catalog Available Models
- **Occam's Razor**: prefer the explanation with fewest assumptions
- **Inversion**: ask how to fail, then avoid that path
- **Second-Order Thinking**: consider consequences of consequences
- **Hanlon's Razor**: never attribute to malice what stupidity explains
- **Map-Territory**: the model is not reality; check where it diverges
- **McNamara Fallacy**: measured is not everything; what isn't measured still exists
- **Circle of Competence**: know what you know and what you don't
- **Margin of Safety**: build buffers for the unexpected
- **Opportunity Cost**: every choice excludes alternatives

### 3. Apply Selected Model(s)
- **Occam's**: list explanations, count assumptions, prefer simplest fitting evidence
- **Inversion**: define goal, invert to "how to guarantee failure," avoid each path
- **Second-Order**: trace consequences 2-3 levels deep; flag where 2nd negates 1st
- **Hanlon's**: for each malice attribution, generate incompetence alternative; prefer fewer-assumption explanation
- **Map-Territory**: identify model used, list where it diverges from reality, gather ground-truth where divergence is high
- **McNamara's**: for each metric in the decision, list what matters that isn't measured; flag where unmeasurable factors were assigned arbitrary values or presumed irrelevant

### 4. Synthesize Insights
- Combine outputs from all applied models
- Identify convergent recommendations (multiple models agree)
- Flag conflicting recommendations (models suggest different actions)
- Produce a ranked list of actionable insights

### 5. Record to Catalog
- Add to `_state/mental_models/applied.jsonl`: problem, models, insights, date

## Output Format

```
mental-model | <problem-summary>

## Problem
<one-line problem statement>

## Models Applied: occam, inversion, second-order

### Occam's Razor
1. Config typo (1 assumption) -- PREFERRED
2. Race condition in deploy (3 assumptions)
3. Malicious interference (5 assumptions)

### Inversion
- How to guarantee failure: skip config check, no rollback, no staging test
- Avoidance: [x] Verify config | [ ] Add rollback | [ ] Test in staging

### Second-Order Thinking
- Action: hotfix config in production
  1st: problem solved | 2nd: post-mortem skipped, root cause persists | 3rd: recurs

## Convergent Insights
1. Check config first (occam + inversion agree)
2. Schedule post-mortem regardless of outcome (second-order)

## Catalog
- Recorded to _state/mental_models/applied.jsonl | ID: mm_0042

## Verdict
INSIGHTS_GENERATED / CONFLICT_UNRESOLVED / INSUFFICIENT_CONTEXT
```

## Skill Chains
- After model application -> `[first-principles]` to derive fundamental truths
- After model application -> `[reframe]` to restructure the problem space
- Before finalizing a decision -> `[decision-log]` to record the reasoning
