---
name: brand-guidelines
description: Applies HUMMBL's official design system tokens (two-tone green system with Grove and Verderer accents, Crimson Pro and Inter typography) to any generated slide, PDF, HTML, or report. Use it when brand colors, style guidelines, visual formatting, voice/tone, or company design standards apply. Supersedes the retired `brand` skill.
version: 0.2.0
execution-mode: advisory
category: dev-tools
status: candidate
---
# HUMMBL Brand Styling & Design System (Grove & Verderer)

## Overview

Use this skill to access and apply HUMMBL's official brand identity, color tokens, typography rules, and aesthetic standards across all generated documents, presentation decks, web dashboards, and visuals.

**Keywords**: branding, corporate identity, visual identity, HUMMBL brand, Grove, Verderer, Verderer Light, Crimson Pro, Inter, JetBrains Mono, two-tone green system, premium styling

---

## Brand Guidelines

### Colors (Two-Tone Green System)

HUMMBL uses a premium two-tone green system designed for high visual appeal, professional trust, and readability:

**Core Palette:**

- **Grove (The Mark background)**: `#12633C` (RGB: 18, 99, 60)
  - Logo background, favicon background, OG image background. Dark anchor.
- **Verderer (The Interactive Accent)**: `#1B7A3D` (RGB: 27, 122, 61)
  - Buttons, links, badges, borders, text highlights. Lighter, warmer, touchable.
- **Verderer Light (Dark Mode Accent)**: `#34C26A` (RGB: 52, 194, 106)
  - Same as Verderer, but lifted for high-contrast on dark backgrounds.

**Supporting Colors:**

- **Amber (Action)**: `#B45309` (RGB: 180, 83, 9) - Secondary accent, call-to-actions, warning highlights
- **Success (Green)**: `#15803D` (RGB: 21, 128, 61) - Positive indicators, PASS statuses
- **Danger (Red)**: `#DC2626` (RGB: 220, 38, 38) - Alerts, FAIL/CRIT statuses

**Backgrounds (Light Theme):**

- **Primary Background**: `#FAFAFA` (RGB: 250, 250, 250)
- **Secondary Background**: `#FFFFFF` (RGB: 255, 255, 255)
- **Elevated Background**: `#F5F5F5` (RGB: 245, 245, 245)

**Backgrounds (Dark Theme):**

- **Primary Background**: `#0A0A0F` (RGB: 10, 10, 15)
- **Secondary Background**: `#111118` (RGB: 17, 17, 24)
- **Elevated Background**: `#1A1A24` (RGB: 26, 26, 36)

**Text Colors:**

- **Primary Text**: `#111827` (RGB: 17, 24, 39) - Clear, high-contrast readability
- **Secondary Text**: `#4B5563` (RGB: 75, 85, 99) - Clean secondary labels & metadata
- **Tertiary Text**: `#6B7280` (RGB: 107, 114, 128) - Muted labels & subtle dates

### Typography

- **Headings (Display, h1, h2, h3, h4)**: **Crimson Pro** (with Georgia fallback) - Premium, editorial serif
- **Body & UI Text**: **Inter** (with Segoe UI or Arial fallback) - High-legibility technical sans-serif
- **Data & Code Blocks**: **JetBrains Mono** (with Consolas fallback) - Distinct monospaced numbers, code, and badges

---

## Smart Implementation Rules

### 1. Slide & Presentation Layout (pptx)
- Backgrounds must default to **Primary Background (Dark Theme)** (`#0A0A0F`) with **Primary Background (Light Theme)** (`#FAFAFA`) for text, or vice versa if explicitly requested.
- Use **Verderer** (`#1B7A3D`) or **Verderer Light** (`#34C26A`) for primary interactive buttons, links, and borders.
- Slides must follow a spacious layout with generous margins (at least 10% safety margin on borders).
- Bold key numbers or metrics and set them to `36pt+` in **JetBrains Mono** colored in **Verderer Light** or **Verderer** for high-end presentation style.

### 2. Document & Spreadsheet Styles (docx, xlsx)
- Report titles must use the **Crimson Pro** font colored in **Grove** (`#12633C`) on a clean, light/elevated banner.
- Tables in spreadsheets must use **Grove** (`#12633C`) for headers with **White** text, and use **Success Green** (`#15803D`) / **Danger Red** (`#DC2626`) text alerts for status indicators.
- Borders should be thin and colored in **Tertiary Text** (`#6B7280`) or **Elevated Background** (`#F5F5F5`).

### 3. Web & HTML Dashboards (web-artifacts-builder)
- Always implement a premium, responsive interface featuring elegant borders using **Verderer** or **Verderer Light** accents.
- Hover states on buttons must have smooth transitions (`all 0.3s ease`) with a subtle shadow using the primary **Verderer** accent: `box-shadow: 0 0 15px rgba(27, 122, 61, 0.4)`.

---

## Technical Integration Details

### Font Class Mappings (python-pptx & docx)
- Headings: Set font name to `"Crimson Pro"`
- Body: Set font name to `"Inter"`
- Data/Code: Set font name to `"JetBrains Mono"`
- Fallbacks: Use `"Georgia"`, `"Arial"`, and `"Consolas"` respectively if system checks fail.

### Color Objects (python-pptx & docx RGBColor)
```python
from docx.shared import RGBColor

# Core Hummbl RGB Color Objects (Grove & Verderer System)
HUMMBL_GROVE          = RGBColor(18, 99, 60)    # Brand Anchor background
HUMMBL_VERDERER       = RGBColor(27, 122, 61)   # Interactive Accent
HUMMBL_VERDERER_LIGHT = RGBColor(52, 194, 106)  # Dark Mode Accent
HUMMBL_TEXT_PRIMARY   = RGBColor(17, 24, 39)    # Primary Text
HUMMBL_TEXT_MUTED     = RGBColor(107, 114, 128) # Tertiary Text
HUMMBL_SUCCESS        = RGBColor(21, 128, 61)   # Success state
HUMMBL_DANGER         = RGBColor(220, 38, 38)   # Danger state
```

---

## Voice & Tone

- Concise, direct, technically precise
- Use active voice
- Avoid buzzwords and filler ("leverage", "synergize", "cutting-edge")
- When explaining governance concepts, use plain language first, then the formal definition
- Humor is dry and understated, never forced

### Brand Story
- **Foundry** builds agents → **Crucible** proves them → **Arbiter** scores output
- Tagline: "Governance infrastructure for AI-native teams"

### Logo & Imagery
- Logo: logo text in Inter Bold with Verderer accent bar
- Files: `web/logo.svg` (stacked), `web/logo-horizontal.svg` (nav)
- No stock photography -- use diagrams, architecture visuals, data visualizations
- Avatar style: geometric/abstract (see `web/avatars/`)

---

## Design Tokens (Export Formats)

### CSS Custom Properties (Dark Theme — production hummbl.io)
```css
:root {
  --bg-primary: #0a0a0f;
  --bg-secondary: #111118;
  --bg-elevated: #1a1a24;
  --text-primary: #f9fafb;
  --text-secondary: #d1d5db;
  --text-tertiary: #9ca3af;
  --accent-green: #1b7a3d;
  --accent-green-hover: #166432;
  --accent-warm: #b45309;
  --accent-success: #15803d;
  --accent-danger: #dc2626;
  --border-subtle: rgba(255, 255, 255, 0.08);
  --border-prominent: rgba(52, 194, 106, 0.3);
  --font-sans: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --font-mono: "JetBrains Mono", "SF Mono", Consolas, monospace;
  --font-serif: "Crimson Pro", Georgia, "Times New Roman", serif;
}
```

### JSON Tokens
```json
{
  "color": {
    "grove": "#12633c",
    "verderer": "#1b7a3d",
    "verderer_light": "#34c26a",
    "bg": { "light": { "primary": "#fafafa", "secondary": "#ffffff", "elevated": "#f5f5f5" }, "dark": { "primary": "#0a0a0f", "secondary": "#111118", "elevated": "#1a1a24" } },
    "text": { "primary": "#111827", "secondary": "#4b5563", "tertiary": "#6b7280" },
    "accent": { "green": "#1b7a3d", "green_hover": "#166432", "green_dark": "#34c26a", "warm": "#b45309", "success": "#15803d", "danger": "#dc2626" },
    "border": { "subtle_light": "rgba(0,0,0,0.08)", "subtle_dark": "rgba(255,255,255,0.08)", "prominent": "rgba(52,194,106,0.3)" }
  },
  "font": { "sans": "Inter", "mono": "JetBrains Mono", "serif": "Crimson Pro" }
}
```

---

## Brand Audit Checklist

When auditing a file/project for brand compliance:
1. Check all hardcoded colors -- should use CSS variables
2. Check font-family declarations -- should use tokens
3. Check tone of copy -- should match voice guidelines
4. Check heading hierarchy -- semantic and consistent
5. Check accent usage -- Verderer for primary actions, Amber for emphasis/warnings
6. Check contrast ratios (WCAG AA) for both light and dark themes
7. Check that JetBrains Mono is used ONLY for code, metrics, and data values, not body text
8. Check that Grove (`#12633c`) is used for logo/favicon/OG backgrounds, not Verderer
9. Report findings as a table: `| Issue | File:Line | Fix |`

---

## Constraints

- These tokens are derived from the production site (hummbl.io) and `content/_BRAND_GUIDE.md`
- If the live site tokens change, update this skill to match
- Brand applies to: public-facing pages, slide decks, PDFs, dashboards, and branded output
- Brand does NOT apply to: internal tools, terminal output, code comments
