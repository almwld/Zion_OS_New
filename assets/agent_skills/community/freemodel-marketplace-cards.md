---
name: freemodel-marketplace-cards
description: Marketplace-ready product visuals (main image, secondaries, A+ modules) via free endpoints with locally-assembled marketplace prompt templates. Vendor-neutral counterpart to higgsfield-marketplace-cards for free-tier budgets.
version: 0.1.1
execution-mode: side_effecting
argument-hint: "[--scope main|product-images|aplus|full-set] [product description]"
category: hummbl-research
status: candidate
---

<!-- SoT: profile (~/.agents/skills/). Vendor-neutral port of higgsfield-marketplace-cards (v0.3.0). Canonical only; not in any lean set. -->
# freemodel-marketplace-cards

Port of `higgsfield-marketplace-cards`. Higgsfield keeps marketplace rules/templates private server-side; here the template system lives in this file and prompt enhancement runs on a free text model, rendering via `freemodel-generate` (read its `references/provider-matrix.md`).

## Step 0 — Bootstrap

1. Follow `freemodel-generate` bootstrap (HF token for images + one text key). Probe routes.
2. If operator wants Higgsfield's private marketplace enhancer + `nano_banana_2` and has credits, route to `higgsfield-marketplace-cards` instead.
3. Network/state guardrail: only submit after explicit marketplace-image request this turn.

## UX Rules

1. Respond in the user's language.
2. At most one concise confirmation question before running.
3. Prefer a product image/description with clear product details before proceeding.
4. Final answer: saved file paths + short labels only.

## Scope Selection (ported unchanged)

| Scope | Creates |
|---|---|
| `main` | 1 marketplace main image |
| `product-images` | main image + 5 secondary images |
| `aplus` | main image + 7 A+ modules |
| `full-set` | main image + 5 secondary images + 7 A+ modules |

Custom subsets via repeated `--asset`:

`main_image`, `infographic`, `multi_angle`, `detail_shot`, `lifestyle`, `whats_in_box`, `aplus_hero_banner`

## Asset templates (local replacement for the private backend)

Each asset gets its own prompt scaffold — fill via one free text-model call per asset (role: "Amazon marketplace merchandiser; output one dense image prompt, no preamble"):

- **main_image** — hero on white/brand background, product 60%+ of frame, retail-compliant (no badges/text unless asked)
- **infographic** — product + callout features; note: free models render text imperfectly — prefer composing text overlays locally (Pillow) over generated text
- **multi_angle** — consistent lighting across angles; front / three-quarter / side / back / top
- **detail_shot** — macro crop, texture/material emphasis
- **lifestyle** — in-context use, ambient brand palette
- **whats_in_box** — flat-lay kit layout, all components visible
- **aplus_hero_banner** — wide 16:9 (1464px+), campaign mood

## Workflow

1. **Collect.** Product details, scope, brand tokens (`brand-guidelines` for hummbl work).
2. **Expand scope → asset list** per tables above.
3. **Assemble prompts** (text model, per-asset scaffold).
4. **Render** each via FLUX.1-schnell (HF Router). Marketplace purity rule: Amazon main images must be pure white background — enforce in prompt.
5. **Post locally when needed** — text overlays/callouts via Pillow (text-in-image from free models is unreliable).
6. **Save + deliver.** `cards_<scope>_<asset>_<NN>.png`. Report paths only.

## Boundary vs the paid original

Free tier cannot match `nano_banana_2` on dense infographic typography. For text-heavy A+ modules, generate the base visual free, then compose text with Pillow/canvas-design for marketplace-compliant output.

## Skill Chains

### Mandatory

- Complete the `freemodel-generate` bootstrap and provider-route probes before
  rendering, and submit marketplace-image requests only when the operator has
  explicitly requested them in the current turn.
- Use the selected asset scope, save outputs using the documented naming
  pattern, and report saved paths rather than raw image bytes.

### Advisory

- For prompt enhancement runs on a free text model -> `[reasoning-router]` (`python ~/bin/reasoning_router.py route`)

## Authority

- **All agents:** May collect product details and prepare local prompt
  scaffolds. They may submit free-tier marketplace renders only after the
  documented bootstrap and a current-turn explicit marketplace-image request.
- **Operator:** May request marketplace images or explicitly choose the paid
  Higgsfield route when credits are available.
