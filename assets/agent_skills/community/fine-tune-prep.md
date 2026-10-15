---
name: fine-tune-prep
description: Prepare training data for LLM fine-tuning -- format validation, dedup, cost estimation, quality checks.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action validate|convert|estimate|split] [--format openai|anthropic|alpaca] [--file PATH]"
category: backend-infra
status: candidate
---
# Fine-Tune Prep

Prepare and validate training data for LLM fine-tuning. Handles format conversion, deduplication, quality scoring, and cost estimation.

## When to Use
- Preparing data for fine-tuning (OpenAI, Anthropic, or local models)
- Converting between training data formats
- Validating training data quality before a fine-tune run
- Estimating fine-tuning cost

## Supported Formats

| Format | Structure | Used By |
|--------|----------|---------|
| OpenAI | `{"messages": [{"role": "system", ...}, {"role": "user", ...}, {"role": "assistant", ...}]}` | OpenAI fine-tuning API |
| Anthropic | `{"prompt": "\n\nHuman: ...\n\nAssistant:", "completion": "..."}` | Anthropic (legacy) |
| Alpaca | `{"instruction": "...", "input": "...", "output": "..."}` | Local model fine-tuning |
| ShareGPT | `{"conversations": [{"from": "human", ...}, {"from": "gpt", ...}]}` | Community models |

## Execution

### validate
1. Read JSONL file
2. Check format compliance (required fields, types)
3. Check for duplicates (exact and near-duplicate)
4. Flag quality issues: empty fields, very short/long examples, encoding errors
5. Report: valid/invalid/warning counts

### convert
1. Read source format
2. Convert to target format
3. Validate output
4. Write converted file

### estimate
1. Count examples and tokens
2. Calculate cost by provider
3. Estimate training time
4. Recommend batch size

### split
1. Split data into train/validation sets (default 90/10)
2. Stratify by category if labels present
3. Write separate files

## Output Format

```
Fine-Tune Prep | {action}
=========================

## Dataset
File: {path}
Format: {detected format}
Examples: {N}
Total tokens: {N}

## Validation (if action=validate)
| Check | Status | Count | Details |
|-------|--------|-------|---------|
| Format compliance | PASS/FAIL | {N} errors | ... |
| Duplicates | {N} found | ... | ... |
| Empty fields | {N} found | ... | ... |
| Token outliers | {N} found | ... | >2 std dev from mean |

## Cost Estimate (if action=estimate)
| Provider | Cost | Est. Time | Notes |
|----------|------|-----------|-------|
| OpenAI (gpt-4o-mini) | $X.XX | ~Xh | ... |
| Local (LoRA on 8B) | $0 | ~Xh | Requires GPU |
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Data validated | `[prompt-lab]` (test base model first for comparison) |
| Cost estimated | `[cost-status]` (budget check) |
| Data converted | `[data-export]` (backup original format) |
| Fine-tune complete | `[eval-suite]` (benchmark fine-tuned vs base) |
| baseline model outputs before fine-tuning via free-tier | `[reasoning-router]` (`route`) |
