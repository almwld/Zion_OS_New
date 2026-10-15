---
name: ts-test-run
description: >
  Run TypeScript/JavaScript tests via jest, vitest, or node --test. The TS/JS
  counterpart to test-run (which is pytest-specific). Detects the test runner
  from package.json, runs the right command, and reports pass/fail/duration.
  Use when the repo has package.json with a test script, a jest/vitest config,
  or .test.ts/.spec.ts files. Do NOT use for pytest (use test-run), LLM eval
  (use eval-suite), or CLI tools (use cli-harness). Routes via harness-routing.md.
version: 0.1.0
execution-mode: advisory
argument-hint: "[unit | integration | e2e | <pattern>] [--runner jest|vitest|node] [--watch] [--coverage]"
schema_version: 0.1.0
category: dev-tools
status: candidate
providers:
  required: [python]
---

# ts-test-run

Run TypeScript/JavaScript tests using the project's configured test runner.
Auto-detects jest, vitest, or node --test from package.json and config files.
The TS/JS equivalent of `test-run` (which is pytest-specific).

## When to Use

- After writing or modifying TypeScript/JavaScript code
- After fixing a bug in a TS/JS package
- Before committing changes to a TS/JS repo
- CI failed and you need to reproduce locally
- When the operator says "run TS tests", "run jest", "run vitest", "npm test"

## When NOT to Use

- Running pytest suites → use `test-run`
- Testing CLI tools → use `cli-harness`
- Testing HTTP APIs → use `api-test`
- Evaluating LLM output → use `eval-suite`
- Performance benchmarking → use `benchmark`

## Execution

### 1. Detect the Test Runner

Check in this order:
1. `package.json` `scripts.test` field — if it contains `jest`, `vitest`, or `node --test`, use that
2. Config files: `jest.config.{js,ts,json}`, `vitest.config.{js,ts}`, `jest.config.{js,ts}.json`
3. Test file patterns: `*.test.{ts,js}`, `*.spec.{ts,js}` → default to `node --test`
4. If `vitest` is in devDependencies → vitest
5. If `jest` is in devDependencies → jest
6. Fallback: `node --test` (Node.js built-in test runner)

### 2. Parse Arguments
- `$ARGUMENTS`: test target (optional)
  - *(empty)*: run all tests
  - `unit`: run tests matching `*.unit.test.{ts,js}` or in `tests/unit/`
  - `integration`: run tests in `tests/integration/`
  - `e2e`: run tests in `tests/e2e/`
  - *anything else*: pass as a pattern filter to the runner
- `--runner`: override detected runner (`jest`, `vitest`, `node`)
- `--watch`: run in watch mode (interactive, for development)
- `--coverage`: collect coverage

### 3. Route by Runner

| Runner | Command |
|--------|---------|
| jest | `npx jest <pattern> --coverage <flag>` |
| vitest | `npx vitest run <pattern> --coverage <flag>` |
| node --test | `node --test <pattern>` |

### 4. Execute

1. `cd` to the repo root (where package.json lives)
2. Run the detected command
3. Capture stdout, stderr, exit code
4. Parse pass/fail counts from the runner's summary output

### 5. Report Results

## Output Format

```
ts-test-run | <runner> | <target> | <YYYY-MM-DD HH:MMZ>
══════════════════════════════════════════

Runner: <jest|vitest|node --test>
Target: <all | unit | integration | e2e | pattern>
Result: X passed, Y failed, Z skipped
Duration: Xs

<if failures>
## Failures
<runner failure output, trimmed to relevant assertions>
</if>

<if coverage>
## Coverage
| File | % Lines | % Branches | % Funcs |
|------|---------|------------|---------|
</if>
```

## Constraints

- ALWAYS detect the runner from package.json first; only override with `--runner` if the operator requests it
- ALWAYS use `npx` (not global installs) to ensure the project's version is used
- Do NOT fabricate test results — always run the actual command
- If no test runner is detected, report the error clearly and suggest installing one
- If `package.json` has no `test` script and no config files, report "no test runner found"
- For monorepos (workspaces), detect the workspace root and run from there

## Skill Chains

### Mandatory
- Follow `harness-routing.md` for SUT type routing

### Advisory
- **After ts-test-run**: `dep-check` (verify zero deps), `license-audit` (check licenses), `benchmark` (if perf matters)
- **Before ts-test-run**: `venv-manage` (not applicable — use `nvm`/`fnm` for Node version), `dep-update` (if deps are outdated)
- **Pair**: `debug-test` (if a test fails and needs root-cause analysis)
- **CI chain**: `ts-test-run` → `dep-check` → `license-audit`

## Authority

- **T1/T2 (operator/trusted)**: Unrestricted.
- **T3 (probationary-trusted)**: Unrestricted (read-only test execution).
- **T4 (probationary)**: Unrestricted (read-only test execution).

## References

- `harness-routing.md` — routing rule for all harness types
- `test-run` — pytest counterpart (Python repos)
- `benchmark` — for function performance testing
- `eval-suite` — for LLM evaluation suites
