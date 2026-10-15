---
provider-specific: true
name: reasoning-router
description: Route reasoning tasks across free model providers (Cloudflare, Groq, Gemini, GitHub Models, SambaNova, OpenRouter) based on task type, context length, and free-tier budget. Executable router with automatic failover. Extends freemodel-generate to reasoning tasks.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[route|providers|models|probe] [--task code-review|analysis|summarization|...] [--dry-run]"
superseded-by: fleet-llm
superseded-note: "The executable script (reasoning_router.py) was never built. fleet-llm now provides multi-provider routing with failover across Aperture, Groq, Nvidia, and DeepSeek. Use `fleet-llm` instead."
category: backend-infra
status: candidate
---
# Reasoning Router

> **SUPERSEDED 2026-09-02** — The executable script (`~/bin/reasoning_router.py`)
> was never built. Use the **`fleet-llm`** skill instead, which provides
> multi-provider routing with automatic failover across Aperture (Gemini),
> Groq, Nvidia, and DeepSeek. This skill is retained for its task-type routing
> table, which may inform future `fleet-llm` enhancements.

Executable model router that dispatches reasoning tasks to the best available free-tier provider. Unlike `model-router` (advisory-only design), this skill **executes** the completion and returns the result.

## When to Use
- Code review or analysis where you want free-tier inference
- Summarization of long documents (routes to long-context models)
- Any reasoning task where cost matters and free providers suffice
- Probing which free providers are currently available

## Operations

### Route a task (auto-select provider)
```bash
python ~/bin/reasoning_router.py route "Review this code for security issues" --task code-review
python ~/bin/reasoning_router.py route "Summarize this paper" --task summarization --context-length 50000
python ~/bin/reasoning_router.py route "Analyze the implications of X" --task analysis --max-tokens 4096
```

### Dry run (see routing decision without executing)
```bash
python ~/bin/reasoning_router.py route "Review this code" --task code-review --dry-run
```

### Route through Cloudflare AI Gateway (caching, rate limiting, logs)
```bash
python ~/bin/reasoning_router.py route "Review this code" --task code-review --use-gateway
```

### List available providers
```bash
python ~/bin/reasoning_router.py providers
```

### List all models
```bash
python ~/bin/reasoning_router.py models
```

### Probe connectivity
```bash
python ~/bin/reasoning_router.py probe
python ~/bin/reasoning_router.py probe --provider cloudflare
```

## Task Types

| Task type | Preferred strength | Min context | Routes to |
|-----------|-------------------|-------------|-----------|
| code-review | reasoning | 32K | GLM-5.2, GPT-OSS-120B, DeepSeek-V4 |
| code-generation | reasoning | 32K | GLM-5.2, GPT-OSS-120B |
| summarization | general | 32K | Llama-4-Scout, Llama-3.3-70B |
| analysis | reasoning | 64K | GLM-5.2, GPT-OSS-120B |
| long-context | long-context | 100K | Gemini-2.5-Flash (1M ctx) |
| quick-lookup | fast | 8K | GLM-4.7-Flash, Llama-3.2-1B |
| frontier | frontier | 128K | GPT-4o (GitHub Models) |
| large-model | large-model | 64K | Llama-3.3-405B (SambaNova) |

## Provider Priority

| Provider | Free allowance | Best for |
|----------|---------------|----------|
| Cloudflare Workers AI | 10K Neurons/day | Reasoning (GLM-5.2, GPT-OSS-120B) |
| Groq | 30 RPM, 14.4K RPD | Fast inference (Llama family) |
| Gemini | 15 RPM, 1M TPM | Long context (1M+ tokens) |
| GitHub Models | Low rate | Frontier access (GPT-4o) |
| SambaNova | Limited RPD | Large model access (405B) |
| OpenRouter | ~50 RPD | Reasoning (Nemotron :free) |

## Environment Variables

Each provider needs its env vars set. Only Cloudflare is currently configured:

| Provider | Env vars |
|----------|----------|
| cloudflare | `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_API_KEY` |
| groq | `GROQ_API_KEY` |
| gemini | `GEMINI_API_KEY` |
| github-models | `GITHUB_TOKEN` |
| sambanova | `SAMBANOVA_API_KEY` |
| openrouter | `OPENROUTER_API_KEY` |

## Failure Handling

- 401 → key invalid: report, fail over to next candidate
- 429 → rate limited: report, fail over
- Automatic fallback to next-best candidate on any error
- If all candidates fail, exit with error

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| Routing decision needed | `[model-router]` for advisory design |
| Free text/image generation | `[freemodel-generate]` for non-reasoning generation |
| Cost tracking needed | Track Neurons reported in stderr per request |
| Neuron budget check | `[usage-monitor]` to check remaining Cloudflare Neurons (`python ~/bin/usage_monitor.py status`) |
| Streaming latency benchmark | `[stream-inference]` to measure TTFT and throughput per model (`python ~/bin/stream_test.py <model> --prompt "test" --use-gateway`) |

## Mandatory

None — routing is advisory; model selection is deterministic.

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction
- **T3 (Medium)**: May run without restriction
- **T4 (Probationary)**: May run
- **Operator**: Override any restriction
