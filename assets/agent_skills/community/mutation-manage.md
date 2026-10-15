---
name: mutation-manage
description: Run and analyze mutation testing results, track kill rate over time, identify weak test areas
version: 0.1.0
execution-mode: advisory
argument-hint: "[--target MODULE] [--action run|report|trends]"
category: dev-tools
status: candidate
---
# Mutation Manage

Run mutation testing against Python modules, analyze mutant survival rates, track kill rate trends over time, and identify test suites with weak coverage. Uses stdlib-compatible mutation strategies (operator swaps, boundary changes, return value mutations).

## When to Use
- After writing tests to verify they actually catch regressions
- Identifying modules where tests pass but do not guard against real bugs
- Tracking mutation kill rate trends across sprints
- Before marking a module as "well-tested" to validate that claim

## Execution
1. Parse `$ARGUMENTS` for `--target` module path and `--action` (default: report).
2. For `run`: generate mutations (negate conditions, swap operators, change boundaries, alter return values) in the target module.
3. Run the test suite for each mutation and record whether it was killed (test failed) or survived (tests still passed).
4. Calculate kill rate: killed / total mutations.
5. For `report`: display per-function mutation results, highlight surviving mutants with the specific mutation applied.
6. For `trends`: compare current kill rate against previous runs stored in `_state/mutation-history.jsonl`.
7. Flag modules with kill rate below 80% as undertested.

## Output Format
```
Mutation Manage | <module> | report

Kill Rate: 87% (52/60 mutants killed)

| Function | Mutants | Killed | Survived | Rate |
|----------|---------|--------|----------|------|
| parse_config | 12 | 12 | 0 | 100% |
| validate_input | 18 | 16 | 2 | 89% |
| calculate_score | 15 | 11 | 4 | 73% |
| format_output | 15 | 13 | 2 | 87% |

Surviving Mutants:
- calculate_score L42: changed `>` to `>=` -- not caught
- calculate_score L58: changed `return 0` to `return 1` -- not caught

Next action: Add boundary tests for calculate_score lines 42 and 58.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Surviving mutants identified | `[ci-monitor]` to track improvement over time |
| Low kill rate module | `[coverage]` to check if lines are even reached |
| Inherits context from | `[test-run]` for baseline test results |
