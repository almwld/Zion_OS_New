---
name: freemodel-generate
description: Zero-cost text, vision, and image generation via free endpoints on NVIDIA NIM, OpenRouter, and HuggingFace Router. OpenAI-compatible, vendor-neutral, failover across providers. Use when asked to generate text/vision analysis/images for free, without Higgsfield credits, or when a higgsfield-* skill is unavailable due to free-tier limits. No video generation or identity training (see references/provider-matrix.md for the boundary).
version: 0.1.1
execution-mode: side_effecting
argument-hint: "[prompt] [--provider nvidia|openrouter|huggingface|auto] [--mode text|vision|image] [--image <path>]"
category: dev-tools
status: candidate
---

<!-- SoT: profile (~/.agents/skills/). Created as canonical skill; not yet promoted to any lean set. -->
# freemodel-generate

Vendor-neutral generation over free OpenAI-compatible endpoints. Replaces the paid path of `higgsfield-generate` when the operator is on a free budget.

## Step 0 — Bootstrap (read `references/provider-matrix.md` first)

1. **Key discovery.** Check env vars `NVIDIA_API_KEY`, `OPENROUTER_API_KEY`, `HF_TOKEN`. If none are set, stop and tell the operator which to create (see matrix for signup URLs). Never print token values.
2. **Probe before use.** One cheap request per provider (e.g. list models or a 1-token completion) to verify the key and quota. If a provider 401/429s, mark it unavailable and fail over.
3. **No spend by design.** These endpoints are free-tier. If any call would incur cost (paid model variant, top-up), stop and ask the operator first.

## UX Rules

1. Be concise. No raw JSON in chat — print the final content or saved file path.
2. Pick a sane default provider/model; ask at most one question when genuinely ambiguous.
3. Respect the network/state guardrail: only call generation endpoints after the operator explicitly requests that generation in the current turn. Key/quota probes are allowed for planning.
4. For hummbl-brand work, compose prompts per the `brand-guidelines` skill (Grove/Verderer greens, Crimson Pro/Inter, tone) before submitting.

## Provider Selection (auto mode)

| Priority | Provider | Best at | Free allowance |
|---|---|---|---|
| 1 | HuggingFace Router | text, vision, image (FLUX.1-schnell) | monthly inference credits |
| 2 | NVIDIA NIM | text, vision (Nemotron family) | trial credits, renewing dev tier |
| 3 | OpenRouter | text only (`:free` models) | ~50 req/day |

Failover order: requested provider → next available. Vision: NIM or HF only. Image: HF only (NVIDIA image routes are model-specific; see matrix).

## Workflows

### Text generation
```bash
curl -s <base_url>/chat/completions \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"model":"<model-id>","messages":[{"role":"user","content":"<prompt>"}],"max_tokens":1024}'
```

### Vision (image understanding — NOT generation)
Same call with `"content":[{"type":"text","text":"..."},{"type":"image_url","image_url":{"url":"data:image/png;base64,<B64>"}}]`. Base64 via `base64 -w0 <path>`.

### Image generation
HF Router, provider-specific route (e.g. fal-ai FLUX.1-schnell) — exact route + payload in `references/provider-matrix.md`. Always probe the route first; image routing on HF varies by provider. Save output to a file, report the path, never inline raw bytes.

## Boundaries (what stays on Higgsfield or paid tiers)

- **Video generation** — no free endpoint equivalent. Route to `higgsfield-generate` when operator has credits.
- **Identity/face training** (`soul-id`) — no free equivalent anywhere. Also requires Higgsfield Basic+ (paid) per its skill card. Treat face photos as sensitive under all providers.
- **Marketplace/private prompt enhancement** — Higgsfield's enhancers are proprietary. This skill assembles prompts locally instead (see `prompt-assembly.md` patterns reused by the `freemodel-product-photoshoot` and `freemodel-marketplace-cards` skills).

## Failure handling

- 401 → key invalid: tell operator, fail over.
- 429 → quota exhausted: mark provider dead for the session, fail over; if all dead, report which quotas need attention.
- 5xx/timeout → single retry, then fail over.

## Automated Routing
For automated provider selection and failover across all free-tier providers, use the reasoning-router tool:
```bash
python ~/bin/reasoning_router.py route "<prompt>" --task <task-type> [--provider nvidia|openrouter|huggingface|cloudflare|gemini] [--use-gateway]
```
The router scores models by task fit, context length, and strength, then fails over automatically. See `[reasoning-router]` skill for details.

## Cost Tracking
When using Cloudflare as a provider, Neuron consumption is auto-logged. Check budget with:
```bash
python ~/bin/usage_monitor.py status
```
See `[usage-monitor]` skill for details.

## Skill Chains

### Mandatory

- Read `references/provider-matrix.md`, keep credentials out of output, and
  make no paid call or top-up.
- Submit a generation request only after the operator explicitly requests that
  generation in the current turn; otherwise limit work to the permitted
  key/quota planning probes.

### Advisory

- For streaming path for Cloudflare Workers AI generation -> `[stream-inference]` (`python ~/bin/stream_test.py --model <model> --prompt test`)

## Authority

- **All agents:** May inspect existing provider configuration without revealing
  token values and may perform the documented no-cost availability probes.
  They may submit generation only for a current-turn operator request and must
  stop when credentials are unavailable or a call would incur cost.
- **Operator:** Must explicitly request generation and may approve a paid model
  variant or top-up after the skill stops and asks.
