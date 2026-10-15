---
name: interaction-design
description: Design or review user flows, interaction states, transitions, feedback loops, empty/loading/error paths, and task completion behavior. Use when the user asks about flows, UX states, onboarding, forms, wizards, or interaction friction.
version: 0.1.0
execution-mode: advisory
argument-hint: <flow-or-feature>
category: dev-tools
status: candidate
---
# Interaction Design

## Purpose

Answer: "Can users move through this flow without confusion or dead ends?"

## Workflow

1. Define the user goal and success condition.
2. Map the happy path and critical alternate paths.
3. Check system feedback at each step: confirmation, progress, loading, errors, recovery.
4. Check decision points: labels, affordances, defaults, validation, irreversible actions.
5. Check edge cases: empty state, partial state, permission denied, timeout, duplicate action.
6. Recommend flow changes, state copy, and component behavior.

## Output

```markdown
Flow Verdict: <clear | usable-with-gaps | confusing | blocked>
User Goal: <goal>
Happy Path: <steps>
Friction Points: <ranked list>
Missing States: <empty/loading/error/success/etc>
Recommended Flow: <concise path>
```

## Rules

- Optimize for task completion, not just screen aesthetics.
- Surface destructive or hard-to-reverse actions explicitly.
- Include microcopy when it changes user comprehension.
