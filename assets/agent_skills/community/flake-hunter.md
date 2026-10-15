---
name: flake-hunter
description: Identify flaky tests by pattern -- re-run suspicious tests, categorize causes, suggest fixes
version: 0.1.0
execution-mode: remedial
argument-hint: "[--runs N] [--target TEST_PATH] [--action hunt|report]"
category: dev-tools
status: candidate
---
# Flake Hunter

Systematically identify and categorize flaky tests by re-running suspicious tests multiple times, analyzing failure patterns, and classifying root causes (timing, shared state, order dependency, resource contention). Produces actionable fix recommendations.

## When to Use
- Tests intermittently fail in CI but pass locally
- After a CI run with unexplained failures that pass on retry
- Periodic flake audit to keep the test suite reliable
- Before marking a test suite as "stable" for gating deploys

## Execution
1. Parse `$ARGUMENTS` for `--runs` (default: 10), `--target` test path, and `--action` (default: hunt).
2. For `hunt`: run the target tests N times, recording pass/fail for each run.
3. Classify each test by flake rate: SOLID (0% fail), SUSPECT (1-20% fail), FLAKY (21-80% fail), BROKEN (81%+ fail).
4. For flaky tests, analyze failure output for common patterns: timing-related keywords (sleep, timeout, race), state keywords (setUp, tearDown, tmp, fixture), order-dependent imports or shared globals.
5. Categorize each flake: TIMING (race condition, slow CI), STATE (shared mutable state), ORDER (test order dependency), RESOURCE (file, port, network), RANDOM (non-deterministic input).
6. For `report`: summarize historical flake data from `_state/flake-history.jsonl`.
7. Suggest specific fixes per category (add retry, isolate state, mock time, pin random seed).

## Output Format
```
Flake Hunter | hunt | 10 runs | tests/test_scheduler.py

| Test | Pass | Fail | Rate | Category | Root Cause |
|------|------|------|------|----------|------------|
| test_schedule_timing | 8 | 2 | 20% | TIMING | sleep(0.1) race |
| test_concurrent_write | 6 | 4 | 40% | STATE | shared tmp file |
| test_api_response | 10 | 0 | 0% | SOLID | -- |

Fixes:
1. test_schedule_timing: Replace sleep(0.1) with event-based wait or mock time
2. test_concurrent_write: Use unique tmp directory per test (tmpdir fixture)

Flake Score: 2/3 tests stable (67%)

Next action: Apply fixes and re-run with `[flake-hunter] --runs 20` to verify.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Flakes categorized | `[debug-test]` to fix the specific flaky test |
| Inherits context from | `[ci-monitor]` for historical flake rate data |
| Flake rate improved | `[ci-monitor]` to update tracking |
