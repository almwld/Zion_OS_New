---
name: design-tokens
description: HUMMBL design token system — colors, typography, spacing, status colors. Generate TCSS, QML tokens, ANSI codes from a single source of truth.
version: 0.1.0
execution-mode: advisory
argument-hint: "[tcss | qml | ansi \"color_name\" | colors | tokens]"
category: dev-tools
status: candidate
---
# HUMMBL Design Tokens

Single source of truth for fleet visual identity. Loads tokens from JSON, converts colors between OKLCH/hex/HSL/256-index, and generates output formats for every rendering surface (web CSS, Textual TCSS, Qt/QML, ANSI terminal).

## When to Use

- Generating TCSS for Textual TUI apps
- Generating QML token singletons for Qt/Quickshell apps
- Converting between color spaces (OKLCH, hex, HSL, 256-index)
- Getting ANSI escape codes for terminal colors
- Looking up fleet status colors (healthy, degraded, stale, critical, offline)

## Usage

```bash
[design-tokens] tcss                    # Generate Textual TCSS stylesheet
[design-tokens] qml                     # Generate Qt/QML FleetTokens.qml singleton
[design-tokens] ansi "accent"           # Get ANSI escape code for a token
[design-tokens] colors                  # List all color tokens
[design-tokens] tokens                  # List all token names
```

## Python API

```python
from hummbl_design_tokens import (
    TokenSystem, load_tokens,
    hex_to_oklch, hex_to_hsl, hex_to_256,
    oklch_to_hex, hsl_to_hex,
    golden_ratio_color, delta_e2000,
    luminance, contrast_ratio, closest_256,
    ansi_color, ansi_reset,
    generate_tcss, generate_qml_tokens,
    tincture_to_256, tincture_to_ansi,
)

# Load the token system
tokens = load_tokens()  # or TokenSystem()

# Generate output formats
tcss = generate_tcss(tokens)           # Textual TCSS
qml = generate_qml_tokens(tokens)      # Qt/QML singleton

# Color conversions
oklch = hex_to_oklch("#2563EB")
hex_str = oklch_to_hex(0.6, 0.2, 250)

# ANSI terminal colors
code = ansi_color("accent")            # "\033[38;5;75m"
reset = ansi_reset()                   # "\033[0m"

# Tincture to ANSI (heraldic tincture name → terminal color)
ansi = tincture_to_ansi("azure")       # ANSI blue
idx = tincture_to_256("or")            # 256-index gold
```

## Key Tokens

| Token | Value | Purpose |
|-------|-------|---------|
| `surfaceBase` | #0F0F12 | App background |
| `surfaceElevated` | #1A1A20 | Card background |
| `surfaceRaised` | #24242C | Hover/active |
| `accent` | #2563EB | Primary action |
| `textBody` | #E5E7EB | Body text |
| `textMuted` | #9CA3AF | Secondary text |
| `textFaint` | #6B7280 | Tertiary text |
| `border` | #333338 | Borders |
| `statusHealthy` | #10B981 | Green |
| `statusDegraded` | #F59E0B | Yellow |
| `statusCritical` | #EF4444 | Red |
| `statusStale` | #6B7280 | Gray |
| `statusOffline` | #4B5563 | Dark gray |

## Install

```bash
cd /work/active/oss/packages/python/hummbl-design-tokens
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-design-tokens/`
- **License**: Apache 2.0
- **Dependencies**: stdlib only
