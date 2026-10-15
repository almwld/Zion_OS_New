---
name: ui-design-system
description: Define, audit, or extend UI design systems including tokens, components, states, spacing, typography, responsive behavior, and governance. Use when the user asks for component-system consistency, design tokens, UI standards, or reusable interface rules.
version: 0.1.0
execution-mode: advisory
argument-hint: <surface-or-component-system>
category: governance-compliance
status: candidate
---
# UI Design System

## Purpose

Answer: "Is the UI system coherent, reusable, and governable?"

## Workflow

1. Inventory primitives: colors, typography, spacing, radii, elevation, motion, icons, layout grids.
2. Inventory components: buttons, inputs, navigation, cards, dialogs, tables, feedback states.
3. Check state coverage: default, hover, focus, active, disabled, loading, empty, error, success.
4. Check responsive rules and density variants.
5. Identify drift: one-off styles, duplicate components, inconsistent naming, inaccessible token choices.
6. Recommend system changes as tokens, component APIs, usage rules, and migration steps.

## Output

```markdown
Design System Status: <coherent | drifted | missing>
Tokens: <covered/gaps>
Components: <covered/gaps>
States: <covered/gaps>
Responsive: <covered/gaps>
Top Fixes: <ranked list>
Governance: <owner/rules/checks>
```

## Rules

- Prefer system-level fixes over one-off visual patches.
- Keep implementation details aligned with the existing stack and design language.
- Do not invent a new visual language when the repo already has one unless the user asks.
