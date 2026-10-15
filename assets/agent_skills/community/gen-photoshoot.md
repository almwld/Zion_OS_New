---
name: gen-photoshoot
description: Brand-quality product photoshoots on free vendor-neutral endpoints. Local mode-specific prompt templates replace the paid backend enhancer. Wraps gen-image (hummbl-gen CLI).
version: 0.1.0
execution-mode: advisory
argument-hint: "[--mode <mode>] [--count N] [prompt]"
category: dev-tools
status: candidate
---
# Gen Photoshoot (vendor-neutral)

Brand-image generation via the `gen-image` CLI (`hummbl-gen`). The paid Higgsfield backend prompt enhancer is replaced by **local prompt assembly**: you build the final image-model prompt from the mode template below, chained with `brand-guidelines` tokens.

## Step 0 — Bootstrap

Shared rule: follow `~/.agents/rules/paid-external-generation-cli.md` when available.

1. Bootstrap per `gen-image` Step 0 (CLI path, key presence, never print key values).
2. Only run image generation after the operator explicitly requests product image creation in the current turn.
3. Privacy note: product photos / brand context will be sent to the selected third-party endpoint. If the product is unreleased/sensitive, confirm the provider choice with the operator first.

## UX Rules

1. Be concise. Print only the saved file paths in the final reply.
2. Detect language, respond in it. Mode names and flags stay English.
3. Ask at most 4 short labeled-option questions before submitting; skip anything obvious from context.
4. Polling is silent; deliver when files land.

## Modes

| Mode | When user wants… |
|---|---|
| `product_shot` | Product on neutral / studio / catalog background |
| `lifestyle_scene` | Product in real-world environment, hands, action, atmosphere |
| `closeup_product_with_person` | Tight crop with hands / partial face |
| `moodboard_pin` | Vertical 2:3 Pinterest-native aesthetic |
| `hero_banner` | Wide-format website / email / campaign header |
| `social_carousel` | 3–10 connected slides |
| `ad_creative_pack` | Coordinated static ad variants |
| `virtual_model_tryout` | Product worn/used by an AI-rendered model |
| `conceptual_product` | Surreal / CGI / levitating / splash |
| `restyle` | Transform an existing image's aesthetic (requires an image-capable model with image input — verify) |

Mode selection + tie-breakers: identical to `higgsfield-product-photoshoot` (pick by intent; platform/format keywords win; specific genre beats generic). Reuse that skill's interview flows (Type A–F) unchanged.

## Local prompt assembly (replaces backend enhancer)

Build the final prompt by filling the mode template. Vocabulary lives HERE, not on a vendor server — edit it as HUMMBL style evolves.

```
[SUBJECT]: <product, materials, packaging, label text verbatim>
[SET]: <mode-specific environment>
[LIGHT]: <mode-specific lighting>
[OPTICS]: <lens/framing>
[PALETTE]: <from brand-guidelines or operator>
[MOOD]: <from interview>
[OUTPUT]: <aspect ratio target, resolution, photographic realism>
```

Mode vocabulary:

- `product_shot` → SET: seamless studio backdrop (white/greige/brand tint); LIGHT: soft large-source key + subtle rim; OPTICS: 85mm macro, product 60–75% of frame, straight-on or 15° hero.
- `lifestyle_scene` → SET: named real environment (kitchen counter morning, café table, gym floor) with 2–3 believable props; LIGHT: natural window/motivated practicals; OPTICS: 35–50mm, shallow depth, product sharp.
- `closeup_product_with_person` → SET: hands/forearms/partial face only, skin texture real; LIGHT: directional beauty light; OPTICS: 100mm, tight crop on application moment.
- `moodboard_pin` → SET: vertical editorial composition, generous negative space, flat-lay or styled shelf; PALETTE: muted tonal layering; OUTPUT: 2:3.
- `hero_banner` → SET: wide cinematic stage, product right- or left-weighted, copy-space band retained; OUTPUT: 16:9 or 21:9.
- `social_carousel` → SET: one consistent visual system (same set/light/palette) across N frames, varied composition per slide; OUTPUT: 4:5 (IG) or 1:1.
- `ad_creative_pack` → SET: coordinated variants — same product truth, different hook composition per variant (straight-on, detail, in-use, offer badge space); OUTPUT: platform-native.
- `virtual_model_tryout` → SET: AI model archetype per interview (age range, styling, energy), product naturally worn/held; OPTICS: full/three-quarter/waist/closeup per interview; consent-safe: no real-person likenesses.
- `conceptual_product` → SET: surreal physics — levitation, frozen splash, sculptural pedestal; LIGHT: dramatic single source + color gels from palette; OPTICS: 50mm, crisp product.
- `restyle` → keep SUBJECT locked; swap SET/LIGHT/PALETTE/MOOD only (seasonal, aesthetic eras per interview Type D).

Brand chain: pull `[PALETTE]` and typography context from `brand-guidelines` (Grove/Verderer greens; Crimson Pro + Inter) unless the operator overrides.

## Generation

```bash
python ~/.agents/skills/gen-image/scripts/hummbl_gen.py image \
  --provider <p> --model <image-capable id, verified via models> \
  --prompt "<assembled template prompt>" \
  -n <count> [--out <prefix>] [--size <WxH>]
```

- `-n 3+` = variants. Vary `SET` details, angle, and lighting phrasing across calls for genuine variety (single call `n` may yield near-duplicates on some free models — prefer N separate submissions with tweaked prompts).
- Aspect ratio: many free image models honor only fixed sizes; check `--size` support for the chosen model and letterbox/crop afterwards if needed.
- For `restyle` and reference-driven work: verify the chosen model accepts image input; free support is sparse — if unavailable, say so and fall back to text-only mode or the paid `higgsfield-product-photoshoot` path.

## Delivering results

Bulleted list of saved file paths, one line per variant. No JSON, no model ids, no prompt text unless asked.

## What this skill does NOT do

- Does not call any paid backend or spend credits.
- Does not handle video, identity training, or virality analysis (see `gen-image` capability map → route to `higgsfield-*`).
- Does not paste the assembled prompt back at the user — they want the images.

## Skill Chains
- For prompt assembly needs a free text model -> `[reasoning-router]` (`python ~/bin/reasoning_router.py route`)
