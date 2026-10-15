---
name: auto-ship
description: "Alias for the lfg skill (compound-engineering plugin). Full autonomous shipping pipeline: plan, implement, review, commit, push, open PR, watch CI to green — hands-off with no check-ins. Use this when you want the autonomous ship pipeline but need a self-documenting skill name."
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[feature description; optionally assign planning and/or implementation to a model or harness]"
category: dev-tools
status: candidate
---
# auto-ship

**This is an alias for the `lfg` skill.** Invoke `lfg` with the same arguments.

The `lfg` skill (compound-engineering plugin) runs the full autonomous shipping pipeline end-to-end, hands-off with no check-ins: plan, implement, review and fix, commit, push a branch, open a PR, and watch CI to green.

## Why this alias exists

`lfg` is an opaque name (internet slang for "let's fucking go"). Agents scanning the skill catalog see `lfg` and don't know what it does without loading its SKILL.md. `auto-ship` is a self-documenting name that appears alongside `lfg` in the catalog, making the autonomous shipping pipeline discoverable by name.

## Usage

```
/auto-ship <feature description>
/auto-ship "add user authentication with JWT"
/auto-ship "fix the flaky integration test, plan with opus"
```

All arguments pass through to `lfg` unchanged.

## When to use

- Operator explicitly wants hands-off autonomous shipping to an open PR
- The full plan → implement → review → commit → push → PR → CI pipeline is wanted
- The operator says "ship it", "auto-ship", "autonomous ship", or "lfg"

## When NOT to use

- In-the-loop work where the operator reviews each step — use `ce-plan`, `ce-work`, `ce-debug`, or `ce-commit-push-pr` instead
- Operator-visible step-by-step shipping — use the native `ship` skill instead

## Relationship to `ship` (native)

- `ship` (native): test → scan → PR → merge → tag with operator-visible steps
- `auto-ship` / `lfg` (plugin): same pipeline but fully autonomous — pushes and opens a PR without stopping

## Skill Chains

### Mandatory

- None — this skill is self-contained.

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction
- **T3 (Medium)**: MUST get operator approval before execution
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
