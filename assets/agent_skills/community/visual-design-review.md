---
name: visual-design-review
description: Review visual design quality including hierarchy, composition, brand fit, polish, contrast, rhythm, balance, and perceived quality. Use for visual critique, UI polish, landing pages, dashboards, screenshots, or mockups.
version: 0.1.0
execution-mode: advisory
argument-hint: <url-file-or-screenshot>
category: dev-tools
status: candidate
---
# Visual Design Review

## Purpose

Answer: "Does this interface look intentional, polished, and on-brand?"

## Workflow

1. Inspect hierarchy: primary action, visual weight, scan path, information grouping.
2. Inspect composition: alignment, spacing rhythm, density, balance, contrast, whitespace.
3. Inspect brand fit: tone, typography, color, imagery, motion, distinctiveness.
4. Inspect finish: rough edges, default styles, inconsistent states, awkward breakpoints.
5. Rank fixes by user-visible impact and implementation cost.

## Output

```markdown
Visual Verdict: <strong | acceptable | rough | off-brand>
Top Findings:
- P1/P2/P3: <issue, impact, fix>
Fast Wins:
- <small fixes>
Deeper Changes:
- <larger direction changes>
```

## Rules

- Be specific; avoid generic "make it cleaner" advice.
- Preserve established product language unless asked to redesign.
- Pair critique with concrete visual fixes.
