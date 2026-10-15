---
name: gen-marketplace-cards
description: Marketplace-ready product listing visuals (main image, secondaries, A+ modules) on free vendor-neutral endpoints via gen-image. Public marketplace rules encoded as local templates — no paid backend enhancer.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--scope main|product-images|aplus|full-set] [prompt]"
category: hummbl-research
status: candidate
---
# Gen Marketplace Cards (vendor-neutral)

Create marketplace listing visual sets with the `gen-image` CLI (`hummbl-gen`). The paid Higgsfield backend enhancer (private marketplace rules/templates) is replaced by **local templates encoded from publicly documented marketplace listing requirements**.

## Step 0 — Bootstrap

Shared rule: follow `~/.agents/rules/paid-external-generation-cli.md` when available.

1. Bootstrap per `gen-image` Step 0 (CLI path, keys present, never print key values).
2. Only run generation after the operator explicitly requests marketplace image creation in the current turn.
3. Product photos + listing context go to a third-party endpoint; confirm provider if the product is unreleased/sensitive.

## UX Rules

1. Respond in the user's language; flags stay English.
2. At most one concise confirmation question before running.
3. Prefer a product reference image. Text/URL-only is fine when product details are clear.
4. You assemble prompts locally from the templates below — never submit a raw user sentence as the final prompt.
5. Final answer: saved file paths with short labels. No JSON, no model ids.

## Scope Selection

Identical bundles to the paid skill:

| Scope | Creates |
|---|---|
| `main` | 1 marketplace main image |
| `product-images` | main image + 5 secondary images |
| `aplus` | main image + 7 A+ modules |
| `full-set` | main image + 5 secondary images + 7 A+ modules |

Custom subsets via repeated asset picks:

`main_image`, `infographic`, `multi_angle`, `detail_shot`, `lifestyle`, `whats_in_box`, `aplus_hero_banner`, `aplus_pain_points`, `aplus_features`, `aplus_ingredients`, `aplus_efficacy`, `aplus_how_to_use`, `aplus_endorsement`

## Local asset templates (public marketplace rules)

**`main_image`** — marketplace-compliant hero: product ONLY, 85%+ of frame, pure white seamless background (RGB 255,255,255), even shadowless studio light, straight-on or 15° hero, 85–100mm, razor-sharp focus. NO text, logos, watermarks, badges, props, or borders (main-image disqualification rules on major marketplaces). 1:1.

**Secondaries:**
- `infographic` — product center, 3–4 key benefits as clean icon+label clusters, brand palette, legible sans-serif (Inter), generous margins, 1:1.
- `multi_angle` — front / three-quarter / side / back coordinated row or 2×2 grid, identical lighting across angles, 1:1.
- `detail_shot` — macro on the signature feature (texture, mechanism, finish), shallow depth, 1:1.
- `lifestyle` — product in believable use environment, natural light, human presence optional (hands only), 1:1.
- `whats_in_box` — flat-lay of full contents, kraft or brand-tinted surface, top-down, labeled spacing, 1:1.

**A+ modules** (wide 3:1 or 16:9 banner slots):
- `aplus_hero_banner` — brand mood banner, product right-weighted, copy space left, palette from `brand-guidelines`.
- `aplus_pain_points` — problem/solution split, 2–3 pain icons left, resolved state right.
- `aplus_features` — product center, radial callouts to 3–4 features.
- `aplus_ingredients` / `aplus_efficacy` — clean grid of ingredient/element chips around product; efficacy adds simple before/after or stat visual (no fabricated numbers — leave stat slots for the operator's real data).
- `aplus_how_to_use` — 3–4 sequential steps, numbered, minimal pictogram style.
- `aplus_endorsement` — tasteful quote-banner layout with empty quote area for the operator's real quote (never fabricate testimonials).

Rules for ALL assets: same palette/lighting system across the set (locked visual system); no invented certifications, awards, ingredient claims, or review stars — text slots stay literal placeholders the operator fills with verified content.

## Generation

One `image` call per asset (free models return one strong image per call; run sequentially, vary seeds via prompt phrasing):

```bash
python ~/.agents/skills/gen-image/scripts/hummbl_gen.py image \
  --provider <p> --model <verified image-capable id> \
  --prompt "<template-filled prompt for this asset>" \
  --out listing-main_image
```

- Filename prefix per asset id (`--out listing-<asset>`); deliver as a labeled list.
- Long text rendering: free models mangle dense on-image text. For infographic/A+ text-heavy modules, either (a) generate art with copy-space and composite real text locally (chain `hummbl-branded-artifacts`), or (b) keep on-image text to ≤5 words. Prefer (a) for compliance-heavy marketplaces.
- `--scope` is a planning concept here (no backend bundle command): expand it into per-asset calls yourself and tell the operator the count before submitting.

## Delivery

```
Marketplace cards ready (full-set = 13 assets):
- Main image: C:\...\listing-main_image-1.png
- Infographic: C:\...\listing-infographic-1.png
- ...
```

## What this skill does NOT do

- No paid backends, no credits, no private vendor templates — rules above are public marketplace listing requirements.
- No fabricated claims, stats, or testimonials — placeholders only.
- No video/identity/virality work (see `gen-image` capability map).

## Skill Chains
- For prompt assembly needs a free text model -> `[reasoning-router]` (`python ~/bin/reasoning_router.py route`)
