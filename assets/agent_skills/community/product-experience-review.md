---
name: product-experience-review
description: Combined UI/UX release-gate review for product surfaces. Use when deciding whether a feature, page, flow, or release is acceptable from interface quality and user-success perspectives.
version: 0.1.0
execution-mode: advisory
argument-hint: <surface-flow-or-release>
category: backend-infra
status: candidate
---
# Product Experience Review

## Purpose

Answer: "Is this product experience good enough to ship?"

This combines UI quality, UX task success, accessibility, content clarity, performance perception, and release risk.

## Workflow

1. Define target user, surface, and release decision.
2. Run targeted checks:
   - UI quality: `visual-design-review` or `ui-audit`.
   - Flow quality: `interaction-design` or `ux-audit`.
   - Accessibility: `a11y-audit`.
   - Copy: `content-design`.
   - Implementation match: `design-qa` when a spec exists.
   - Performance perception: `perf-profile` or `performance-review` when relevant.
3. Rank findings by release impact.
4. Decide:
   - `SHIP`
   - `SHIP_WITH_NOTES`
   - `FIX_FIRST`
   - `UNKNOWN`

## Output

```markdown
Product Experience Verdict: <SHIP | SHIP_WITH_NOTES | FIX_FIRST | UNKNOWN>
Surface: <surface>
User Goal: <goal>
Evidence: <checks run>
Findings:
- P1/P2/P3: <issue, impact, fix>
Release Notes:
- <ship notes or blockers>
```

## Rules

- Use this as a release gate, not a broad design brainstorm.
- A P1 task failure means `FIX_FIRST`.
- If no user goal is known, verdict is at most `UNKNOWN` or `SHIP_WITH_NOTES`.
