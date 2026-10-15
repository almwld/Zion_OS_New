---
name: onboard-dev
description: Generate dev environment setup guide from repo analysis
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--repo PATH] [--os mac|windows|linux]"
category: sales-marketing
status: candidate
---
# Onboard Dev

Generate a dev environment setup guide from repo analysis: dependencies, tools, first build, first test, common gotchas. Produces a step-by-step guide tailored to the target OS.

## When to Use
- New developer joining the project
- Setting up the project on a new machine
- Documenting the setup process after it changes
- Verifying that the setup guide is still accurate

## Execution
### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=onboard-dev] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. Parse `$ARGUMENTS` for `--repo` (default: current directory) and `--os` (default: detect current)
2. Analyze the repository:
   a. Read `pyproject.toml` / `setup.py` / `requirements.txt` for dependencies
   b. Read `CLAUDE.md` / `README.md` / `CONTRIBUTING.md` for existing setup docs
   c. Check for `.python-version`, `.nvmrc`, `.tool-versions` for version requirements
   d. Identify required system tools (git, gh, Python, node, etc.)
   e. Check for env var requirements (scan for `os.environ`, `.env.example`)
   f. Identify pre-commit hooks and their requirements
3. Generate setup steps tailored to `--os`:
   - Package manager commands (brew for mac, choco/winget for windows, apt for linux)
   - Python venv creation and activation (OS-specific syntax)
   - Dependency installation
   - First build/compile step
   - First test run command
   - Environment variable setup
4. Identify common gotchas:
   - Python version mismatches
   - Missing system dependencies
   - Platform-specific issues
   - Permission issues
5. Generate a "verify setup" checklist with expected outputs

## Output Format
```
Onboard Dev | {repo_name} | OS: {os}

Prerequisites:
1. {tool} {version} -- {install command}

Setup Steps:
1. Clone: {command}
2. Python: {venv setup}
3. Install: {pip install command}
4. Configure: {env vars}
5. Verify: {first test command}

Expected Output:
{what a successful setup looks like}

Common Gotchas:
- {gotcha}: {fix}

Next action: {recommendation}
```

## Skill Chains

### Mandatory

None — document generation from read-only analysis + file write; no external impact.

### Advisory

- Guide generated → `[readme-gen]` to update README
- Onboarding a person → `[onboard-human]` for team-level onboarding
- Setup verification → `[test-run]` to confirm tests pass

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (file generation only)
- **Operator**: Override any restriction
