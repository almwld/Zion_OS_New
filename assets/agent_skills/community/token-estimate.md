---
provider-specific: true
name: token-estimate
description: Estimate token count and cost for prompts, documents, or conversations across models.
version: 0.1.0
execution-mode: advisory
argument-hint: "[FILE_OR_TEXT] [--model claude-opus|claude-sonnet|claude-haiku|gpt-4o|all]"
category: hummbl-research
status: candidate
---
# Token Estimate

Quick token count and cost estimation without making an API call. Useful for budgeting, context window planning, and cost optimization.

## When to Use
- Before sending a large document to an LLM
- Estimating API costs for a batch job
- Checking if content fits in a context window
- When user says "how many tokens" or "how much will this cost"

## Execution

1. **Read input**: file path, clipboard, or inline text
2. **Estimate tokens**: Use word count * 1.3 as rough estimate (or tiktoken if available)
3. **Calculate cost** across models using current pricing
4. **Check context fit**: Will it fit in the model's context window?

## Pricing Table (as of Mar 2026)

| Model | Input $/MTok | Output $/MTok | Context |
|-------|-------------|--------------|---------|
| Claude Opus 4.6 | $15.00 | $75.00 | 200K (1M extended) |
| Claude Sonnet 4.6 | $3.00 | $15.00 | 200K |
| Claude Haiku 4.5 | $0.80 | $4.00 | 200K |
| GPT-4o | $2.50 | $10.00 | 128K |
| GPT-5.4 | $5.00 | $15.00 | 256K |

*Prices may be outdated -- verify at docs.anthropic.com or openai.com/pricing*

## Output Format

```
Token Estimate | {source}
=========================

## Input
Source: {file path or "inline text"}
Characters: {N}
Words: {N}
Estimated tokens: {N}

## Cost Estimate
| Model | Input Cost | Est. Output Cost* | Total | Fits Context? |
|-------|-----------|-------------------|-------|---------------|
| Opus 4.6 | $X.XX | $X.XX | $X.XX | YES/NO |
| Sonnet 4.6 | $X.XX | $X.XX | $X.XX | YES/NO |
| Haiku 4.5 | $X.XX | $X.XX | $X.XX | YES/NO |

*Output cost estimated at 1.5x input tokens (typical ratio)

## Recommendation
{Cheapest model that fits context, or warning if none fit}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Content too large | `[dimension-reduce]` (summarize before sending) |
| Cost too high | `[model-compare]` (try cheaper model) |
| Fits context | `[prompt-lab]` (proceed with prompt design) |
| Budget planning | `[runway]` (factor into cost projections) |
| convert Cloudflare Neuron costs to USD equivalents | `[usage-monitor]` (`python ~/bin/usage_monitor.py status`) |
