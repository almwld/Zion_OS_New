---
name: tech-debt
description: Comprehensive multi-repo tech debt scanner, classifier, and reducer. Covers all 8 debt categories with severity rubric and remediation plans.
version: 0.2.0
execution-mode: remedial
argument-hint: "[scan | reduce | report | cross-repo | arbiter-audit]"
category: dev-tools
status: candidate
---
# Tech Debt

Systematic tech debt management — find it, classify it, reduce it, prevent it from hiding.

## When to Use
- Before a sprint planning session ("what's the worst debt right now?")
- After a period of fast shipping ("what did we accumulate?")
- Suspecting a CI quality gate isn't catching real issues (`arbiter-audit` mode)
- Onboarding a new repo or team member (`report` mode for full picture)
- Cross-org hygiene check (`cross-repo` mode)

---

## Modes

### `scan` (default)
Run all 8 debt checks against `services/`, `integrations/`, `cognition/` (or any specified path).

```bash
# 1. Deferred-comment markers in non-test source
echo "=== Debt markers ==="
grep -rn "TODO\|FIXME\|HACK\|XXX\|WORKAROUND" services/ integrations/ cognition/ \
  --include="*.py" | grep -v "/tests/" | grep -v "__pycache__"

# 2. Silent exception swallowing (P0 risk: hides production failures)
echo "=== Silent pass-after-except ==="
grep -rn -A1 "except.*:" services/ integrations/ cognition/ \
  --include="*.py" | grep -v "__pycache__" | grep -B1 "^\s*pass$"

# 3. Broad exception clauses (P1: reduces debuggability)
echo "=== Broad except Exception ==="
grep -rn "except Exception\|except BaseException\|except:" \
  services/ integrations/ cognition/ --include="*.py" | grep -v "__pycache__" | \
  awk -F: '{print $1}' | sort | uniq -c | sort -rn | head -15

# 4. Large files (>1000 LOC = decomposition candidate, >2000 = critical)
echo "=== Large files ==="
find services/ integrations/ cognition/ -name "*.py" | \
  xargs wc -l 2>/dev/null | sort -rn | head -15

# 5. Suppression annotations
echo "=== Suppressions ==="
grep -rn "# type: ignore\|# noqa\|# pylint: disable" \
  services/ integrations/ cognition/ --include="*.py" | grep -v "__pycache__" | wc -l

# 6. Wildcard imports
echo "=== Wildcard imports ==="
grep -rn "^from .* import \*\|^import \*" services/ integrations/ cognition/ \
  --include="*.py" | grep -v "__pycache__"

# 7. Global mutable state (thread-safety risk in async services)
echo "=== Global mutable state ==="
grep -rn "^_[a-z].*= None$\|^[A-Z_].*= \[\]$\|^[A-Z_].*= {}$" \
  services/ integrations/ cognition/ --include="*.py" | grep -v "__pycache__" | head -20

# 8. Missing return type annotations on public functions
echo "=== Unannotated public functions (sample) ==="
python3 -c "
import ast, pathlib
for f in sorted(pathlib.Path('.').rglob('*.py')):
    if any(x in str(f) for x in ['.venv','__pycache__','tests','test_']): continue
    if not any(str(f).startswith(d) for d in ['services','integrations','cognition']): continue
    try:
        tree = ast.parse(f.read_text())
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef) and not node.name.startswith('_'):
                if node.returns is None:
                    print(f'  {f}:{node.lineno} {node.name}()')
    except: pass
" 2>/dev/null | head -20
```

---

### `reduce`
Fix specific debt categories. Each fix mode is surgical — touch only the target.

```bash
# Mode: silent-pass — find and replace with proper logging
python3 - << 'EOF'
"""Find except blocks with bare pass — print patch suggestions."""
import ast, pathlib, textwrap

for f in pathlib.Path('.').rglob('*.py'):
    if any(x in str(f) for x in ['.venv', '__pycache__', 'tests']): continue
    try:
        src = f.read_text()
        tree = ast.parse(src)
        lines = src.splitlines()
        for node in ast.walk(tree):
            if isinstance(node, ast.ExceptHandler):
                body = [n for n in node.body if not isinstance(n, ast.Expr)]
                if len(node.body) == 1 and isinstance(node.body[0], ast.Pass):
                    print(f"\n# FIX: {f}:{node.lineno}")
                    print(f"# Change: except ... pass")
                    print(f"# To:     except ... log.warning('silenced: %s', e)")
    except Exception:
        pass
EOF
```

For automated fixes, use `[bulk-edit]` with the pattern above or apply targeted edits per file.

---

### `report`
Generate a full markdown tech debt report for a repo.

**Report template:**

```
Tech Debt Inventory | <repo> | <date>
══════════════════════════════════════

## Executive Summary
- Total source files: N | Total LOC: N
- Debt rating: LOW / MED / HIGH / CRITICAL
- Top 3 priority items: ...

## Category Scores
| Category             | Count | Severity | Notes |
|----------------------|-------|----------|-------|
| Silent pass-in-catch |     N | HIGH     | |
| Broad except         |     N | MED      | |
| Files >1000 LOC      |     N | MED      | |
| Files >2000 LOC      |     N | HIGH     | |
| Deferred markers     |     N | LOW      | |
| Suppressions         |     N | LOW      | |
| Wildcard imports     |     N | MED      | |
| Global mutable state |     N | MED      | depends on async |

## Top 5 Items (by risk)
### P0 — Production Risk
- item: description — file:line

### P1 — Velocity Risk
- item: description — file:line

### P2 — Maintainability
- item: description

## Payoff Plan
| Item | Effort | Value | Sprint |
|------|--------|-------|--------|
| Fix silent catches in scheduler_adapters.py | S | HIGH | next |

## What the CI Arbiter Cannot See
The Arbiter grades changed-file hygiene only. Existing debt in unchanged files
scores 0. Items this report found that Arbiter will never catch:
- [list them]
```

---

### `cross-repo`
Scan all repos in an org one-by-one.

```bash
# List all repos
gh repo list <org> --json name,languages,diskUsage \
  --jq '.[] | "\(.name) — \(.languages[0].node.name // "unknown") \(.diskUsage)KB"'

# For each Python repo, clone or use gh api to scan key metrics:
# - Python file count
# - Total LOC estimate (diskUsage * 0.4 heuristic for Python-dominant repos)
# - Broad except count (gh api search)
# - Presence of ruff.toml / pyproject.toml [tool.ruff]

# Report format: one row per repo in the summary table
```

**Multi-repo summary table:**
```
| Repo            | LOC    | Rating | Top Issue                     |
|-----------------|--------|--------|-------------------------------|
| hummbl-governance    | 94k    | MED    | 9 files >1000 LOC, 365 excepts|
| foundermode-app | ~5k    | LOW    | Global _client state (voice.py)|
| swarm-test      | ~3k    | ?      | needs scan                    |
```

---

### `arbiter-audit`
Diagnose why the CI quality arbiter scores suspiciously high.

**The structural blind spot**: the Arbiter analyzes the *diff* (changed files only), not the repo.
A PR that adds clean new code to a 2,000-line file scores 100.0 even if the underlying file is
a maintenance nightmare.

**Audit steps:**

```bash
# 1. Check what the arbiter actually ran last time
gh run list --workflow "quality: arbiter analysis" --limit 5
gh run view <run-id> --log | grep -A5 "arbiter report"

# 2. Check if report JSON has findings or is always empty
gh run view <run-id> --log | grep '"findings"\|"by_tool"\|"by_severity"'

# 3. Check the 3 tool scores
# If lint=100, security=100, complexity=100 consistently:
# - lint: code follows ruff rules (expected for CI-linted PRs)
# - security: stdlib-only = no bandit findings (structural)
# - complexity: small functions pass radon threshold
```

**Fix options by severity:**

| Option | Effort | Signal Gain |
|--------|--------|-------------|
| Add `--repo` flag to run full-tree scan alongside diff | LOW | HIGH — catches existing debt |
| Add test coverage delta to rubric | MED | HIGH — penalizes PRs with no new tests |
| Lower F threshold from 60 → 80 | LOW | MED — tighter gate |
| Add dead-code check (vulture is already installed) | LOW | MED |
| Weight by file size (large-file PRs score harder) | MED | MED |

---

## Severity Rubric

| Issue | Severity | Why |
|-------|----------|-----|
| `except ... pass` (silent swallow) | **P0** | Production failures become invisible; corrupts observability |
| File > 2000 LOC | **P0** | Untestable in isolation; merge conflicts compound |
| `except Exception` without re-raise or logging | **P1** | Hides bug class; slows incident triage |
| File 1000–2000 LOC | **P1** | Cognitive load ceiling; refactor now before it grows |
| Global mutable state in async service | **P1** | Race conditions under load; hard to test |
| Missing return type annotations | **P2** | Mypy blind spots; docs debt |
| `# type: ignore` / `noqa` | **P2** | Suppresses errors that probably exist |
| Deferred markers in production code | **P2** | Acknowledged but untracked — put it in Linear instead |
| Wildcard imports | **P2** | Namespace pollution; CI tool false negatives |
| File 500–1000 LOC | **P3** | Watch-list; refactor if touching anyway |
| Deferred markers in tests | **P3** | Test intent drift |

---

## Process (documented from April 12 2026 session)

This process was validated against `hummbl-io/hummbl-governance` (94k LOC, 221 source files):

1. **List repos** — `gh repo list <org>` for language + size
2. **Run the 8-category scan** on each Python-dominant repo
3. **Check the Arbiter** (`arbiter-audit` mode) — understand what CI *cannot* see
4. **Classify findings** using the severity rubric above
5. **Report** — one summary table per repo + cross-repo comparison
6. **Prioritize** — P0 items go in next sprint; P1 go in backlog with `[rice-prioritize]`
7. **Reduce** — use `[bulk-edit]` for mechanical fixes (silent catches → log.warning); manual for design debt

**Key insight from April 12 audit:**
The Arbiter gave A (100.0) on every PR because: (a) stdlib-only eliminates bandit findings, (b) Conventional Commits + ruff eliminate lint findings, (c) small functions eliminate radon findings. The arbiter measures PR hygiene correctly — it just doesn't measure the *canvas*, only the brushstroke. Real debt lives in existing files that PRs don't touch. The fix is a full-tree scan alongside the diff scan.

---

## Output Format

```
Tech Debt | <repo> | <mode> | <date>
══════════════════════════════════════

## Summary
Debt rating: LOW / MED / HIGH / CRITICAL

| Category             | Count | Sev  |
|----------------------|-------|------|
| Silent pass-in-catch |     N | P0   |
| Files > 2000 LOC     |     N | P0   |
| Broad except         |     N | P1   |
| Files 1000-2000 LOC  |     N | P1   |
| Global mutable state |     N | P1   |
| Suppressions         |     N | P2   |
| Deferred markers     |     N | P2   |
| Wildcard imports     |     N | P2   |

## Top Items
[ranked P0 → P3, file:line for each]

## Payoff Plan
[effort × value matrix for top items]

## Arbiter Gap
[what CI cannot see — existing debt invisible to diff-only scan]
```

## Base120 Context
- Primary: **IN19** (Via Negativa — improve by removing)
- Related: **DE7** (Pareto 80/20), **RE1** (Kaizen), **DE12** (Constraint Isolation), **SY4** (Blind Spot Mapping)
