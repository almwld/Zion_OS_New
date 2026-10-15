---
name: color-contrast
description: Check and suggest color contrast ratios for WCAG compliance. [Maps to P9.]
version: 0.1.0
execution-mode: advisory
argument-hint: <color1> <color2> or <file-or-url>
category: governance-compliance
status: candidate
---
# Color Contrast Checker Command

Analyze color combinations for WCAG 2.1 AA/AAA compliance. Checks foreground/background contrast ratios and suggests accessible alternatives when needed.

## When to Use
- Implementing or reviewing UI color schemes
- When user mentions accessibility color requirements
- During design system development
- Testing color accessibility in existing components

## Execution

### 1. Parse Input
Handle different input formats:
- Two colors: `<color1> <color2>` (hex, rgb, rgba, hsl, or named colors)
- File/URL: Extract color usage from CSS/HTML
- Interactive mode: Prompt for color values

### 2. Calculate Contrast Ratio
Compute luminance and contrast ratio using WCAG formula:
- Convert colors to linear RGB
- Calculate relative luminance for each color
- Compute contrast ratio: (L1 + 0.05) / (L2 + 0.05) where L1 is lighter
- Determine compliance levels:
  - AA text: ≥ 4.5:1
  - AA large text: ≥ 3:1  
  - AAA text: ≥ 7:1
  - AAA large text: ≥ 4.5:1

### 3. Generate Accessible Alternatives
When non-compliant:
- Suggest lighter/darker variants that meet AA/AAA
- Provide multiple options preserving hue when possible
- Calculate exact adjustment needed for compliance

### 4. Output Results
Present analysis with visual indicators and actionable suggestions.

## Output Format
```
Color Contrast | <input>
════════════════════════════
Foreground: <color> (#<hex>)
Background: <color> (#<hex>)

## Contrast Analysis
- Relative Luminance: <fg-lum> / <bg-lum>
- Contrast Ratio: <ratio>:1

## WCAG Compliance
- AA Text: <pass/fail> (≥ 4.5:1)
- AA Large Text: <pass/fail> (≥ 3:1)
- AAA Text: <pass/fail> (≥ 7:1)
- AAA Large Text: <pass/fail> (≥ 4.5:1)

## Accessible Alternatives
<if compliant>
✅ Current combination meets all selected criteria

<if not compliant>
To achieve AA text (4.5:1):
  Option 1: Lighten background to #<hex>
  Option 2: Darken foreground to #<hex>
  Option 3: Adjust both: fg #<hex>, bg #<hex>

To achieve AAA text (7:1):
  Option 1: Lighten background to #<hex>
  Option 2: Darken foreground to #<hex>
  Option 3: Adjust both: fg #<hex>, bg #<hex>

## Visual Preview
<color-block> Text on <color-block> Background

## Recommendations
USE CASE: <suggested-application>
NEXT: Apply suggested colors and verify with [a11y-audit]
```

## Base120 Context
- Primary: **P9** (Cultural Adaptation - ensuring visual accessibility)
- Related: **DE5** (Finding vital few adjustments), **IN8** (Verifying contrast claims)

## After Completion
Naturally chains to: Apply changes and run `[a11y-audit]` for full page verification
