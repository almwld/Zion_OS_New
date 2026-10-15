---
name: mtsmu-debug
description: "Evidence-first debugging for failures, regressions, flaky tests, broken scripts, and runtime issues: reproduce, isolate root cause, patch narrowly, verify, and receipt."
version: 0.1.0
execution-mode: advisory
argument-hint: "<failing test, broken script, or error description>"
category: dev-tools
status: candidate
---
# MTSMU Debug

## Quick Start

- Reproduce before theorizing.
- Prefer the smallest failing scope that still captures the bug.
- Distinguish symptom, trigger, root cause, and fix.
- Patch the narrowest layer that resolves the real cause.
- Verify behavior directly and add a regression test when practical.

## Workflow

1. Reproduce: capture the failing command, test, request, or environment signal.
2. Isolate: reduce the failure to the smallest file, function, path, or config surface that still fails.
3. Instrument: add the least invasive probe needed -- targeted tests, temporary prints, diff inspection, env tracing, process checks, or request stubs.
4. Patch: fix the root cause, not only the visible symptom.
5. Verify: re-run the failing case, then the nearest relevant suite.
6. Receipt: report the root cause, the fix, what verified it, and any remaining uncertainty.

## Decision Rules

- If the first explanation is not tested, treat it as a hypothesis.
- If a fix passes one check but contradicts another signal, keep investigating.
- If a failure is caused by weak telemetry, fix the telemetry before trusting the diagnosis.
- If a bug repeats across tasks, consider whether it should become a reusable script, helper, or skill.

## Output Contract

Keep reports short and auditable:

- `Repro`
- `Root cause`
- `Fix`
- `Verification`
- `Residual risk`
- `Confidence`

## Debug Patterns

Reliable sequence: reproduce with one command, tighten scope until one small surface fails, change one variable at a time, prefer direct evidence over stack-ranked guesses, verify at two levels (local case + nearby suite).

Common traps: fixing a symptom while root cause remains, trusting stale telemetry, counting wrapper processes as the target, treating default config as explicit config, stopping after one green check when integration behavior is unverified.

When to escalate: missing credentials or external infra, conflicting user changes in the same surface, reproduction impossible with available local context.

Validation hygiene: use `bash -n` for shell syntax (not Python compilation), use language-native tests for the language being edited, verify claimed artifacts exist on disk.
