---
name: retry-audit
description: Audit retry logic, backoff strategies, timeouts, and jitter across the codebase
version: 0.1.0
execution-mode: advisory
argument-hint: "[module-path] [--fix]"
category: governance-compliance
status: candidate
---
# [retry-audit]

## When to Use
- After chaos tests reveal retry gaps
- Before adding new external integrations
- Reviewing resilience posture for SOC 2 Availability
- Debugging intermittent failures in adapters

## Execution

### 1. Scan Retry Patterns
```bash
# Retry loops
grep -rn "retry\|retries\|max_attempts\|attempt" $PROJECT_ROOT/ --include="*.py" | head -30
# Backoff patterns
grep -rn "backoff\|sleep\|delay\|wait" $PROJECT_ROOT/ --include="*.py" | head -30
# Timeout configurations
grep -rn "timeout\|TIMEOUT\|time_limit" $PROJECT_ROOT/ --include="*.py" | head -30
# Jitter
grep -rn "jitter\|random\.\|randint" $PROJECT_ROOT/ --include="*.py" | head -20
```

### 2. Catalog Each Retry Site
For each retry pattern found, document:
- **Location**: file:line
- **Strategy**: fixed, linear, exponential, none
- **Max attempts**: number or unlimited
- **Base delay**: seconds
- **Max delay** (cap): seconds or uncapped
- **Jitter**: present/absent
- **Timeout**: per-attempt and total
- **On exhaustion**: raise, fallback, silent fail

### 3. Check Against Best Practices
Flag issues:
- **NO_RETRY**: external call with no retry (adapter, HTTP, subprocess)
- **NO_BACKOFF**: retry without increasing delay (thundering herd risk)
- **NO_JITTER**: exponential backoff without jitter (correlated retries)
- **NO_TIMEOUT**: retry loop with no total timeout (infinite hang risk)
- **NO_CAP**: exponential backoff with no max delay cap
- **SILENT_FAIL**: retry exhaustion swallowed without logging
- **TOO_MANY**: max_attempts > 10 (excessive for most patterns)

### 4. Fix Mode
If `--fix` flag: generate patches for common issues:
- Add jitter to exponential backoff
- Add timeout caps to unbounded retries
- Add logging on retry exhaustion

## Output Format

```
Retry Audit | <scope> | <date>
============================================

Retry Sites Found: 12
---------------------
  integrations/github_adapter.py:45
    Strategy: exponential  Max: 3  Base: 1.0s  Cap: 8s  Jitter: YES  Timeout: 30s
    On exhaustion: raises CalledProcessError
    Status: [OK]

  integrations/linear_adapter.py:78
    Strategy: fixed  Max: 2  Base: 2.0s  Cap: --  Jitter: NO  Timeout: none
    On exhaustion: returns None (silent)
    Status: [WARN] NO_JITTER, NO_TIMEOUT, SILENT_FAIL

  services/briefing.py:120
    Strategy: none  Max: 1  Base: --  Cap: --  Jitter: --  Timeout: 60s
    On exhaustion: N/A (no retry)
    Status: [INFO] NO_RETRY on resilient_briefing call

External Calls Without Retry
-----------------------------
  integrations/cost_tracker.py:33   subprocess.run(...)     [WARN] NO_RETRY
  services/signal_delivery.py:55    urllib.request(...)      [WARN] NO_RETRY

Summary
-------
  Total retry sites: 12
  OK: 7
  WARN: 4 (2 NO_JITTER, 1 NO_TIMEOUT, 3 SILENT_FAIL)
  Missing retry: 2 external calls

Next action: <recommendation>
```

## Skill Chains
- After `[retry-audit]` -> `[chaos-test]` to validate retry behavior under failure
- After `[retry-audit] --fix` -> `[test-run]` to verify fixes pass
- After `[retry-audit]` -> `[error-catalog]` to cross-reference exhaustion handling
