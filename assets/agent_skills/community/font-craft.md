---
name: font-craft
description: Design, engineer, and compile bespoke vector typefaces and typography assets programmatically into installable TTF, OTF, and WOFF2 fonts with interactive specimen proof sheets.
version: 0.1.0
execution-mode: advisory
triggers:
  - "create a font"
  - "generate typeface"
  - "bespoke typography"
  - "custom font"
  - "font-craft"
  - "vector typography"
category: dev-tools
status: candidate
providers:
  required: [python]
  pip: [fontTools]
---
# Font Craft

`font-craft` is an agentic design and engineering capability for generating bespoke typefaces, logotypes, and icon fonts from mathematical primitives or SVG vectors into production-grade font binaries (`.ttf`, `.otf`, `.woff2`).

## Architectural Philosophy
1. **Geometric Precision Over Heuristics**: Letterforms are calculated mathematically using parametric stems, bowls, counters, and ascenders/descenders rather than hand-traced rasters.
2. **Standardized OpenType Compiles**: Fonts are compiled via `fonttools` directly into valid TrueType/OpenType tables with proper side-bearings and advance widths.
3. **Specimen Proof Gating**: Never output a font binary without generating an interactive HTML/SVG specimen proof sheet for visual validation across optical sizes, pangrams, and inverted contrast.
4. **Promotion Path**: Once mature and ready for external distribution, `font-craft` projects can be branded using novel etymological `.com` marks from the Brand Factory roster (`glyphura`, `typotect`, `charaktia`, `grammatect`).

## Workflow

### Phase 1: Metric & Aesthetic Specification
Establish font metrics:
- `units_per_em`: 1000 (default)
- `ascender`: 750 (or 800 for high-contrast stems)
- `cap_height`: 700
- `x_height`: 500
- `descender`: -200
- `stem_width`: Weight definition (e.g., 80 for regular, 160 for bold)

### Phase 2: Parametric Glyph Geometry
Define glyphs using Bézier pen operations or SVG path data. Stored in `scripts/parametric_engine.py` or imported from clean SVG files.

### Phase 3: Binary Compilation
Compile glyph dictionaries into OpenType font structures using `fonttools`:
```bash
python3 ~/.agents/skills/font-craft/scripts/build_font.py \
  --family "HummblSans" \
  --style "Regular" \
  --output ./HummblSans-Regular.ttf
```

### Phase 4: Verification & Specimen Sheet
Generate an HTML specimen sheet rendering the compiled font with live WebFont `@font-face` embeds:
```bash
python3 ~/.agents/skills/font-craft/scripts/preview_specimen.py \
  --font ./HummblSans-Regular.ttf \
  --output ./specimen.html
```
