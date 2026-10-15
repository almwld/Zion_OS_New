---
name: venv-manage
description: Create, verify, and troubleshoot Python virtual environments
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[create|verify|fix|list] [--path .venv] [--python 3.11]"
category: dev-tools
status: candidate
---
# venv-manage | Python Virtual Environment Management

## When to Use
- Setting up a new project or repo
- Debugging import errors or version mismatches
- After Python upgrade or Homebrew update
- Verifying PEP 668 compliance (externally-managed environments)
- CI runner venv troubleshooting

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=venv-manage] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Parse Action
- `create`: create new venv at specified path
- `verify`: check existing venv health (default action)
- `fix`: attempt to repair broken venv
- `list`: show all venvs in current project tree

### 2. Verify Action (default)
Check existing venv at `$PATH` (default `.venv`):
```bash
# Python version
.venv/bin/python --version
# pip health
.venv/bin/pip check
# Editable installs
.venv/bin/pip list --editable
# Site-packages sanity
.venv/bin/python -c "import sys; print(sys.prefix)"
# PEP 668 marker
ls -la .venv/lib/python*/EXTERNALLY-MANAGED 2>/dev/null
```

### 3. Create Action
```bash
python3.XX -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -e ".[test]"  # if pyproject.toml exists
```
Verify creation succeeded with verify checks.

### 4. Fix Action
Common fixes:
- Broken symlinks: recreate venv with `python3 -m venv --clear .venv`
- Wrong Python version: recreate with correct interpreter
- Missing pip: `python -m ensurepip --upgrade`
- Stale .pyc: `find .venv -name "*.pyc" -delete`

### 5. PEP 668 Compliance Check
- Verify system Python has EXTERNALLY-MANAGED marker
- Verify venv does NOT have the marker
- Confirm `pip install` works in venv but fails outside
- Important for CI runners ($REMOTE_HOST uses venv for PEP 668)

### 6. List Action
```bash
find . -name "pyvenv.cfg" -maxdepth 4 2>/dev/null
```
Show each venv's Python version and package count.

## Output Format

```
venv-manage | verify .venv

## Environment
- Path: $HOME/.venv
- Python: 3.11.8
- pip: 24.0
- Packages: 12 (8 runtime + 4 test)

## Health Checks
| Check               | Status | Detail                    |
|---------------------|--------|---------------------------|
| Python binary       | OK     | 3.11.8                    |
| pip check           | OK     | No broken deps            |
| Editable installs   | OK     | hummbl-governance 0.3.0        |
| Symlinks            | OK     | All valid                 |
| PEP 668             | OK     | System managed, venv free |
| stdlib-only runtime | OK     | No third-party in core    |

## Issues Found
- None (or list with fix commands)

## Fix Commands (if needed)
python3.11 -m venv --clear .venv && source .venv/bin/activate && pip install -e ".[test]"
```

## Skill Chains

### Mandatory

None — local venv management; no external impact.

### Advisory

- → `[venv-manage] fix` (rebuild after Python upgrade)
- → `[test-run]` (verify tests pass after venv fix)
- → `[venv-manage] verify` (clean environment before benchmarking)

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (local environment, no external impact)
- **Operator**: Override any restriction
