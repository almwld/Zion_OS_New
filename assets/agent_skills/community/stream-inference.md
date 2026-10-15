---
provider-specific: true
name: stream-inference
description: Stream token-by-token output from Cloudflare Workers AI models. Real-time SSE streaming for agent workflows where the user sees output as it's generated. Reports TTFT, throughput, and Neuron consumption.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--model MODEL] [--prompt PROMPT] [--max-tokens N] [--raw]"
category: backend-infra
status: candidate
---
# Stream Inference

Token-by-token streaming from Cloudflare Workers AI via Server-Sent Events (SSE). Essential for real-time agent workflows where the user sees output as it's generated.

## When to Use
- Real-time agent responses where the user should see output as it's generated
- Long-running reasoning tasks where TTFT (time to first token) matters
- Measuring streaming throughput and latency characteristics
- Debugging reasoning model behavior (see chain-of-thought as it streams)

## Operations

### Stream a prompt
```bash
python ~/bin/stream_test.py --model glm-4.7-flash --prompt "Explain recursion" --max-tokens 200 --raw
python ~/bin/stream_test.py --model glm-5.2 --prompt "Review this code: def f(x): return x" --max-tokens 500
```

### Models supported
- `glm-4.7-flash` — fast reasoning, TTFT ~0.4s, ~29 tokens/sec
- `glm-5.2` — full reasoning, TTFT ~5s (thinks before responding), ~27 tokens/sec
- `gpt-oss-120b` — OpenAI reasoning model
- `deepseek-v4-flash` — DeepSeek reasoning
- `nemotron-3-120b` — NVIDIA Nemotron reasoning
- `llama-4-scout` — Meta Llama 4 general purpose
- `llama-3.3-70b` — Meta Llama 3.3 general purpose

## Streaming Format

Cloudflare Workers AI returns SSE with `data: {json}` lines. Reasoning models (GLM, GPT-OSS, DeepSeek) use `reasoning_content` in the delta; standard models use `content`. This skill handles both transparently.

### SSE chunk structure (reasoning models)
```
data: {"choices":[{"delta":{"reasoning":"...","reasoning_content":"..."}}],"usage":{"neurons":0.07}}
```

### SSE chunk structure (standard models)
```
data: {"choices":[{"delta":{"content":"..."}}],"usage":{"neurons":0.05}}
```

## Metrics Reported

| Metric | Description |
|--------|-------------|
| TTFT | Time to first token (latency) |
| Throughput | Tokens per second |
| Neurons | Cloudflare Neuron consumption |
| Token count | Both streamed count and API-reported count |

## Observed Performance (2026-08-20)

| Model | TTFT | Throughput | Neurons/100 tokens |
|-------|------|------------|---------------------|
| glm-4.7-flash | 0.38s | 28.9 tok/s | ~3.3 |
| glm-5.2 | 5.13s | 26.9 tok/s | ~37.5 |

Reasoning models have high TTFT because they think before producing output. For interactive use, prefer `glm-4.7-flash`. For complex reasoning, `glm-5.2` is worth the wait.

## Environment Variables

- `CLOUDFLARE_ACCOUNT_ID` — Cloudflare account ID
- `CLOUDFLARE_API_KEY` — Cloudflare API token (cfat_ prefix)

## Auto-Logging

The `stream_test.py` tool automatically logs Neuron consumption to the usage monitor after each successful stream, just like `reasoning-router`. No manual logging needed.

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| Need routing logic | `[reasoning-router]` for automatic provider selection |
| Track Neuron usage | `[usage-monitor]` to log consumption |
| Non-streaming is fine | `[reasoning-router]` for simpler batch completion |

## Mandatory

None — read-only streaming; no stateful side effects.

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction
- **T3 (Medium)**: May run without restriction
- **T4 (Probationary)**: May run
- **Operator**: Override any restriction
