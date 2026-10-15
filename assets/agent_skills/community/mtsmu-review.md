---
name: mtsmu-review
description: Bug-first review for code, configs, scripts, and operational changes. Use when the user asks for a review, risk assessment, or merge-readiness check and wants findings prioritized by severity, supported by evidence, with testing gaps and residual risks called out before any summary.
version: 0.1.0
execution-mode: remedial
argument-hint: "<file, PR, or change to review>"
category: dev-tools
status: candidate
---
# MTSMU Review

## Quick Start

- Findings first.
- Prioritize bugs, regressions, unsafe assumptions, and missing tests.
- Support every finding with concrete evidence from the diff, code path, command output, or behavior.
- If there are no findings, say that explicitly and still note residual risks.

## Review Workflow

1. Inspect the change surface and likely blast radius. Prioritize env resolution, defaults, config precedence, auth, ports, and runtime boundary changes before lower-risk refactors or docs.
2. Look for correctness failures before style issues.
3. Check defaults, env resolution, boundary conditions, and tests.
4. Verify whether the change actually proves the intended behavior.
5. Write findings ordered by severity.

## Output Contract

Use this shape:

- `Findings`
- `Open questions`
- `Residual risk`
- `Change summary`

Keep `Findings` first. If there are none, say `No findings` first, then note any testing gaps.

## Severity Rules

- `high`: likely bug, data loss, broken runtime path, unsafe security or ops behavior
- `medium`: meaningful regression risk or incomplete verification
- `low`: minor robustness or maintainability issue with limited impact

## Review Patterns

High-value checks: rank review targets by bug density not recency, prefer env/config/default resolution changes over import-only refactors, verify the code path actually runs where claimed, check if defaults are treated as explicit config, confirm tests cover failure modes not just happy path, verify the verification command proves real behavior.

Common traps: summarizing the change before identifying risk, treating passing unit tests as full integration proof, missing config precedence bugs, ignoring dirty-worktree interactions.

No-findings standard: say `No findings` only after inspecting the diff directly, considering risky paths, and reviewing available tests. Then still note missing integration coverage, unexercised external dependencies, and unverified assumptions.
