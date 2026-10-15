---
name: env-setup
description: One-command dev environment bootstrap — venv, deps, hooks, config, verification
version: 1.0.0
execution-mode: side_effecting
argument-hint: "[--machine mbp|$REMOTE_HOST|windows] [--repo-root path]"
category: backend-infra
status: candidate
---
# Environment Setup | `$ARGUMENTS`

Bootstrap a complete development environment for hummbl-governance. Creates venv, installs dependencies, configures git hooks, verifies imports, and runs smoke tests.

## Context Gathering

Before executing this skill, gather the following context:
- Run `python3 --version 2>&1`
- Run `uname -sm`
- Run `git rev-parse --show-toplevel 2>/dev/null`
- Run `test -d .venv && echo "venv exists" || echo "no venv"`

## Procedure

Parse `$ARGUMENTS` for machine type (default: auto-detect) and repo root (default: git root).

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=env-setup] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### Step 1 — Detect Environment

```bash
# Machine detection
HOSTNAME=$(hostname)
ARCH=$(uname -m)
OS=$(uname -s)
echo "Host: $HOSTNAME | Arch: $ARCH | OS: $OS"

# Python version check (require 3.11+)
python3 -c "
import sys
v = sys.version_info
print(f'Python {v.major}.{v.minor}.{v.micro}')
if (v.major, v.minor) < (3, 11):
    print('FAIL: Python 3.11+ required')
    sys.exit(1)
else:
    print('PASS: Python version OK')
"
```

### Step 2 — Create Virtual Environment

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

# Create venv if missing
if [ ! -d .venv ]; then
    python3 -m venv .venv
    echo "PASS: Created .venv"
else
    echo "PASS: .venv already exists"
fi

# Activate and verify
source .venv/bin/activate
which python3
python3 --version
```

### Step 3 — Install Dependencies

```bash
source .venv/bin/activate

# Upgrade pip
python3 -m pip install --upgrade pip --quiet

# Install package with test extras
python3 -m pip install -e ".[test]" --quiet 2>&1 | tail -5

# Verify installation
python3 -m pip list 2>/dev/null | grep -E "pytest|coverage|bandit|semgrep|founder" || echo "WARN: some packages may be missing"
echo "PASS: Dependencies installed"
```

### Step 4 — Install Git Hooks

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Ensure hooks directory exists
mkdir -p "$REPO_ROOT/.git-hooks"

# Configure git to use custom hooks dir
git config core.hooksPath .git-hooks
echo "PASS: git hooks path set to .git-hooks"

# Copy hook scripts from source
if [ -d "$REPO_ROOT/scripts/git-hooks" ]; then
    for hook in "$REPO_ROOT/scripts/git-hooks/"*; do
        dest="$REPO_ROOT/.git-hooks/$(basename "$hook")"
        cp "$hook" "$dest"
        chmod +x "$dest"
        echo "PASS: Installed $(basename "$hook")"
    done
else
    echo "WARN: scripts/git-hooks/ not found -- hooks not installed"
fi

# Verify commit-msg hook exists
test -x "$REPO_ROOT/.git-hooks/commit-msg" && echo "PASS: commit-msg hook executable" || echo "FAIL: commit-msg hook missing or not executable"
```

### Step 5 — Verify Imports

```bash
source .venv/bin/activate

python3 -c "
modules = [
    'your_package',
    # Add your project's core modules here
    # e.g., 'your_package.services.main',
    # 'your_package.integrations.api_client',
]
passed = 0; failed = 0
for mod in modules:
    try:
        __import__(mod)
        passed += 1
        print(f'  PASS: {mod}')
    except ImportError as e:
        failed += 1
        print(f'  FAIL: {mod} -- {e}')
print(f'Imports: {passed} PASS, {failed} FAIL')
"
```

### Step 6 — Run Smoke Test

```bash
source .venv/bin/activate

# Run a minimal test to verify pytest works
python3 -m pytest tests/test_acceptance.py -v --tb=short -q 2>&1 | tail -15

# Check exit code
if [ $? -eq 0 ]; then
    echo "PASS: Smoke tests passed"
else
    echo "FAIL: Smoke tests failed -- check output above"
fi
```

### Step 7 — Machine-Specific Checks

```bash
HOSTNAME=$(hostname)

# local machine-specific: verify no Ollama running (CPU constraint)
if echo "$HOSTNAME" | grep -qi "macbook\|huxley"; then
    pgrep -x ollama >/dev/null 2>&1 && echo "WARN: Ollama running on local machine (CPU hog)" || echo "PASS: No Ollama on local machine"
fi

# remote-node-specific: verify Ollama is available
if echo "$HOSTNAME" | grep -qi "mini\|maks\|$REMOTE_HOST"; then
    curl -s -o /dev/null -w "%{http_code}" http://localhost:11434/api/tags --connect-timeout 2 | grep -q "200" && echo "PASS: Ollama reachable on $REMOTE_HOST" || echo "WARN: Ollama not reachable on port 11434"
fi

# Tailscale check
which tailscale >/dev/null 2>&1 && tailscale status --json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'PASS: Tailscale up -- {d.get(\"Self\",{}).get(\"HostName\",\"?\")}')" 2>/dev/null || echo "SKIP: Tailscale not available"
```

## Output Format

```
Environment Setup | <machine> | <date>
======================================

Step 1 — Detect:       [PASS] Python 3.X.Y on <OS> <ARCH>
Step 2 — Venv:         [PASS|CREATED] .venv at <path>
Step 3 — Dependencies: [PASS] pip install -e ".[test]" complete
Step 4 — Git Hooks:    [PASS] N hooks installed to .git-hooks/
Step 5 — Imports:      [PASS] N/N core modules importable
Step 6 — Smoke Test:   [PASS] N tests passed
Step 7 — Machine:      [PASS] <machine-specific checks>

Overall: [READY|ISSUES]
  Issues: <list or "none">

Activate with:
  source .venv/bin/activate

Next action: <environment ready | fix N issues listed above>
```

## Skill Chains

### Mandatory

None — environment setup; local changes only (venv creation, dependency installation, git hooks configuration).

### Advisory

- After: `[test-run]` (full test suite), `[health]` (verify services), `[sitrep]` (start working)

## Authority

- **T1 (TRUSTED)**: May run (full bootstrap — venv, deps, hooks, config, verification)
- **T2 (Active/High)**: May run (full bootstrap — venv, deps, hooks, config, verification)
- **T3 (Medium)**: May run (full bootstrap — venv, deps, hooks, config, verification)
- **T4 (Probationary)**: May run with operator approval (modifies local environment — venv, git config, installed packages)
- **Operator**: Override any restriction
