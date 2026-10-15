---
name: gen-image
description: Vendor-neutral image and text generation over free OpenAI-compatible endpoints (NVIDIA, OpenRouter, HuggingFace, Groq, Cerebras, Together, Mistral, Google, or any custom vendor) via the hummbl-gen CLI. Free-tier first, no paid credits.
version: 0.1.0
execution-mode: advisory
argument-hint: "[prompt] [--provider <name>] [--model <id>] [--image|--chat] [--size WxH] [-n N]"
category: fleet-ops
status: candidate
providers:
  required: [python]
---
# Gen Image (vendor-neutral)

Generate images (and text) from the terminal through **free-tier OpenAI-compatible endpoints** via the `hummbl-gen` CLI shipped in this skill. Vendor-neutral by design: same command shape for every provider, and any unlisted vendor works via `--base-url` + `--api-key-env`.

This is the free-tier counterpart to `higgsfield-generate` (paid credits). It does NOT replace Higgsfield video, Soul-ID, Marketing Studio, or Virality Predictor — see **Capability map** below.

## Step 0 — Bootstrap

Shared rule: follow `~/.agents/rules/paid-external-generation-cli.md` when available — its spend/privacy discipline applies here too (free tiers still have quotas, and prompts/images sent to third parties must be operator-authorized).

1. CLI = `python "~/.agents/skills/gen-image/scripts/hummbl_gen.py"`. Verify with the `providers` command (below). Requires Python 3.11+ (already on PATH). Zero third-party deps.
2. **Credentials — 1Password auto-discovery is the primary path** (zero manual work per session). The CLI reads plain env vars; if a key is missing, it automatically attempts to read it from 1Password using a predictable naming convention:
   - **Naming convention**: create 1Password items named `hummbl-<provider>` (e.g., `hummbl-openrouter`, `hummbl-nvidia`, `hummbl-groq`, `hummbl-huggingface`, `hummbl-cerebras`, `hummbl-together`, `hummbl-mistral`, `hummbl-google`) in your **Private** vault, with a field named **`credential`**.
   - **Auto-discovery**: discovery commands (`providers`, `models`) automatically query 1Password when the desktop app is unlocked. Generation commands (`chat`, `image`) require explicit `--auto-1password` flag to prevent accidental credit spend.
   - **Prereq**: 1Password desktop app running + unlocked (biometric). No `op.env` files, no `op run` wrappers, no `setx`.
   - **Cache**: successful reads are cached in-memory for the process lifetime.
   - **Fallback**: if 1Password isn't available or items don't match, the error message guides you to the three paths (auto, manual `op run`, plain env).
   - **Never commit keys**. Never print key values.
3. Key env vars (for reference / plain-env fallback): `NVIDIA_API_KEY`, `OPENROUTER_API_KEY`, `HF_TOKEN`, `GROQ_API_KEY`, `CEREBRAS_API_KEY`, `TOGETHER_API_KEY`, `MISTRAL_API_KEY`, `GEMINI_API_KEY`.
4. Never print, log, or echo API key values anywhere.

```bash
python ~/.agents/skills/gen-image/scripts/hummbl_gen.py providers          # auto-discovers from 1Password if unlocked
# generation requires explicit flag to avoid accidental spend:
python ~/.agents/skills/gen-image/scripts/hummbl_gen.py chat --provider groq --model <id> --prompt "..." --auto-1password
```

## UX Rules

1. Be concise. For images: deliver local file paths. For text: the content only.
2. No internal jargon. Don't narrate "calling chat/completions".
3. Detect the user's language; reply in it. Flags stay English.
4. Don't batch-ask. Pick a sane default provider+model and ask one thing at a time only if genuinely missing.
5. Spend/privacy guardrail: only run generation after the operator explicitly requested it in the current turn. Discovery commands (`providers`, `models`) are always allowed.
6. Quota guardrail: on 429/quota errors, switch provider rather than hammering retries — the CLI already retries transient failures twice.

## Commands

```bash
hummbl-gen providers                        # presets + which keys are set
hummbl-gen models --provider openrouter --free   # discover models
hummbl-gen chat   --provider groq --model <id> --prompt "..."   # text gen
hummbl-gen image  --provider openrouter --model <id> --prompt "..." -n 3   # image gen
hummbl-gen image  --base-url https://vendor.example/v1 --api-key-env MY_KEY --model <id> --prompt "..."  # any vendor
```

(`hummbl-gen` = the full python path from Step 0; alias it in the shell if it helps.)

- `--dry-run` on chat/image prints the exact request minus auth — use for verification without spending quota.
- `--json` gives raw responses for pipelines.
- Image output: `hummbl-gen-<timestamp>-N.png` in CWD, or `--out name` (prefix when `-n > 1`).

## Provider selection

| Provider | Free posture | Best for |
|---|---|---|
| `openrouter` | `:free` model ids + trial credits | widest model menu incl. image-capable free models |
| `huggingface` | monthly free inference credits | FLUX-class image models via router |
| `nvidia` | free developer credits | fast text; some image NIMs |
| `groq` / `cerebras` | generous free tiers | ultra-fast text (no image gen) |
| `together` | free FLUX.1 schnell | solid free image gen |
| `google` | free tier | Gemini text + image-capable flash models |
| `mistral` | experiment tier | text |
| custom | any | any OpenAI-compatible vendor with 2 flags |

## Model discovery (do this, don't guess)

Model ids change often. Always verify before first use:

```bash
hummbl-gen models --provider openrouter --free
hummbl-gen models --provider huggingface
hummbl-gen models --provider nvidia
```

Known-good **candidate** ids (verify at runtime with `models` — free lineups shift):
- image: OpenRouter Gemini flash image-preview `:free` variants; Together `fluke-ai/flux-schnell`-class FLUX; HF router `fal-ai/flux-schnell`-class.
- text/enhancement: any free Llama/Gemini/DeepSeek `:free` id on OpenRouter or Groq.

## Local prompt enhancement (replaces paid backend enhancers)

Higgsfield's product-photoshoot / marketplace-cards backends add photography vocabulary server-side. Here, **you** are the enhancer: assemble the final prompt locally (see `gen-photoshoot` and `gen-marketplace-cards` for mode templates), then submit with `image`. Optionally use `chat` on a free text model to draft/expand prompt variants first — then feed the best into `image`.

## Capability map — what moves to free, what stays paid

| Capability | Free path (this skill) | Stays on Higgsfield (paid credits) |
|---|---|---|
| Text gen / prompt enhancement | `chat` — full coverage | — |
| Image gen (product, brand, illustration) | `image` — covered | — |
| Reference-conditioned image (img2img style) | partial (model-dependent; verify model supports image input) | Soul 2.0 / Nano Banana (strong) |
| Video generation | **no free equivalent** | Seedance 2.0, Kling, Veo, Marketing Studio video |
| Identity training (face-faithful) | **no free equivalent** | `higgsfield-soul-id` (Basic+ plan) |
| Marketing Studio (avatars, hooks, ad refs, brand kits) | approximate with local prompt templates only | full backend system |
| Virality Predictor (video analysis) | **no free equivalent** | `brain_activity` |

Route video / identity / virality requests to the `higgsfield-*` skills and tell the operator they spend credits.

## Chaining

- `brand-guidelines` / `hummbl-branded-artifacts` — inject HUMMBL tokens (Grove/Verderer greens, Crimson Pro/Inter) into prompts before submitting.
- `gen-photoshoot` — product photoshoot modes on top of this CLI.
- `gen-marketplace-cards` — marketplace listing image system on top of this CLI.

## Errors

- `HTTP 401/403` → key missing/wrong env var; check `providers`.
- `HTTP 429` → rate/quota; switch provider or wait (CLI already backed off twice).
- `no images returned … /images/generations` → that model isn't image-capable or provider lacks the endpoint; pick another model/provider (verify with `models`).
- `--model required` → discover ids first with `models`.
- Network errors → CLI retries; persistent failure usually means wrong base URL for custom vendors.

## Provider size limitations

| Provider | Max output size | Notes |
|----------|----------------|-------|
| Pollinations.ai | **768x768** | Caps output at 768px regardless of `?width`/`?height` URL params. Requesting 1024x1024 returns 768x768 silently. (Origin: 2026-09-02 polycube lab — 5 images requested at 1024x1024, all returned 768x768.) |
| OpenRouter (image models) | Varies by model | Check model card for max resolution. |
| HuggingFace | Varies by model | Check model card for max resolution. |

**When resolution matters:** if the target use case requires >768px (e.g., print, high-DPI display, downstream upscaling), do not use Pollinations.ai. Use a provider that supports the target resolution natively, or upscale the 768px output with a separate tool.

## Skill Chains
- For vendor-neutral generation across overlapping providers -> `[reasoning-router]` (`python ~/bin/reasoning_router.py providers`)
