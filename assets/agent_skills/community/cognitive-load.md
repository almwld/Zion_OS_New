---
name: cognitive-load
description: Estimate cognitive load of UI elements using task complexity, information density, and Hick's law
version: 0.1.0
execution-mode: advisory
argument-hint: "<ui-path-or-screenshot> [--method hick|sweller|nasa-tlx]"
category: fleet-ops
status: candidate
---
# cognitive-load | UI Cognitive Load Estimation

## When to Use
- Evaluating whether a UI overwhelms users with too many choices
- Comparing design alternatives for mental effort requirements
- Identifying high-load screens before user testing
- Justifying simplification recommendations with quantitative estimates

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: UI file path (HTML, JSX, Figma export) or screenshot
- `--method hick|sweller|nasa-tlx`: estimation method (default `hick`)
- If screenshot, use vision to identify interactive elements and text density

### 2. Extract UI Elements
- Parse DOM tree or analyze screenshot for:
  - Interactive elements (buttons, links, inputs, toggles)
  - Text blocks and their reading length
  - Navigation depth and branching factor
  - Form fields and required vs optional markers
- Count distinct choices at each decision point

### 3. Apply Estimation Method
- **Hick's Law**: `RT = a + b * log2(n + 1)`; sum RT across decision points; flag if total > 2s
- **Sweller's**: score intrinsic (content complexity), extraneous (bad layout/split-attention), germane (schema building) on 1-10; flag if extraneous > intrinsic
- **NASA-TLX**: estimate mental demand, effort, frustration (1-100 each); weighted average = overall TLX

### 4. Identify Load Hotspots
- Rank UI regions by cognitive load contribution
- Flag elements with high choice count or dense information
- Identify split-attention patterns (multiple panels requiring simultaneous focus)

### 5. Generate Recommendations
- Reduce choices via progressive disclosure or smart defaults
- Consolidate related information to reduce split-attention
- Simplify labels and group related actions
- Prioritize changes by load reduction impact

## Output Format

```
cognitive-load | <ui-path>

## Method: <hick|sweller|nasa-tlx>

## UI Summary
- Screen: dashboard | Interactive elements: 14 | Text blocks: 8
- Navigation depth: 3 | Decision points: 5

## Hick's Law Analysis
| Decision Point  | Choices | RT (ms) |
|-----------------|---------|---------|
| Main nav        | 7       | 680     |
| Filter dropdown | 12      | 920     |
| Action buttons  | 5       | 530     |
| Total           |         | 2,130   |

## Load Score
- Overall: 72/100 (HIGH) | Intrinsic: 6 | Extraneous: 8 | Germane: 4

## Hotspots & Recommendations
1. Filter dropdown (12 choices) -- reduce to 5 with "more" expansion
2. Dashboard panels (split-attention) -- consolidate or tab
- Group action buttons into primary + overflow; add smart defaults

## Verdict
HIGH_LOAD / MODERATE / LOW_LOAD
```

## Skill Chains
- After load estimation -> `[ux-audit]` for full UX review
- After load estimation -> `[a11y-audit]` for accessibility interaction
- Before design refinement -> `[interaction-design]` to implement changes
