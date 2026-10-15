---
name: complexity-score
description: Cyclomatic and cognitive complexity scoring per function with hotspot ranking and simplification suggestions
version: 0.2.0
status: tested
canonical_status: not_yet_global_canon
execution-mode: advisory
argument-hint: "[PATH] [--threshold N] [--top N]"
category: dev-tools
providers:
  required: [bash, python]
---
# Complexity Score

Analyze Python code for cyclomatic and cognitive complexity at the function level. Ranks functions by complexity score, identifies hotspots that are hardest to maintain, and suggests specific simplification strategies for the worst offenders.

## When to Use
- Before refactoring to identify the highest-value targets
- During code review to flag overly complex new code
- As part of a tech debt audit to quantify maintenance burden
- When onboarding to understand which modules are hardest to work with

## Execution
1. Parse `$ARGUMENTS` for target path (default: current directory), threshold (default: 10), and top N (default: 20).
2. Use Python AST to parse each `.py` file in the target path.
3. For each function/method, calculate:
   - **Cyclomatic complexity**: count branches (if, elif, for, while, except, and, or, ternary).
   - **Cognitive complexity**: weight nested branches higher, penalize breaks in linear flow.
4. Flag functions exceeding the threshold.
5. Rank all functions by complexity score (descending).
6. For the top N offenders, analyze the structure and suggest simplification: extract method, early return, guard clause, lookup table, polymorphism.
7. Compute module-level averages and identify the most complex modules overall.

## Output Format
```
Complexity Score | {path}

## Summary
- Files scanned: {N}
- Functions analyzed: {N}
- Above threshold ({threshold}): {N} ({pct}%)
- Average complexity: {avg}

## Top {N} Hotspots
| Rank | Function | File:Line | Cyclomatic | Cognitive | Suggestion |
|------|----------|-----------|------------|-----------|------------|
| 1 | {func} | {file}:{line} | {cc} | {cog} | {suggestion} |
| 2 | {func} | {file}:{line} | {cc} | {cog} | {suggestion} |

## Module Averages
| Module | Avg Complexity | Max | Functions |
|--------|---------------|-----|-----------|
| {module} | {avg} | {max} | {count} |

## Recommendations
1. {highest-impact simplification}
2. {next recommendation}

No further action needed. | Consider [simplify] for the top hotspot.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| High-complexity functions found | `[simplify]` to refactor the worst offenders |
| Systemic complexity across modules | `[tech-debt]` to track as debt items |
| Ready to refactor | `[tdd]` to add tests before changing complex code |

## Promotion Receipt (v0.2.0 — 2026-06-24)

**Status**: `candidate` → `tested`
**Eval suite**: `eval/` (8 cases)
**Schema version**: `complexity_score_eval.v0.1.0`

### Self-test results (perfect run)
- cyclomatic_accuracy: 1.0 (gate: gte 0.85) PASS
- cognitive_accuracy: 1.0 (gate: gte 0.80) PASS
- hotspot_detection_rate: 1.0 (gate: gte 0.90) PASS
- false_hotspot_rate: 0.0 (gate: lte 0.10) PASS
- schema_validity: 1.0 (gate: gte 1.0, HARD) PASS
- critical_hotspot_detection: 1.0 (gate: gte 1.0, HARD) PASS

### Residual issues
- Self-test uses ground-truth-as-actual; real AST parse needed
- No real-world complexity run validated yet
- Next target: STABLE (requires cross-agent runs + live sessions)
