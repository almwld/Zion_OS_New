---
name: model-router
description: Design multi-model routing -- select optimal model per task based on cost, quality, latency, and context
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action design|analyze|recommend] [--budget USD]"
category: backend-infra
status: candidate
---
# Model Router Designer

Design intelligent multi-model routing strategies that select the optimal LLM for each task based on cost, quality, latency, and context window requirements. Supports budget-constrained optimization and fallback chains.

## When to Use
- Building a system that needs to route different tasks to different models
- Optimizing API spend by downgrading simple tasks to cheaper models
- Designing fallback chains for when a primary model is unavailable
- Analyzing current model usage patterns to find cost savings

## Execution
1. Parse `$ARGUMENTS` for `--action` (default: `design`) and optional `--budget` constraint
2. For `design`: define task categories (simple classification, code generation, creative writing, analysis, etc.), map each to optimal model considering cost/quality/latency tradeoffs
3. For `analyze`: review current model usage patterns, identify tasks being over-served by expensive models, calculate potential savings
4. For `recommend`: given a specific task description, recommend the best model with rationale
5. Build a routing decision tree: task complexity assessment -> context length check -> quality requirement -> budget constraint -> model selection
6. Design fallback chains (e.g., Claude Opus -> Claude Sonnet -> Claude Haiku)
7. Include latency budgets and timeout handling per model tier
8. Estimate monthly cost under the routing strategy vs single-model baseline

## Output Format
```
Model Router | {action}
────────────────────────────────
Task categories: {N}
Models in pool: {list}
Budget: {USD/month or unconstrained}

Routing Table:
| Task Type | Primary | Fallback | Max Latency | Est. Cost |
|-----------|---------|----------|-------------|-----------|
| classify  | Haiku   | --       | 500ms       | $0.002    |
| code_gen  | Sonnet  | Opus     | 5s          | $0.08     |
| analysis  | Opus    | Sonnet   | 30s         | $0.15     |

Estimated monthly cost: ${N} (vs ${N} single-model baseline)
Savings: {N}%
Action: {next steps or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Routing designed | `[token-estimate]` to validate cost projections |
| Analysis shows waste | `[ai-cost-optimize]` for broader cost reduction |
| Model comparison needed | `[model-compare]` to benchmark candidates on real inputs |
| Ready to execute routing | `[reasoning-router]` to run the actual inference via free-tier providers |
| Latency data needed for routing table | `[stream-inference]` to measure TTFT and throughput per model (`python ~/bin/stream_test.py <model> --prompt "test"`) |
| Neuron budget check before routing | `[usage-monitor]` to check remaining Cloudflare Neurons (`python ~/bin/usage_monitor.py status`) |

## Executable Implementation
This skill is advisory/design-only. For executable routing across free-tier providers (Cloudflare Workers AI, Google Gemini, OpenRouter, NVIDIA NIM, HuggingFace Router), use:
```bash
python ~/bin/reasoning_router.py route "<prompt>" --task <task-type> [--temperature N] [--top-p N] [--stream] [--use-gateway]
python ~/bin/reasoning_router.py providers  # list available providers
python ~/bin/reasoning_router.py probe      # test connectivity
```
