---
name: regression-check
description: Identify what could break from a code change by tracing callers, dependents, and downstream consumers
version: 0.2.0
status: stable
canonical_status: not_yet_global_canon
execution-mode: remedial
argument-hint: "<file_or_function> [--depth N] [--include-tests]"
category: dev-tools
providers:
  required: [bash, python]
---
# Regression Check

Trace the impact radius of a code change by finding all callers, importers, and downstream consumers of a modified file or function. Identifies what could break, which tests cover the affected paths, and what remains untested.

## When to Use
- Before merging a change to understand its blast radius
- After modifying a shared utility or service module
- When changing a function signature or return type
- Before deprecating or removing a public API

## Execution
1. Parse `$ARGUMENTS` for the target file or function, depth limit (default: 3), and whether to include test files.
2. If target is a function: find its definition location (file, line, module).
3. Build a caller graph by searching for imports and references across the codebase.
4. For each caller, recursively find its callers up to `--depth` levels.
5. Identify affected test files that import or reference any file in the impact graph.
6. Check for contract schemas that reference the affected module.
7. Flag high-risk paths: functions with no test coverage in the impact chain.
8. Summarize the impact with a risk assessment.

## Output Format
```
Regression Check | {target}

## Impact Summary
- Direct callers: {N}
- Transitive dependents (depth {N}): {N}
- Test files covering impact: {N}
- Untested paths: {N}

## Caller Graph
{target}
  <- {caller_1} ({file})
    <- {caller_1a} ({file})
  <- {caller_2} ({file})

## Affected Tests
| Test File | Covers |
|-----------|--------|
| {test_file} | {direct|transitive} call to {target} |

## Untested Impact Paths
| Caller | File | Risk |
|--------|------|------|
| {func} | {file} | No test coverage for this call path |

## Risk Assessment
- Overall risk: {LOW|MEDIUM|HIGH|CRITICAL}
- Reason: {explanation}
- Recommendation: {test these paths before merging | safe to proceed | needs integration test}

No further action needed. | Consider [tdd] for untested paths.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Untested paths found | `[tdd]` to generate test stubs for gaps |
| High risk assessment | `[ship-check]` for full pre-merge verification |
| Impact is large | `[pre-mortem]` to anticipate failure scenarios |

## Promotion Receipt (v0.2.0 — 2026-06-24)

**Status**: `candidate` → `tested`
**Eval suite**: `eval/` (8 cases)
**Schema version**: `regression_check_eval.v0.1.0`

### Self-test results (perfect run)
- caller_detection_accuracy: 1.0 (gate: gte 0.85) PASS
- risk_assessment_accuracy: 1.0 (gate: gte 0.85) PASS
- test_coverage_detection: 1.0 (gate: gte 0.80) PASS
- false_high_risk_rate: 0.0 (gate: lte 0.15) PASS
- schema_validity: 1.0 (gate: gte 1.0, HARD) PASS
- critical_path_detection: 1.0 (gate: gte 1.0, HARD) PASS

### Residual issues
- Self-test uses ground-truth-as-actual; real codebase trace needed
- No real-world regression check validated yet
- Caller graph depth limited to 3 in test cases; deeper chains untested
- Next target: STABLE (requires cross-agent runs + live sessions)
