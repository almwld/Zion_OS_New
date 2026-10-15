---
provider-specific: true
name: prompt-lab
description: Version, test, and compare prompts across models -- A/B testing for prompt engineering.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action create|test|compare|history] [--model claude|gpt|gemini|ollama] [--prompt-id ID]"
category: backend-infra
status: candidate
---
# Prompt Lab

Version-controlled prompt engineering workbench. Create, test, compare, and iterate on prompts with structured evaluation.

## When to Use
- Designing a new prompt for an agent, skill, or application
- Comparing prompt variants for quality/cost/latency tradeoffs
- Before deploying a prompt to production (system prompt, agent instruction)
- When user says "test this prompt" or "which prompt is better"

## Storage

Prompts are stored as JSONL at `_state/prompt-lab/prompts.jsonl`:
```json
{"id": "prompt-001", "name": "briefing-summary", "version": 3, "created": "2026-03-29T12:00:00Z", "model": "claude-opus-4-6", "system": "...", "user_template": "...", "variables": ["date", "adapters"], "tags": ["briefing", "production"], "notes": "Added structured output format"}
```

Test results at `_state/prompt-lab/results.jsonl`:
```json
{"prompt_id": "prompt-001", "version": 3, "timestamp": "...", "model": "claude-opus-4-6", "input_tokens": 450, "output_tokens": 1200, "latency_ms": 3400, "score": 4.2, "notes": "Good structure, missed one adapter"}
```

## Execution

### create
1. Accept prompt text (system + user template)
2. Extract variables (anything in `{{variable}}` syntax)
3. Assign ID and version 1
4. Save to prompts.jsonl
5. Output: prompt card with ID, variables, metadata

### test
1. Load prompt by ID
2. Fill variables from user input or defaults
3. Estimate token count and cost
4. If `--model` specified, note model for the test record
5. Run the prompt (or dry-run showing the filled template)
6. Score the output (1-5 scale: accuracy, completeness, format, conciseness)
7. Save result to results.jsonl

### compare
1. Load two prompt versions (by ID or version number)
2. Show diff between them
3. Show test results side-by-side
4. Recommend which to keep based on scores

### history
1. Load all versions of a prompt by ID
2. Show version timeline with scores and notes
3. Highlight best-performing version

## Output Format

```
Prompt Lab | {action} | {prompt_id}
===================================

## Prompt Card
ID: {id}
Name: {name}
Version: {version}
Model: {target model}
Variables: {list}
System prompt: {first 100 chars}...
User template: {first 100 chars}...

## Test Results (if action=test)
| Run | Model | Tokens (in/out) | Latency | Score | Notes |
|-----|-------|-----------------|---------|-------|-------|

## Comparison (if action=compare)
| Metric | Version A | Version B | Winner |
|--------|-----------|-----------|--------|

## Recommendation
{Which version to use and why}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| `[prompt-lab] test` | `[eval-suite]` (systematic evaluation) |
| `[prompt-lab] compare` | `[decision-log]` (record the choice) |
| Prompt for agent | `[system-prompt]` (if it's an agent system prompt) |
| Prompt optimized | `[token-estimate]` (verify cost) |
| A/B test prompts across models | `[reasoning-router]` (`python ~/bin/reasoning_router.py route`) |
