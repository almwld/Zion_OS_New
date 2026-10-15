---
name: python-upgrade
description: Check codebase compatibility with target Python version
version: 0.1.0
execution-mode: remedial
argument-hint: "<target: 3.12|3.13|3.14|3.15>"
category: dev-tools
status: candidate
---
# [python-upgrade]

## When to Use
- Planning Python version upgrade for the project
- New Python release drops and you want to assess impact
- CI matrix expansion to include new Python versions
- Checking if deprecated stdlib modules are in use

## Execution

### 1. Current State
```bash
# Current Python version
python3 --version
# pyproject.toml Python requirement
grep -A2 "python_requires\|requires-python" pyproject.toml 2>/dev/null || echo "No pyproject.toml"
# CI matrix
grep -A5 "python-version" .github/workflows/ci.yml 2>/dev/null | head -10
```

### 2. Deprecated Module Scan
Check for modules deprecated or removed in target version:

**Removed in 3.12**: `distutils` (use `setuptools`), `imp` (use `importlib`)
**Removed in 3.13**: `aifc`, `audioop`, `cgi`, `cgitb`, `chunk`, `crypt`, `imghdr`, `mailcap`, `msilib`, `nis`, `nntplib`, `ossaudiodev`, `pipes`, `sndhdr`, `spwd`, `sunau`, `telnetlib`, `uu`, `xdrlib`
**Deprecated in 3.14**: `argparse.BooleanOptionalAction` changes, `pathlib` new methods
**Preview in 3.14**: free-threaded mode (no-GIL), `typing` improvements

```bash
# Scan for deprecated imports
for mod in distutils imp aifc audioop cgi cgitb chunk crypt imghdr mailcap pipes sndhdr telnetlib uu xdrlib; do
  grep -rn "import $mod\|from $mod" $PROJECT_ROOT/ --include="*.py" 2>/dev/null
done
```

### 3. Syntax and Feature Compatibility
```bash
# Type annotation patterns that changed
grep -rn "Optional\[" $PROJECT_ROOT/ --include="*.py" | wc -l  # use X | None in 3.10+
grep -rn "Union\[" $PROJECT_ROOT/ --include="*.py" | wc -l    # use X | Y in 3.10+
grep -rn "from __future__ import annotations" $PROJECT_ROOT/ --include="*.py" | wc -l
# match/case (3.10+)
grep -rn "match " $PROJECT_ROOT/ --include="*.py" | head -5
# Exception groups (3.11+)
grep -rn "ExceptionGroup\|except\*" $PROJECT_ROOT/ --include="*.py" | head -5
# f-string improvements (3.12+: arbitrary expressions)
```

### 4. Test Suite Verification
```bash
# Try running tests with target version if available
python3.13 --version 2>/dev/null && echo "3.13 available" || echo "3.13 not installed"
python3.14 --version 2>/dev/null && echo "3.14 available" || echo "3.14 not installed"
```

### 5. Dependency Check
```bash
# Check test dependencies compatibility
grep -A20 "\[test\]" pyproject.toml 2>/dev/null | head -25
# pip compatibility
pip index versions pytest 2>/dev/null | head -3
```

## Output Format

```
Python Upgrade | <current> -> <target> | <date>
============================================

Current: Python 3.11
Target:  Python 3.14
CI Matrix: 3.11, 3.12, 3.13, 3.14

Deprecated/Removed Modules Found
---------------------------------
  [NONE] No deprecated module imports found

Syntax Modernization Opportunities
-----------------------------------
  Optional[X] -> X | None:    45 occurrences (cosmetic, not blocking)
  Union[X, Y] -> X | Y:       12 occurrences (cosmetic, not blocking)
  from __future__ annotations: 8 files (can remove for 3.11+)

New Features Available
----------------------
  3.12: f-string arbitrary expressions, type parameter syntax (PEP 695)
  3.13: improved error messages, REPL improvements
  3.14: free-threaded mode (experimental), deferred eval of annotations

Blocking Issues
---------------
  [NONE] No blocking compatibility issues found

Test Results on Target
----------------------
  Python 3.14: not installed locally (test on CI or $REMOTE_HOST)

Recommended Actions
-------------------
  1. Add 3.14 to CI matrix (.github/workflows/ci.yml)
  2. Modernize type annotations (Optional -> X | None) -- 45 files
  3. Test free-threaded mode on $REMOTE_HOST (experimental)

Next action: <recommendation>
```

## Skill Chains
- After `[python-upgrade]` -> `[test-run]` on target version
- After `[python-upgrade]` with blocking issues -> `[tech-debt]` to plan remediation
- After `[python-upgrade]` -> `[ci-monitor]` to verify CI matrix passes
