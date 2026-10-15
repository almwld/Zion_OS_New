---
name: test-trends
description: Track test count, pass rate, duration, and flake rate over time from CI and git history
version: 0.1.0
execution-mode: advisory
argument-hint: "[--days N] [--flakes] [--slowest]"
category: dev-tools
status: candidate
---
# [test-trends]

## When to Use
- Weekly quality review to spot regression trends
- Before release to verify test health trajectory
- Investigating flaky test patterns
- Justifying test infrastructure investment

## Execution

### 1. Current Baseline
```bash
# Total test count
python -m pytest hummbl_governance/tests/ --collect-only -q 2>/dev/null | tail -1
# Run with timing
python -m pytest hummbl_governance/tests/ -v --tb=no -q 2>&1 | tail -5
```

### 2. Historical Data from Git
```bash
# Test file count over time
git log --oneline --since="30 days ago" -- "hummbl_governance/tests/" | wc -l
# Test count changes (from commit messages and file diffs)
git log --oneline --since="30 days ago" --diff-filter=A -- "hummbl_governance/tests/test_*.py"
git log --oneline --since="30 days ago" --diff-filter=D -- "hummbl_governance/tests/test_*.py"
# CLAUDE.md test count references over time
git log --oneline -10 -- "CLAUDE.md" | head -5
```

### 3. CI History (if available)
```bash
# Recent CI runs
gh run list --limit 20 --json conclusion,createdAt,name 2>/dev/null || echo "gh CLI not available or no runs"
# Failed runs
gh run list --limit 20 --status failure --json conclusion,createdAt,name 2>/dev/null | head -20
```

### 4. Flake Detection
If `--flakes` flag:
```bash
# Tests that have been in both pass and fail states recently
gh run list --limit 50 --json conclusion,createdAt 2>/dev/null | head -20
# Known flaky patterns
grep -rn "flaky\|intermittent\|retry\|skip.*random" hummbl_governance/tests/ --include="*.py" | head -10
```

### 5. Slowest Tests
If `--slowest` flag:
```bash
python -m pytest hummbl_governance/tests/ --durations=20 -q 2>&1 | head -25
```

## Output Format

```
Test Trends | <period> | <date>
============================================

Current Snapshot
----------------
  Total tests:     7,700+
  Test files:      242
  Pass rate:       100% (last run)
  Duration:        ~45s (full suite)

30-Day Trend
------------
  Tests added:     +340
  Tests removed:   -12
  Net growth:      +328 (+4.4%)
  New test files:  8
  Deleted files:   1

  Week    | Count | Pass% | Duration | Flakes
  --------|-------|-------|----------|-------
  Mar 1   | 7372  | 100%  | 42s      | 0
  Mar 8   | 7450  | 99.8% | 43s      | 2
  Mar 15  | 7580  | 100%  | 44s      | 0
  Mar 22  | 7700  | 100%  | 45s      | 1

CI Health (last 20 runs)
------------------------
  Passed: 17/20 (85%)
  Failed: 3/20
  Failure reasons:
    - 2x timeout (runner issue)
    - 1x flaky test (test_calendar_adapter)

Flaky Tests
-----------
  test_calendar_adapter::test_timeout  -- failed 2/10 runs (network mock timing)

Slowest Tests (top 5)
---------------------
  test_acceptance.py::test_full_briefing          3.2s
  test_runtime_wiring.py::test_resilient_flow     2.8s
  test_event_store.py::test_large_batch           2.1s

Next action: <recommendation>
```

## Skill Chains
- After `[test-trends] --flakes` -> `[debug-test]` on identified flaky tests
- After `[test-trends] --slowest` -> optimize slow tests or mark as integration
- After `[test-trends]` -> `[loc-report]` for code-to-test ratio analysis
