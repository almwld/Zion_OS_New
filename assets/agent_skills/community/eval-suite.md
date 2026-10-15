---
name: eval-suite
description: Design and run LLM evaluation suites -- accuracy, latency, cost, format compliance across test cases.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action design|run|report] [--suite SUITE_ID] [--model MODEL]"
category: governance-compliance
status: candidate
---
# Eval Suite

Systematic LLM evaluation beyond single prompt tests. Design test suites with multiple cases, run them across models, track regressions.

## When to Use
- Before deploying a new prompt or agent to production
- Comparing models for a specific use case
- After model upgrade (did quality regress?)
- Building confidence in an LLM-powered feature

## Storage

Suites at `_state/prompt-lab/eval-suites.jsonl`:
```json
{"suite_id": "eval-briefing-v1", "name": "Briefing Quality", "created": "...", "cases": [{"input": "...", "expected_contains": ["weather", "calendar"], "expected_format": "markdown", "max_tokens": 2000}], "scoring": {"accuracy": 0.4, "format": 0.3, "conciseness": 0.3}}
```

## Execution

### design
1. Define what you're evaluating (task description)
2. Create 5-20 test cases with inputs and expected outputs/properties
3. Define scoring weights (accuracy, format, latency, cost, safety)
4. Save suite to eval-suites.jsonl

### run
1. Load suite by ID
2. For each test case: run prompt, measure latency, count tokens
3. Score each output against expected properties
4. Aggregate scores with weights
5. Save results

### report
1. Load results for a suite
2. Show per-case scores, aggregate score, regressions
3. Compare across models if multiple runs exist
4. Flag cases where quality dropped

## Output Format

```
Eval Suite | {suite_id} | {action}
==================================

## Suite: {name}
Cases: {N} | Scoring: accuracy={w1}, format={w2}, conciseness={w3}

## Results
| Case | Input (truncated) | Score | Accuracy | Format | Latency | Tokens |
|------|-------------------|-------|----------|--------|---------|--------|

## Aggregate
Overall: {weighted score}/5.0
Pass rate: {N}/{total} cases above threshold
Regressions: {list or "none"}

## Model Comparison (if multiple runs)
| Model | Avg Score | Avg Latency | Avg Cost | Recommendation |
|-------|-----------|-------------|----------|----------------|
```

## Skill Chains
- **Routing**: See `harness-routing.md` for SUT-type routing. This skill covers LLM text output eval only. For agent skills use `eval-forge`, for CLI tools use `cli-harness`.
| After this skill... | Consider... |
|--------------------|-------------|
| `[eval-suite] run` | `[model-compare]` (if testing multiple models) |
| `[eval-suite] report` | `[decision-log]` (record model selection) |
| Quality regression found | `[prompt-lab]` (iterate on the prompt) |
| Suite designed | `[hallucination-check]` (add factual accuracy cases) |
| execute eval cases across free-tier providers | `[reasoning-router]` (`python ~/bin/reasoning_router.py route`) |
