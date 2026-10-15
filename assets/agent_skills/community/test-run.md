---
name: test-run
description: Run tests by target (unit, integration, e2e, security, or -k).
version: 0.1.0
execution-mode: advisory
argument-hint: "[unit | integration | e2e | chaos | security | <pattern>]"
category: dev-tools
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Test file count**: Run `ls ~/$PROJECT_ROOT/tests/*/ 2>/dev/null | grep -c "\.py$" || echo "0"`
- **Test subdirs**: Run `ls -d ~/$PROJECT_ROOT/tests/*/ 2>/dev/null | xargs -I{} basename {} | tr '\n' ' ' || echo "none"`

# Test Run Command

## When to Use
- After writing new code
- After fixing a bug
- Before committing
- When you need to verify a specific module works
- CI failed and you need to reproduce locally
Run pytest against a specific test subdirectory or pattern.

## Usage

```bash
[test-run]              # Run ALL tests
[test-run] unit         # Run unit tests only
[test-run] integration  # Run integration tests only
[test-run] e2e          # Run end-to-end tests
[test-run] chaos        # Run chaos tests
[test-run] security     # Run security tests
[test-run] alerts       # Run tests matching -k "alerts"
```

## Execution

### Route by argument

| Argument | Command |
|----------|---------|
| *(empty)* | `python -m pytest $PROJECT_ROOT/tests/ -v` |
| `unit` | `python -m pytest $PROJECT_ROOT/tests/unit/ -v` |
| `integration` | `python -m pytest $PROJECT_ROOT/tests/integration/ -v` |
| `e2e` | `python -m pytest $PROJECT_ROOT/tests/e2e/ -v` |
| `chaos` | `python -m pytest $PROJECT_ROOT/tests/chaos/ -v` |
| `security` | `python -m pytest $PROJECT_ROOT/tests/security/ -v` |
| *anything else* | `python -m pytest -k "$ARGUMENTS" -v` |

### After execution

1. Report pass/fail counts from the pytest summary line.
2. If any tests fail, show the FAILURES section.
3. Report wall-clock duration.

## Output Format

```
Test Run | <target> | <YYYY-MM-DD HH:MMZ>
══════════════════════════════════════════

Target: <subdir or pattern>
Result: X passed, Y failed, Z skipped
Duration: Xs

<if failures>
## Failures
<pytest FAILURES output, trimmed to relevant assertions>
</if>
```

## Skill Chains
- **Routing**: See `harness-routing.md` for SUT-type routing. This skill covers Python pytest suites only. For TS/JS tests use `ts-test-run`, for CLI tools use `cli-harness`.

## Constraints

- Always use `python -m pytest` (not bare `pytest`) to ensure correct module resolution.
- Do not fabricate test results -- always run the actual command.
- If the test directory does not exist, report the error clearly.
- For IDP tests, prepend `ENABLE_IDP=true` to the command.
