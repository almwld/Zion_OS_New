---
name: cli-harness
description: >
  Build and run test harnesses for CLI tools — captures exit code, stdout/stderr,
  filesystem mutations, and environment variable effects. Use when testing
  command-line programs (Python argparse/click/typer, shell scripts, compiled
  binaries) that mutate state through filesystem, env, or process side effects.
  Do NOT use for pytest suites (use test-run), LLM text output (use eval-suite),
  or function performance (use benchmark). Routes via harness-routing.md.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<command> [--cases path] [--fixture-dir path] [--capture fs|env|stdout|all] [--dry-run]"
schema_version: 0.1.0
category: dev-tools
status: candidate
providers:
  required: [python]
---

# cli-harness

Build and run test harnesses for command-line tools. A CLI harness wraps a
command with inputs, executes it in a controlled environment, captures outputs
(exit code, stdout, stderr, filesystem changes, env changes), and verifies
expected behavior against declared assertions.

## When to Use

- Testing a CLI tool that modifies files, env vars, or process state
- Verifying a script's exit codes and output across input variations
- Regression-testing CLI tools after refactoring
- Validating that a command produces expected filesystem mutations
- When the operator says "test this command", "harness this CLI", "verify this script"

## When NOT to Use

- Running pytest suites → use `test-run`
- Measuring function performance → use `benchmark`
- Testing HTTP APIs → use `api-test`
- Testing MCP servers → use `mcp-test`
- Evaluating LLM text output → use `eval-suite`
- Testing agent skills with side effects → use `eval-forge`

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=cli-harness] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```

### 1. Parse Arguments
- `$ARGUMENTS`: the command to test (required). Can be a path to a script or a command string.
- `--cases`: path to a JSON/JSONL file with test cases (optional; if absent, generate from command analysis)
- `--fixture-dir`: directory for test fixtures and temporary filesystem state (default: `_state/cli-harness/<slug>/`)
- `--capture`: what to capture — `fs`, `env`, `stdout`, `all` (default: `all`)
- `--dry-run`: show the harness plan without executing

### 2. Analyze the Command
- Identify the command type: Python script, shell script, compiled binary
- Detect entry point: `__main__`, argparse, click, typer, or plain script
- Enumerate arguments, flags, and expected inputs
- Identify side-effect surfaces: files written, env vars set, processes spawned

### 3. Build Test Cases
For each test case, define:
- **name**: short identifier
- **args**: command-line arguments to pass
- **stdin**: optional input to pipe
- **env**: environment variables to set (isolated from host env)
- **expected_exit**: expected exit code (0, 1, 2, etc.)
- **expected_stdout**: substring or regex match (optional)
- **expected_stderr**: substring or regex match (optional)
- **expected_fs_changes**: list of files that should be created/modified/deleted
- **expected_env_changes**: env vars that should be set/unset (for subprocess-scoped env)

If `--cases` is provided, load from file. Otherwise, generate a minimal set:
- Happy path: valid args, expect exit 0
- Missing args: no required args, expect non-zero exit
- Invalid input: bad arg value, expect non-zero exit
- Side-effect check: verify fs/env mutations match expected

### 4. Create Fixture Environment
- Create an isolated fixture directory under `--fixture-dir`
- Copy or symlink any required input files
- Set up a clean env scope (inherit host env, apply case-specific overrides)
- Snapshot filesystem state before execution (for diff comparison)

### 5. Execute Each Case
For each test case:
1. Snapshot pre-state (filesystem listing, env vars)
2. Run the command in a subprocess with `subprocess.run()`
3. Capture: exit code, stdout, stderr, execution time
4. Snapshot post-state (filesystem listing, env vars)
5. Compute diffs: fs changes (created/modified/deleted), env changes

### 6. Verify Assertions
For each case, check:
- **exit_code**: actual == expected
- **stdout**: matches expected (substring or regex)
- **stderr**: matches expected (substring or regex)
- **fs_changes**: actual changes == expected changes
- **env_changes**: actual changes == expected changes

Record pass/fail per assertion and per case.

### 7. Report Results

## Output Format

```
cli-harness | <command> | <YYYY-MM-DD HH:MMZ>
══════════════════════════════════════════

## Command
<command>

## Cases: N | Pass: X | Fail: Y

| Case | Exit | Stdout | Stderr | FS | Env | Result |
|------|------|--------|--------|----|-----|--------|
| happy_path | 0/0 | PASS | - | PASS | - | PASS |
| missing_args | 2/2 | - | PASS | - | - | PASS |
| invalid_input | 1/1 | - | PASS | - | - | PASS |
| fs_mutation | 0/0 | PASS | - | FAIL | - | FAIL |

## Failures
### fs_mutation
- Expected: create _state/cli-harness/test/output.json
- Actual: no file created

## Fixture Dir
_state/cli-harness/<slug>/

## Verdict
PASS / FAIL (X/N cases passed)
```

## Case File Format

JSONL with one case per line:
```json
{"name": "happy_path", "args": ["--input", "foo.txt", "--output", "bar.txt"], "expected_exit": 0, "expected_stdout": "success", "expected_fs_changes": [{"path": "bar.txt", "action": "create"}]}
```

## Constraints

- ALWAYS run commands in an isolated fixture directory, never in the repo root
- ALWAYS isolate env vars — inherit host env, apply overrides, never mutate host env
- NEVER run destructive commands (rm -rf, dd, mkfs) without explicit operator approval
- NEVER execute commands with real credentials or secrets in the fixture env
- DO NOT fabricate results — always run the actual command
- If the command requires network access, note it and ask operator before proceeding
- Clean up fixture directories after the run unless `--keep-fixtures` is set
- Use `subprocess.run()` with `timeout` to prevent hangs

## Skill Chains

### Mandatory
- Follow `harness-routing.md` for SUT type routing
- Post SKILL_INVOKE on entry for side_effecting mode

### Advisory
- **After cli-harness**: `test-run` (if the CLI has Python unit tests), `benchmark` (if measuring CLI latency)
- **Before cli-harness**: `mock-server` (if the CLI calls an API), `venv-manage` (if Python CLI needs a venv)
- **Pair**: `debug-test` (if a case fails and needs root-cause analysis)

## Authority

- **T1/T2 (operator/trusted)**: Unrestricted. Can build and run CLI harnesses.
- **T3 (probationary-trusted)**: Can run harnesses in dry-run mode. Execution requires operator approval for commands with filesystem side effects.
- **T4 (probationary)**: Dry-run only. Cannot execute CLI harnesses without operator escalation.

## References

- `harness-routing.md` — routing rule for all harness types
- `eval-forge` — for agent skills (not CLI tools)
- `test-run` — for pytest suites (not CLI harnesses)
- `benchmark` — for function performance (not CLI correctness)
