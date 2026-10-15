---
name: design-qa
description: Verify implemented UI against design intent, specifications, screenshots, or acceptance criteria. Use before release, after frontend changes, or when checking visual/interaction regressions.
version: 0.1.0
execution-mode: advisory
argument-hint: <implementation-and-spec>
category: dev-tools
status: candidate
---
# Design QA

## Purpose

Answer: "Does the shipped implementation match the intended design and interaction behavior?"

## Workflow

1. Establish reference: design file, screenshot, spec, acceptance criteria, or prior version.
2. Inspect implementation in the browser when possible.
3. Compare layout, spacing, typography, color, component states, responsiveness, and interactions.
4. Check accessibility basics: focus, labels, keyboard reachability, contrast.
5. Classify differences:
   - `BLOCKER`: breaks task or brand-critical surface.
   - `FIX`: visible mismatch or missing state.
   - `ACCEPT`: acceptable implementation variance.
6. Provide exact reproduction steps and file/component pointers when available.

## Output

```markdown
Design QA Verdict: <pass | pass-with-fixes | fail>
Reference: <spec/screenshot/url>
Tested Surface: <url/component>
Findings:
- BLOCKER/FIX/ACCEPT: <issue, evidence, correction>
Release Decision: <ship | fix first | unknown>
```

## Rules

- Do not require pixel perfection unless the surface demands it.
- Focus on user-visible mismatches and missing states.
- If no reference exists, use `visual-design-review` or `ui-audit` instead.
