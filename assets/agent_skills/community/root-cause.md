---
name: root-cause
description: Perform evidence-backed 5-why analysis for test, CI, service, code, workflow, or process failures; identify an actionable systemic cause and prevention.
version: 1.0.1
execution-mode: advisory
argument-hint: <failure-description>
category: dev-tools
status: tested
providers:
  required: [bash, python]
---
# Root Cause Analysis

Structured 5-why analysis starting from an observed failure. Every "why" must cite evidence (log line, test output, code path, bus message). No speculation without labeling it as such.

Use this for generic test, CI, service, code, workflow, or process failures. If
the defining evidence is an OS-level segfault, abort, or systemd core dump, use
the runtime's crash-diagnosis skill first; return here only when a broader
systemic 5-why analysis is requested.

## Working Directory

Run all `git`, `gh`, `pytest`, and `rg` commands from the fleet repo root (`~/.agents` or the active worktree equivalent). Never assume a package-relative CWD. (The prior canonical repo `hummbl-governance` is archived; `~/.agents` is the live fleet repo on agent-node.)

## Arguments

- `$ARGUMENTS`: Description of the failure or symptom to investigate
- If no arguments, prompt for: What broke? When? What was the expected behavior?

## Workflow

### 1. Define the Symptom Precisely

Before asking "why", establish the observable facts.

```bash
# Gather evidence for the symptom — run whichever apply:

# Recent test failures
python3 -m pytest --tb=short -q 2>&1 | tail -30

# Recent error logs
find . -name "*.log" -newer /tmp/rca_marker -exec grep -l -i "error\|exception\|fail" {} \; 2>/dev/null

# Check service logs
tail -50 _state/logs/*.log 2>/dev/null | grep -i "error\|exception\|traceback"

# Recent bus BLOCKED messages
awk -F'\t' '$4 == "BLOCKED"' _state/coordination/messages.tsv | tail -10

# Git log around the time of failure
git log --oneline --since="2 hours ago" | head -20

# Health probe status
python3 -m your_project.services.health 2>/dev/null | head -20

# CI status
gh run list --limit 5 2>/dev/null
```

Document:
- **What** failed (exact error message, test name, service name)
- **When** it started (timestamp, commit hash, or event)
- **Expected** behavior vs actual behavior
- **Impact** (who/what is affected)

### 2. The 5 Whys

For each level, gather evidence BEFORE stating the cause.

#### Why 1: Why did [symptom] occur?

```bash
# Trace the immediate cause
# For a test failure:
python3 -m pytest path/to/failing_test.py -v --tb=long 2>&1 | tail -50

# For an import error:
python3 -c "import MODULE_NAME" 2>&1

# For a service failure:
curl -s http://localhost:PORT/health 2>&1

# For a bus issue:
tail -5 _state/coordination/messages.tsv
```

Evidence: [cite specific output]
Cause: [one sentence]

#### Why 2: Why did [cause 1] happen?

```bash
# Dig one level deeper
# Trace the code path
grep -n "PATTERN_FROM_ERROR" path/to/file.py

# Check recent changes to the file
git log --oneline -5 path/to/file.py

# Check if a dependency changed
git diff HEAD~5 path/to/requirements.txt path/to/pyproject.toml 2>/dev/null
```

Evidence: [cite specific output]
Cause: [one sentence]

#### Why 3: Why did [cause 2] happen?

```bash
# Continue tracing — common patterns:

# Configuration changed?
git diff HEAD~10 -- "*.toml" "*.yaml" "*.json" "*.cfg" | head -40

# Environment changed?
python3 --version
which python3

# Dependency missing?
pip list 2>/dev/null | grep PACKAGE_NAME

# Permission issue?
ls -la PATH_TO_FILE
```

Evidence: [cite specific output]
Cause: [one sentence]

#### Why 4: Why did [cause 3] happen?

```bash
# Getting closer to root — look for process/system causes:

# Was this a known pattern?
grep -r "TODO\|FIXME\|HACK\|WORKAROUND" path/to/module/ | head -10

# Was there a guardrail that should have caught this?
git log --oneline --all | grep -i "guard\|gate\|check\|valid" | head -10

# Did CI catch it?
gh run list --workflow=ci.yml --limit 5 2>/dev/null
```

Evidence: [cite specific output]
Cause: [one sentence]

#### Why 5: Root Cause

The root cause should be:
1. **Actionable** — you can fix it, not just describe it
2. **Systemic** — fixing it prevents recurrence, not just this instance
3. **Evidenced** — supported by the chain above, not guessed

Common root cause categories:
- **Missing test**: The failure case had no test coverage
- **Missing validation**: Input was not validated at the boundary
- **Missing guard**: No circuit breaker, no retry, no timeout
- **Process gap**: No review caught it, no CI check exists
- **Stale assumption**: Code assumed X but environment changed
- **Coupling**: Change in A broke B due to hidden dependency

### 3. Verify the Chain

Walk the chain backwards: if we fix the root cause, does each intermediate "why" also get resolved?

### 4. Propose Fix

The fix should target the root cause, not the symptom. Include:
- The specific code, config, or process change
- A test that would have caught this failure
- A guardrail to prevent recurrence

## Output Format

```
Root Cause Analysis | [short failure label]

## Symptom
  What:     [exact error or failure description]
  When:     [timestamp or commit]
  Expected: [what should have happened]
  Actual:   [what happened instead]
  Impact:   [who/what is affected]

## 5-Why Chain

  ┌─ Symptom: [failure description]
  │
  ├─ Why 1: [immediate cause]
  │  Evidence: [file:line, log entry, or command output]
  │
  ├─ Why 2: [next-level cause]
  │  Evidence: [file:line, log entry, or command output]
  │
  ├─ Why 3: [deeper cause]
  │  Evidence: [file:line, log entry, or command output]
  │
  ├─ Why 4: [systemic cause]
  │  Evidence: [file:line, log entry, or command output]
  │
  └─ Why 5 (ROOT): [actionable root cause]
     Evidence: [file:line, log entry, or command output]
     Category: [missing test | missing validation | process gap | ...]

## Verification
  Chain integrity: [VALID — each why follows from the previous]
  Root addresses all: [YES — fixing root prevents symptom recurrence]
  Alternative roots: [NONE | list if multiple possible roots exist]

## Recommended Fix
  Target:   [root cause — why 5]
  Change:   [specific code/config/process change]
  File(s):  [paths to modify]
  Test:     [test to add that would have caught this]
  Guard:    [guardrail to prevent recurrence]

## Confidence
  [HIGH]   — All 5 whys have direct evidence
  [MEDIUM] — 3-4 whys evidenced, 1-2 inferred
  [LOW]    — Significant speculation; needs more data

  Speculative steps: [list any "why" levels that lack hard evidence]

No further action needed | Action: [specific next step]
```

## Rules

1. **Evidence at every level** — "Why N" without evidence is speculation. Label it: `[INFERRED]`
2. **Stop at actionable** — If you reach an actionable root cause at Why 3, stop. Do not force 5 levels.
3. **Do not branch early** — Follow ONE causal chain. If you find multiple branches, note them and pick the most likely.
4. **Verify backwards** — The chain must be logically consistent when read in reverse.
5. **Fix the root, not the symptom** — A try/except around a crash is a symptom fix. Fixing the data that causes the crash is a root fix.

## Common Anti-Patterns

| Anti-Pattern | Example | Better |
|-------------|---------|--------|
| Stopping at blame | "Developer made a mistake" | "No test existed for this edge case" |
| Stopping at symptom | "The function returned None" | "Input validation missing at boundary" |
| Circular reasoning | "It failed because it was broken" | Trace to specific code/config |
| Speculation as fact | "Probably a race condition" | Reproduce with evidence or label [INFERRED] |
| Premature fix | "Add a retry" | Find why the first attempt fails |

## Skill Chains

- After RCA: `[debug-test]` (if test-related root cause)
- After RCA: `[regression-check]` (verify fix does not break other things)
- After RCA: `[retrospective]` (persist learnings)
- After RCA: `[ledger]` (record the finding for future reference)
- If process gap: `[pre-mortem]` (identify similar gaps elsewhere)
- If recurring: `[postmortem]` (broader incident review)
