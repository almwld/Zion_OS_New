---
name: synthesis-mode
description: Compress exploration into action — every output is a decision, recommendation, or not-yet.
version: 0.1.0
execution-mode: advisory
status: approved
category: fleet-ops
protected_variable: decision_quality
composition:
  - deep-research-mode
  - economics-mode
conflicts: []
---

# Synthesis-Mode Skill

## Invocation

```
/synthesis-mode
```

Or "what should we do?"

## What This Skill Does

Activates synthesis-mode for converging exploration into action. Compresses
multi-source input into decisions, recommendations with confidence levels,
or honest "not yet" statements with missing-information lists.

## Inputs

- **Input sources**: What research/findings/experiments to synthesize?
- **Decision needed**: What question needs to be answered?
- **Deadline**: When does the decision need to be made?

## Output

```markdown
# Synthesis

**Date**: YYYY-MM-DD
**Input sources**: <what was synthesized>
**Decision question**: <what needs to be answered>

## Output type: decision / recommendation / not-yet

### Decision/Recommendation
<what to do>

### Confidence: HIGH / MEDIUM / LOW
<reasoning for confidence level>

### Reasoning
<why this is the right call>

### Uncertainties
<what we don't know>

### Minority Views
<dissenting perspectives, if any>

### Reversibility: reversible / irreversible

### Missing Information (if not-yet)
<what's needed before we can decide>

## Receipt
<synthesis-mode receipt per doctrine template>
```

## Composition

- **synthesis-mode + deep-research-mode**: Research-then-decide pipeline. Deep-research gathers; synthesis decides.
- **synthesis-mode + economics-mode**: Financial decision synthesis. Economics-mode provides options; synthesis picks.

## Cost

~10K-25K tokens per session (depends on number of input sources and complexity).
