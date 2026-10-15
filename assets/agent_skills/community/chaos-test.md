---
name: chaos-test
description: Run controlled chaos tests to verify circuit breakers and kill switch behavior
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<scenario: adapter-kill|state-corrupt|network-fail|all> [--dry-run]"
category: security
status: candidate
---
# [chaos-test]

## When to Use
- Validating resilience after infrastructure changes
- Before a release to verify fault tolerance
- After adding new adapters or services
- Periodic hardening verification (monthly cadence)

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=chaos-test] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Pre-flight Safety Check
```bash
# Verify we are NOT in production
echo "Environment: $(hostname)"
# Check kill switch is not already active
grep -r "kill_switch\|KillSwitchMode" services/kill_switch_core.py | head -5
# Verify test infrastructure exists
ls tests/chaos/ 2>/dev/null || ls tests/ | grep -i chaos
```

IMPORTANT: Never run chaos tests against production state. Always use test fixtures or isolated state directories.

### 2. Scenario Selection
Parse `$ARGUMENTS` for scenario. If `--dry-run`, describe what would happen without executing.

**adapter-kill**: Kill each adapter one at a time, verify circuit breaker opens:
```bash
python -m pytest tests/ -k "chaos" -v --timeout=30
# Or run specific chaos scenarios
python -m pytest tests/ -k "circuit_breaker" -v
```

**state-corrupt**: Inject malformed data into state files, verify recovery:
- Corrupt briefing state JSON
- Inject invalid entries into bus TSV
- Truncate event store SQLite

**network-fail**: Simulate network failures for external services:
- Mock timeout on GitHub adapter
- Mock connection refused on Linear adapter
- Mock SSL error on Google Calendar adapter

**all**: Run all scenarios sequentially.

### 3. Execute Tests
```bash
# Run existing chaos/resilience tests
python -m pytest tests/ -k "chaos or resilient or circuit" -v --tb=short
# Check kill switch modes
python -m pytest tests/ -k "kill_switch" -v --tb=short
```

### 4. Verify Recovery
After each chaos scenario, verify:
- Circuit breaker transitions (CLOSED -> OPEN -> HALF_OPEN -> CLOSED)
- Kill switch mode changes and recovery
- No data loss or corruption in persistent state
- Health probes report accurate degraded status

## Output Format

```
Chaos Test | <scenario> | <date>
============================================

Scenario: adapter-kill
----------------------
  github_adapter    KILLED -> circuit OPEN -> recovered in 2.1s    [PASS]
  linear_adapter    KILLED -> circuit OPEN -> recovered in 1.8s    [PASS]
  calendar_adapter  KILLED -> circuit OPEN -> recovered in 2.4s    [PASS]
  cost_tracker      KILLED -> circuit OPEN -> NOT recovered        [FAIL]
    Detail: no fallback configured for cost data

Scenario: state-corrupt
------------------------
  briefing.json     CORRUPTED -> detected -> rebuilt from cache    [PASS]
  messages.tsv      MALFORMED -> skipped bad line -> continued     [PASS]
  event_store.db    TRUNCATED -> integrity error -> recreated      [PASS]

Scenario: network-fail
-----------------------
  github timeout    -> retry 3x -> circuit open -> fallback        [PASS]
  linear refused    -> immediate circuit open -> cached data        [PASS]
  calendar SSL      -> retry 1x -> circuit open -> empty schedule  [PASS]

Summary
-------
  Scenarios run: 9
  Passed: 8
  Failed: 1
  Recovery time (avg): 2.1s

Findings
--------
  [HIGH] cost_tracker has no fallback when circuit opens
  [INFO] All circuit breakers recovered within 3s threshold

Next action: <recommendation>
```

## Skill Chains

### Mandatory

- `[health]` MUST confirm baseline before chaos test — establishes a known-good state so recovery can be verified

### Advisory

- **Routing**: See `harness-routing.md` for SUT-type routing. This skill covers chaos/resilience testing only.
- After `[chaos-test]` with failures → `[debug-test]` on failing scenarios
- After `[chaos-test]` → `[retry-audit]` to verify retry configs match chaos results
- After `[chaos-test]` → `[soc2-check]` to update Availability evidence

## Authority

- **T1 (TRUSTED)**: May run with health baseline confirmed
- **T2 (Active/High)**: May run with health baseline confirmed
- **T3 (Medium)**: Operator approval required + health baseline confirmed
- **T4 (Probationary)**: BLOCKED (destructive testing — probationary agents must not inject failures)
- **Operator**: Override any restriction
