---
name: exception-flow
description: Map exception flow through code — trace raise/catch/propagate paths, identify swallowed errors, and visualize call stacks
version: 0.1.0
execution-mode: advisory
argument-hint: "<module-or-path> [--visualize] [--depth 5]"
category: dev-tools
status: candidate
---
# exception-flow | Exception Flow Mapping and Analysis

## When to Use
- Understanding how exceptions propagate through a codebase
- Finding swallowed exceptions (bare except, empty catch blocks)
- Tracing the origin of an error to its handling (or lack thereof)
- Auditing error handling completeness before a release

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: module name or file/directory path
- `--visualize`: generate ASCII call-stack diagram of exception paths
- `--depth 5`: maximum call-chain depth to trace (default 5)

### 2. Scan for Raise Points
- Parse for `raise`, `throw`, `panic!`, or equivalents
- Record: file, line, exception type, function; classify as explicit, re-raise, or library-propagated

### 3. Scan for Catch Points
- Parse for `try/except`, `catch`, `match Err`, or equivalents
- Flag: **swallowed** (empty/log-only body), **over-broad** (base Exception), **shadowing** (parent before child)

### 4. Trace Propagation Paths
- Build call graph; for each raise, trace upward through callers
- Determine: caught? re-raised, transformed, or swallowed? uncaught -> handler or crash?
- Record path as: `raise -> caller1 -> ... -> handler/crash`

### 5. Identify Problems
- **Swallowed errors**: exception caught but not logged or re-raised
- **Unhandled paths**: exception reaches top-level with no handler
- **Type erosion**: specific exception caught as generic and context lost
- **Catch ordering**: parent type before child type (unreachable child)

### 6. Visualize (if --visualize)
- Generate ASCII tree showing raise-to-handler paths
- Use indentation to show call depth (up to `--depth`)
- Mark swallowed paths with `[SWALLOWED]` and unhandled with `[UNHANDLED]`

## Output Format

```
exception-flow | <module-or-path>

## Summary
- Files scanned: 23 | Raise points: 47 | Catch points: 31
- Swallowed: 6 | Unhandled: 3 | Over-broad: 4

## Raise Points
| File:Line   | Function       | Type             | Class        |
|-------------|----------------|------------------|--------------|
| auth.py:42  | validate_token | TokenExpired     | explicit     |
| db.py:118   | query          | OperationalError | library-prop |

## Swallowed Exceptions
| File:Line  | Caught    | Handler      | Impact         |
|------------|-----------|--------------|----------------|
| utils.py:55| Exception | pass         | silent failure |
| cache.py:30| KeyError  | return None  | masked miss    |

## Propagation Paths
```
validate_token -> TokenExpired
  -> handle_request [CAUGHT: logged + re-raised]
    -> middleware [CAUGHT: HTTP 401] -> top-level [HANDLED]

db.query -> OperationalError
  -> process_item [UNCAUGHT] -> top-level [UNHANDLED: crashes]
```

## Recommendations
- utils.py:55 -- log or re-raise; db.py:118 -- add retry; cache.py:30 -- distinguish miss from error

## Verdict
CLEAN / SWALLOWED_FOUND / UNHANDLED_FOUND / CRITICAL_GAPS
```

## Skill Chains
- After flow mapping -> `[error-catalog]` to document exception types
- After flow mapping -> `[try-except-audit]` for deeper catch-block review
- Before debugging -> `[debug-test]` to reproduce identified issues
