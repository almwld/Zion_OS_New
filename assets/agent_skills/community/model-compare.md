---
provider-specific: true
name: model-compare
description: Side-by-side model comparison on identical inputs with structured scoring.
version: 0.1.0
execution-mode: advisory
argument-hint: "<model_a> <model_b> [--task DESCRIPTION] [--input FILE_OR_TEXT]"
category: backend-infra
status: candidate
---
# Model Compare

Compare two or more models head-to-head on the same task. Useful for model selection, upgrade validation, and cost optimization.

## When to Use
- Choosing between models for a feature (Opus vs Sonnet, GPT-5 vs Claude)
- Validating a model upgrade doesn't regress quality
- Finding the cheapest model that meets quality bar
- When user says "which model should I use" or "compare models"

## Execution

1. **Define the task**: What are we comparing? (summarization, code gen, analysis, etc.)
2. **Prepare inputs**: 3-5 representative inputs for the task
3. **Run each model** on each input (or use cached results from `[eval-suite]`)
4. **Score outputs** on: accuracy, completeness, format, latency, cost
5. **Recommend** the best model for this task with rationale

## Comparison Dimensions

| Dimension | How to Measure |
|-----------|---------------|
| Quality | Human scoring 1-5 on accuracy, completeness |
| Format | Does output match expected structure? |
| Latency | Time to first token, time to completion |
| Cost | Input + output tokens * price per MTok |
| Safety | Any refusals, hallucinations, policy violations? |
| Context | Max context window, how it handles long inputs |

## Output Format

```
Model Compare | {model_a} vs {model_b} | {task}
================================================

## Task: {description}
Inputs: {N} test cases

## Head-to-Head Results
| Input | {model_a} Score | {model_b} Score | Winner | Notes |
|-------|----------------|----------------|--------|-------|

## Aggregate
| Metric | {model_a} | {model_b} |
|--------|-----------|-----------|
| Avg Quality | ... | ... |
| Avg Latency | ... | ... |
| Avg Cost/call | ... | ... |
| Context Window | ... | ... |

## Recommendation
**Winner: {model}**
Reason: {rationale}
Caveat: {when the other model might be better}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Model selected | `[decision-log]` (record the choice) |
| Cost difference significant | `[cost-status]` (update budget projections) |
| Quality close | `[eval-suite]` (run more test cases to break tie) |
| Cheaper model wins | `[token-estimate]` (verify savings at scale) |
| Streaming latency comparison | `[stream-inference]` to measure TTFT and tokens/sec per model (`python ~/bin/stream_test.py <model> --prompt "test"`) |
