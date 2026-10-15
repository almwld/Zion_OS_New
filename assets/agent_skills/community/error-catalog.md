---
name: error-catalog
description: Catalog all exception types, error codes, and handling patterns in the codebase
version: 0.1.0
execution-mode: advisory
argument-hint: "[module-path] [--severity] [--unhandled]"
category: dev-tools
status: candidate
---
# [error-catalog]

## When to Use
- Auditing error handling before a release
- Building error documentation for operators
- Identifying unhandled exception paths
- After `[soc2-check]` flags Processing Integrity gaps
- Debugging production issues to understand error taxonomy

## Execution

### 1. Scan Exception Definitions
```bash
# Custom exception classes
grep -rn "class.*Error\|class.*Exception" src/ --include="*.py"
# Raised exceptions
grep -rn "raise " src/ --include="*.py" | head -40
# Error codes / error strings
grep -rn "error_code\|ERROR_\|err_" src/ --include="*.py" | head -30
```

### 2. Scan Error Handling Patterns
```bash
# Try/except blocks
grep -rn "except " src/ --include="*.py" | head -40
# Bare excepts (anti-pattern)
grep -rn "except:" src/ --include="*.py"
# Broad excepts
grep -rn "except Exception" src/ --include="*.py"
# Logging on error
grep -rn "logger\.\(error\|warning\|critical\)" src/ --include="*.py" | head -20
```

### 3. Classify by Module
Group findings by module path. For each module:
- List custom exception types
- Count raise sites
- Count handler sites (try/except)
- Identify unhandled paths (raise without matching except in call chain)

### 4. Severity Classification
- **CRITICAL**: unhandled exceptions that crash the process
- **HIGH**: errors that lose data or corrupt state
- **MEDIUM**: errors that degrade functionality (adapter failures)
- **LOW**: expected errors with proper recovery (retries, fallbacks)

If `--unhandled` flag: show only unhandled or bare-except patterns.
If `--severity` flag: sort output by severity descending.

## Output Format

```
Error Catalog | <scope> | <date>
============================================

Exception Types (custom)
------------------------
  CircuitBreakerOpen       services/circuit_breaker.py    MEDIUM  adapter unavailable
  KillSwitchActive         services/kill_switch_core.py   HIGH    halts processing
  DelegationTokenExpired   services/delegation_token.py   MEDIUM  re-auth needed
  SchemaValidationError    cognition/schema_validator.py  LOW     input rejected

By Module
---------
  services/briefing.py
    Raises: 3 (ValueError, RuntimeError, CircuitBreakerOpen)
    Handles: 5 try/except blocks
    Bare excepts: 0
    Recovery: fallback to cached briefing

  integrations/github_adapter.py
    Raises: 2 (subprocess.CalledProcessError, TimeoutError)
    Handles: 3 try/except blocks
    Bare excepts: 0
    Recovery: circuit breaker wraps all calls

Anti-Patterns Found
-------------------
  [WARN] 2 bare except: clauses (suppress all errors)
    - services/foo.py:42
    - integrations/bar.py:89
  [WARN] 5 broad except Exception (may mask bugs)
  [INFO] 0 unlogged exceptions

Summary
-------
  Custom exceptions: 8
  Raise sites: 47
  Handler sites: 62
  Bare excepts: 2
  Unhandled paths: 3

Next action: <recommendation>
```

## Skill Chains
- After `[error-catalog]` -> `[retry-audit]` to check recovery strategies
- After `[error-catalog] --unhandled` -> `[debug-test]` to write tests for unhandled paths
- After `[error-catalog]` -> `[soc2-check]` to update Processing Integrity evidence
