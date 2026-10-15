---
name: freemodel-product-photoshoot
description: Brand-quality product imagery via free endpoints (HF FLUX.1-schnell primary) with locally-assembled mode-specific photography prompts. Vendor-neutral counterpart to higgsfield-product-photoshoot for free-tier budgets. Use for product shots, lifestyle scenes, hero banners, social carousels, ad packs without Higgsfield credits.
version: 0.1.1
execution-mode: side_effecting
argument-hint: "[--mode <mode>] [--count N] [--aspect 16:9|2:3|1:1] [product description or --image <path>]"
category: dev-tools
status: candidate
---

<!-- SoT: profile (~/.agents/skills/). Vendor-neutral port of higgsfield-product-photoshoot (v0.3.0). Canonical only; not in any lean set. -->
# freemodel-product-photoshoot

Port of `higgsfield-product-photoshoot`. Key difference: no proprietary backend enhancer — prompts are assembled locally via a free text model, then rendered via the free image route in `freemodel-generate` (read its `references/provider-matrix.md`).

## Step 0 — Bootstrap

1. Follow `freemodel-generate` bootstrap: verify `HF_TOKEN` (image) and at least one text key. Probe both routes.
2. If the operator explicitly wants Higgsfield's `gpt_image_2` quality and has credits, say so and route to `higgsfield-product-photoshoot` instead.
3. Network/state guardrail: only submit generation after the operator explicitly requests product imagery this turn. Key probes are allowed.

## UX Rules

1. Concise. Final reply = saved file paths + short labels, nothing else.
2. At most 4 short questions before submitting; skip anything obvious from context or brand memory.
3. Respond in the user's language; mode names and flags stay English.
4. For hummbl-brand work, inject tokens from the `brand-guidelines` skill before rendering.

## Modes (ported unchanged)

| Mode | When user wants… |
|---|---|
| `product_shot` | Product on neutral / studio / catalog background |
| `lifestyle_scene` | Product in real-world environment, hands, action, atmosphere |
| `closeup_product_with_person` | Tight crop with hands / partial face — beauty application, holding, demonstrating |
| `moodboard_pin` | Vertical 2:3 Pinterest-native aesthetic, moodboard feel |
| `hero_banner` | Wide-format website / email / campaign header |
| `social_carousel` | 3–10 connected slides for IG / LinkedIn / Facebook |
| `ad_creative_pack` | Coordinated pack of static ad variants for Meta / TikTok / Pinterest / Google Ads |
| `virtual_model_tryout` | Product worn or used by an AI-rendered model |
| `conceptual_product` | Surreal / CGI-style / levitating / splash / sculptural product |
| `restyle` | Transform an existing image's aesthetic, mood, or seasonal context |

Pick by intent, not surface keyword. When two modes apply, prefer the more specific.

## Workflow

1. **Collect.** Product description or reference image, mode, count, aspect. Reference images: only usable with vision-capable + image-edit-capable endpoints — free tier rarely supports img2img; default to text-to-image and say so plainly.
2. **Assemble prompt locally** (replaces backend enhancer). One free text-model call:
   - System role: "commercial photography director; output a single dense image-generation prompt, no preamble"
   - Include: mode vocabulary from the table above, product details, lighting/lens/composition guidance, brand tokens when relevant.
3. **Render.** FLUX.1-schnell via HF Router (`freemodel-generate` image workflow). `--count N` = N sequential calls with slight prompt variation; carousels/packs = per-asset calls with a consistent style seed phrase.
4. **Save + deliver.** Files to `<dest or cwd>/photoshoot_<mode>_<NN>.png`. Report paths only.

## Boundaries vs the paid original

- Model ceiling: FLUX.1-schnell ≠ gpt_image_2 on complex text-in-image and photoreal faces. State this when the operator asks for heavy in-image typography or faces.
- `restyle` mode on an existing image needs img2img — often unavailable free. Offer text-prompted re-render instead.
- No `virtual_model_tryout` face fidelity without identity training (see freemodel-generate boundaries: soul-id has no free equivalent).

## Skill Chains

### Mandatory

- Complete the `freemodel-generate` bootstrap, including the documented route
  probes, before rendering. Submit product imagery only after the operator
  explicitly requests it in the current turn.
- Save outputs only to the requested destination or current working directory
  and report paths rather than raw bytes. For unavailable img2img or
  face-fidelity work, use the documented text-prompted re-render or state the
  boundary.

### Advisory

- For prompt enhancement runs on a free text model -> `[reasoning-router]` (`python ~/bin/reasoning_router.py route`)

## Authority

- **All agents:** May collect product details and prepare local prompt
  scaffolds. They may submit free-tier renders only after the documented
  bootstrap and a current-turn explicit product-imagery request.
- **Operator:** May request product imagery or explicitly choose the paid
  Higgsfield route when credits are available.
