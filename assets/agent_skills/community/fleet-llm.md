---
name: fleet-llm
description: Multi-provider LLM gateway — Aperture (unfunded 2026-09-27), Cloudflare Workers AI, Groq, Nvidia, DeepSeek, and Cheaper Inference (funded 2026-09-23) for fleet agents
version: 2.1.0
execution-mode: side_effecting
argument-hint: "[prompt]"
category: hummbl-research
status: candidate
---
# Fleet LLM Gateway

Multi-provider LLM access for fleet agents. Live-probe status 2026-09-27:

1. **Aperture** (Tailscale-authenticated) — REACHABLE but UNFUNDED: every catalog model returns HTTP 402 "payment method required". The old "free Gemini/Gemma" claim is stale — no free models remain.
2. **Cloudflare Workers AI** (free Neurons quota) — `CLOUDFLARE_API_KEY`/1Password token; `@cf/*` models, probe-verified 2026-09-27
3. **Groq** (free tier, fast) — GROQ_API_KEY; `groq/compound*` IDs 404 — use `qwen/*`, `openai/gpt-oss-*`
4. **Nvidia** (free tier, ~80 models) — NVIDIA_API_KEY from env
5. **DeepSeek** (~$6 remaining, cheap) — DEEPSEEK_API_KEY; 1Password item `HUMMBL-DEEPSEEK-API-KEY-09242026` is the live key (old `HUMMBL-DEEPSEEK` item is stale/401)
6. **Cheaper Inference** (paid discount marketplace; FUNDED 2026-09-23, live-probed 2026-09-27) — CHEAPER_INFERENCE_API_KEY

### Provider Latency (measured 2026-09-02)

| Provider | Latency | Best For |
|----------|---------|----------|
| Groq | ~1s | Interactive work, real-time completions |
| Aperture | ~1s | UNFUNDED 2026-09-27 — do not select until wallet is topped up |
| Cloudflare Workers AI | ~1-3s | Free interactive work, no wallet needed |
| DeepSeek | ~3-5s | Code generation, batch tasks |
| Nvidia | ~15s | Batch tasks only — too slow for interactive use |

Select Groq or Cloudflare Workers AI for interactive work. Reserve Nvidia for batch tasks
where latency doesn't matter. (Origin: 2026-09-02 — 3 consecutive timed runs
to Nvidia all >12s.)

## When to Use

- When you need LLM completions and don't want to spend API credits
- When you need a free model for research, code generation, or analysis
- When you need tool-calling support without paying for GPT-4/Claude
- When the operator's OpenAI/Anthropic credits are exhausted

## Available Models

### Aperture (Tailscale-authenticated — UNFUNDED 2026-09-27, all models 402)

Discover live IDs with `python ~/bin/fleet-llm.py --list-models` (or
`FLEET_LLM_MODEL`). Do not hardcode dated Gemini version strings here;
they rot and couple the gateway to a vendor snapshot.

| Class | Context | Tool Calling | Streaming | Notes |
|-------|---------|-------------|-----------|-------|
| Aperture default (flash-lite class) | 1M | Yes | Yes | Default — fast, capable |
| Aperture reasoning (flash class) | 1M | Yes | Yes | Newer, has reasoning tokens |
| Aperture open-weights (`gemma-4-31b-it`) | 262K | Yes | Yes | Google open-weights |

### Groq (free tier, very fast)

| Model | Context | Notes |
|-------|---------|-------|
| `qwen/qwen3.8-27b` | 131K | Qwen 3.8 27B — probe-verified 2026-09-27 |
| `qwen/qwen3.6-27b` | 131K | Qwen 3.6 27B |
| `openai/gpt-oss-120b` | 131K | GPT-OSS 120B |
| `openai/gpt-oss-20b` | 131K | GPT-OSS 20B |
| `meta-llama/llama-4-scout-17b-16e-instruct` | 131K | Llama 4 Scout |

(Removed `groq/compound`/`groq/compound-mini` — 404 "does not exist" on this account as of 2026-09-27.)

### Nvidia (free tier, slower)

| Model | Context | Notes |
|-------|---------|-------|
| `deepseek-ai/deepseek-v4-flash-0731` | 131K | DeepSeek V4 Flash |
| `deepseek-ai/deepseek-v4-pro-0813` | 131K | DeepSeek V4 Pro |
| `meta/llama-3.1-405b-instruct` | 131K | Llama 405B |

### DeepSeek (paid, ~$6 remaining — live key is 1Password `HUMMBL-DEEPSEEK-API-KEY-09242026`)

| Model | Context | Notes |
|-------|---------|-------|
| `deepseek-chat` | 131K | Main chat model |
| `deepseek-reasoner` | 131K | Reasoning model |

### Cheaper Inference (paid, FUNDED 2026-09-23 — live-probed 2026-09-27)

OpenAI-compatible discount gateway (Keak AI, Inc.). Route explicitly via the
`ci/` prefix or `--provider cheaper-inference`. Catalog is dynamic and
advertised discounts rotate — resolve live model IDs from
`GET https://api.cheaperinference.com/v1/models`; do not
hardcode catalog IDs here (snapshot 2026-09-21 showed DeepSeek/GLM/GPT/Claude
families at ~30-64% off list).

**Constraints (hard rules until due diligence clears):**
- **Non-sensitive traffic only** — requests execute under third-party sellers'
  upstream provider accounts (credential-relay marketplace). No PII, secrets,
  unpublished IP, or governance payloads.
- **Never default routing** — explicit opt-in only; not in any routing_role.
- **Prompt-mutation techniques** — dashboard "techniques" (context trim,
  cache, model swap) must stay OFF for correctness-sensitive work.
- Wallet is prepaid and non-refundable ($5 min). HTTP 402 can indicate
  concurrent pre-authorization holds, not an empty wallet — retry before
  concluding funds are out.

## Python API

```python
import os
from fleet_llm import chat, stream_chat, gemini_native

# Discover IDs: python ~/bin/fleet-llm.py --list-models
# Aperture default lives in FLEET_LLM_MODEL; do not paste dated Gemini ids.
model = os.environ.get("FLEET_LLM_MODEL", "qwen/qwen3.8-27b")

# Auto-routes by model name prefix
resp = chat(model, [{"role": "user", "content": "What is 2+2?"}])
resp = chat("qwen/qwen3.8-27b", [{"role": "user", "content": "What is 2+2?"}])
resp = chat("deepseek-chat", [{"role": "user", "content": "What is 2+2?"}])

# Force a provider
resp = chat("deepseek-ai/deepseek-v4-flash-0731", messages, provider="nvidia")

# Streaming
for chunk in stream_chat("qwen/qwen3.8-27b", messages):
    print(chunk, end="")

# Tool calling
resp = chat(model, messages, tools=[{
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get weather for a city",
        "parameters": {"type": "object", "properties": {"city": {"type": "string"}}}
    }
}])

# Native Gemini API (for models that don't support OpenAI format)
native = os.environ["FLEET_LLM_NATIVE_MODEL"]  # id from --list-models
resp = gemini_native(native, prompt="Hello")
```

## CLI

```bash
# Simple prompt (defaults to the Aperture default from --list-models)
python ~/bin/fleet-llm.py "What is 2+2?"

# Choose model (auto-routes to correct provider)
python ~/bin/fleet-llm.py --model groq/compound "Explain quantum computing"
python ~/bin/fleet-llm.py --model deepseek-chat "Write a function"
python ~/bin/fleet-llm.py --model deepseek-ai/deepseek-v4-flash-0731 "Hello"

# Force a provider
python ~/bin/fleet-llm.py --provider groq --model groq/compound "Hello"

# Stream output
python ~/bin/fleet-llm.py --stream "Write a haiku about fleets"
python ~/bin/fleet-llm.py --stream --model groq/compound "Count to 5"

# List verified models
python ~/bin/fleet-llm.py --list-models

# List all models from a specific provider
python ~/bin/fleet-llm.py --provider groq --list-models

# List configured providers
python ~/bin/fleet-llm.py --list-providers
```

## Model Routing

The gateway auto-routes based on model name prefix:

| Prefix | Provider |
|--------|----------|
| `ci/*` | Cheaper Inference (explicit-only; prefix stripped upstream) |
| `@cf/*` | Cloudflare Workers AI (direct REST) |
| `gemini-*`, `gemma-*` | Aperture |
| `groq/*`, `qwen/*`, `openai/gpt-oss-*`, `meta-llama/*` | Groq |
| `deepseek-*`, `deepseek/*` | DeepSeek |
| `<anything else>` | Aperture (default — WARNING: unfunded, returns 402) |

Override with `--provider` or `provider=` kwarg.

## OpenCode Integration

The `aperture` provider is configured in `~/.config/opencode/opencode.jsonc`:

```bash
# Resolve the Aperture id from --list-models; do not pin a dated Gemini string.
opencode -m aperture/$FLEET_LLM_MODEL
```

## Codex Integration

```bash
# Use the wrapper script
~/bin/codex-aperture "fix the bug in src/main.rs"

# Or set env vars directly
export OPENAI_BASE_URL=http://ai/v1
export OPENAI_API_KEY=ts-noauth-needed
codex -m "$FLEET_LLM_MODEL"
```

## API Endpoints

- **Aperture**: `http://ai/v1/chat/completions` (Tailscale-authenticated)
- **Groq**: `https://api.groq.com/openai/v1/chat/completions`
- **Nvidia**: `https://integrate.api.nvidia.com/v1/chat/completions`
- **DeepSeek**: `https://api.deepseek.com/v1/chat/completions`
- **Cheaper Inference**: `https://api.cheaperinference.com/v1/chat/completions`
- All are OpenAI-compatible

## Limitations

- Aperture: UNFUNDED as of 2026-09-27 — all catalog models return HTTP 402; do not route to it until the wallet is topped up
- Nvidia: free tier is slower (~10-20s response times)
- DeepSeek: ~$6 remaining (not free, but cheap); fleet-llm resolves the 1Password `HUMMBL-DEEPSEEK-API-KEY-09242026` item
- Cheaper Inference: funded and live; seller-relay upstream means model identity/route can change without notice; non-sensitive traffic only
- Groq: Cloudflare blocks urllib's default User-Agent (fleet-llm.py sets `fleet-llm/2.0`)
- No image generation, no embeddings
- Rate limits are per-provider free-tier limits

## Install

The wrapper is at `~/bin/fleet-llm.py`. No installation needed — stdlib only.
- Aperture requires the `ai` node on Tailscale (check: `tailscale status | grep ai`)
- Groq/Nvidia/DeepSeek require their respective API keys in `~/.config/hummbl/.env`

## Skill Chains

### Mandatory

- Resolve Aperture model IDs via `--list-models` or `FLEET_LLM_MODEL`; do not
  hardcode dated Gemini version strings
- Prefer a free provider before spending operator OpenAI/Anthropic credits

### Advisory

- After a completion that will leave the fleet → `admission-gate`
- For cost tracking → `usage-monitor` or `agent-cost-track`

## Authority

- **T1 (TRUSTED)**: May run freely
- **T2 (Active/High)**: May run freely
- **T3 (Medium)**: May run freely
- **T4 (Probationary)**: May run with operator notification
- **Operator**: Override any restriction
