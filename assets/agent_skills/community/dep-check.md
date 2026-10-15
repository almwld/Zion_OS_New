---
name: dep-check
description: Verify zero third-party runtime dependencies -- scan imports including conditional try/except imports.
version: 0.2.0
execution-mode: advisory
argument-hint: "[scan | deep | verify FILE | audit]"
status: tested
category: dev-tools
providers:
  required: [python]
---
# Dependency Check Command

Enforce the stdlib-only rule: zero third-party runtime dependencies in core code.

## When to Use
- After adding new imports
- Before shipping a feature
- When reviewing another agent's code
- Periodic audit (monthly)

## Operations

### scan
Quick scan for non-stdlib imports (top-level only):
```bash
python3 -c "
import ast, sys
from pathlib import Path

STDLIB = set(sys.stdlib_module_names)
CORE_DIRS = ['services', 'integrations', 'cognition', 'bus']

violations = []
for d in CORE_DIRS:
    for f in Path(d).rglob('*.py'):
        try:
            tree = ast.parse(f.read_text())
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        mod = alias.name.split('.')[0]
                        if mod not in STDLIB and mod != 'your_package':
                            violations.append((str(f), node.lineno, mod))
                elif isinstance(node, ast.ImportFrom) and node.module:
                    mod = node.module.split('.')[0]
                    if mod not in STDLIB and mod != 'your_package':
                        violations.append((str(f), node.lineno, mod))
        except: pass

if violations:
    for f, line, mod in sorted(violations):
        print(f'  {f}:{line} imports {mod}')
    print(f'\n{len(violations)} violations found')
else:
    print('Clean: no third-party imports in core code')
"
```

### deep
**Enhanced scan** that also catches conditional `try: import X except: pass` patterns.
This was added after [proof-check] found 5 hidden third-party imports the basic scan missed.

```bash
python3 -c "
import ast, sys
from pathlib import Path

STDLIB = set(sys.stdlib_module_names)
CORE_DIRS = ['services', 'integrations', 'cognition', 'bus']

def _is_conditional(tree, node):
    for parent in ast.walk(tree):
        if isinstance(parent, ast.Try):
            for child in ast.walk(parent):
                if child is node:
                    return True
    return False

violations = []
for d in CORE_DIRS:
    for f in Path(d).rglob('*.py'):
        if '.venv' in str(f): continue
        try:
            tree = ast.parse(f.read_text())
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        mod = alias.name.split('.')[0]
                        if mod not in STDLIB and mod != 'your_package':
                            tag = 'conditional' if _is_conditional(tree, node) else 'direct'
                            violations.append((str(f), node.lineno, mod, tag))
                elif isinstance(node, ast.ImportFrom) and node.module:
                    mod = node.module.split('.')[0]
                    if mod not in STDLIB and mod != 'your_package':
                        tag = 'conditional' if _is_conditional(tree, node) else 'direct'
                        violations.append((str(f), node.lineno, mod, tag))
        except: pass

if violations:
    for f, line, mod, tag in sorted(violations):
        marker = ' [CONDITIONAL]' if tag == 'conditional' else ''
        print(f'  {f}:{line} imports {mod}{marker}')
    direct = sum(1 for _, _, _, t in violations if t == 'direct')
    cond = sum(1 for _, _, _, t in violations if t == 'conditional')
    print(f'\n{len(violations)} violations ({direct} direct, {cond} conditional)')
else:
    print('Clean: no third-party imports in core code (including conditional)')
"
```

### verify
Check a specific file:
```bash
python3 -c "import ast; [print(f'  line {n.lineno}: {n.module or n.names[0].name}') for n in ast.walk(ast.parse(open('$FILE').read())) if isinstance(n, (ast.Import, ast.ImportFrom))]"
```

### audit
Full audit including pyproject.toml:
```bash
echo "=== pyproject.toml dependencies ==="
grep -A 20 '\[project\]' pyproject.toml | grep -A 10 'dependencies'
echo
echo "=== test extras ==="
grep -A 10 '\[project.optional-dependencies\]' pyproject.toml
```

## Rules
- `services/`, `integrations/`, `cognition/`, `bus/` -- stdlib only
- `tests/` -- pytest, coverage allowed (in `[test]` extras)
- `dashboard/` -- FastAPI, uvicorn allowed (separate install)
- Conditional imports (`try: import X except: pass`) still count as violations
- If you need a library function, implement it with stdlib
- Exceptions must be explicitly approved in `pyproject.toml`

## Live Vulnerability Check

After scanning imports, check discovered dependencies for known vulnerabilities using free APIs:

```bash
# OSV.dev — query vulnerabilities for a specific package
python ~/bin/free_apis.py osv query --package <package-name> --ecosystem <PyPI|npm|Go>

# NVD — search for CVEs by keyword
python ~/bin/free_apis.py nvd search --keyword "<package-name>" --limit 10

# NVD — fetch full details for a specific CVE
python ~/bin/free_apis.py nvd cve --id CVE-YYYY-NNNNN
```

These are keyless and return structured vulnerability data including CVSS scores, descriptions, and references. Use after the `scan` or `audit` operations to flag dependencies with known CVEs.

## Known Exceptions (to investigate)
Files found by [proof-check] that have conditional third-party imports:
- `services/predictive_resilience.py`: numpy, sklearn (likely dead code on stdlib path)
- `services/cost_governor_bridge.py`: jsonschema
- `integrations/langgraph_adapter.py`: langgraph
- `integrations/paperqa_adapter.py`: paperqa
- `integrations/semantic_kernel_adapter.py`: semantic_kernel

These should be either removed or documented as approved exceptions.
