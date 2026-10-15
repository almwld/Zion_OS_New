---
name: stdlib-or-not
description: Audit any codebase to classify imports as stdlib vs third-party, with try-wrapped detection and repo-level verdict. [Maps to P1.]
version: 0.2.0
execution-mode: advisory
argument-hint: "[PATH | --json | --diff REF1..REF2]"
category: governance-compliance
status: candidate
---

# Stdlib-or-Not Command

Scan a Python codebase and report which imports are stdlib, which are third-party (hard vs try-wrapped), and which are unresolved. Useful before audits, when inheriting a codebase, or when evaluating dependency hygiene.

## When to Use
- When asked "is this codebase stdlib-only?"
- When reviewing or inheriting an unfamiliar Python project
- When auditing dependency health across a repo
- When checking whether dependency claims in docs match reality

## Execution

```bash
python3 -c "
import ast, sys, os, json, importlib
from pathlib import Path

TARGET = Path('${1:-.}').resolve()
SKIP_DIRS = {'.venv', '.tox', '.eggs', '__pycache__', 'node_modules', 'build', 'dist'}
STDLIB = frozenset(sys.stdlib_module_names) | frozenset(sys.builtin_module_names)
STDLIB |= {'__future__', '__main__', '__builtins__', 'setuptools', 'distutils'}

def is_internal(top, target, rel_path):
    '''Check if an import resolves to a sibling package within the target.'''
    # Check for sibling Python packages
    for candidate in (target / top):
        if candidate.is_dir() and (candidate / '__init__.py').exists():
            return True
    # Check for namespace packages at repo root
    return False

def is_in_try(node):
    '''Walk up the AST tree to check if this import is inside a try block.'''
    parent = node
    for p in ast.walk(node):
        pass
    # Can't easily walk up in ast.walk; use parent tracking instead
    return False

def collect_imports(tree, rel_str):
    '''Collect all imports from an AST tree, detecting try-wrapping.'''
    imports = []
    for node in ast.iter_child_nodes(tree):
        _walk_imports(node, imports, rel_str, in_try=False)
    return imports

def _walk_imports(node, imports, rel_str, in_try):
    if isinstance(node, ast.Try):
        for child in node.body:
            _walk_imports(child, imports, rel_str, in_try=True)
        for child in node.handlers:
            for c in child.body:
                _walk_imports(c, imports, rel_str, in_try=True)
        if node.orelse:
            for child in node.orelse:
                _walk_imports(child, imports, rel_str, in_try)
        if node.finalbody:
            for child in node.finalbody:
                _walk_imports(child, imports, rel_str, in_try)
        return
    if isinstance(node, ast.Import):
        for alias in node.names:
            imports.append((rel_str, node.lineno, alias.name, in_try))
    elif isinstance(node, ast.ImportFrom) and node.module:
        if node.module == '__future__':
            return
        imports.append((rel_str, node.lineno, node.module, in_try))
    for child in ast.iter_child_nodes(node):
        _walk_imports(child, imports, rel_str, in_try)

def classify(top, target):
    if top in STDLIB:
        return 'stdlib'
    if is_internal(top, target, None):
        return 'internal'
    try:
        spec = importlib.util.find_spec(top)
        if spec is None:
            return 'unresolved'
        origin = spec.origin or ''
        if 'site-packages' in origin or 'dist-packages' in origin:
            return 'third-party'
        if '/lib/python' in origin:
            return 'stdlib'
        return 'unknown'
    except (ValueError, ImportError, ModuleNotFoundError):
        return 'unresolved'

results = {}
try_wrapped = {}
total = 0
counts = {'stdlib': 0, 'third-party': 0, 'internal': 0, 'unresolved': 0, 'unknown': 0}

for pyfile in sorted(TARGET.rglob('*.py')):
    parts = pyfile.relative_to(TARGET).parts
    if any(p in SKIP_DIRS for p in parts):
        continue
    rel = str(pyfile.relative_to(TARGET))
    try:
        tree = ast.parse(pyfile.read_text(encoding='utf-8', errors='replace'))
    except SyntaxError:
        continue
    for f, line, name, in_try in collect_imports(tree, rel):
        top = name.split('.')[0]
        cls = classify(top, TARGET)
        entry = (rel, line, name)
        results.setdefault(cls, []).append(entry)
        counts[cls] = counts.get(cls, 0) + 1
        total += 1
        if cls == 'third-party' and in_try:
            try_wrapped.setdefault(top, []).append(entry)

if '--json' in sys.argv:
    print(json.dumps({
        'target': str(TARGET),
        'total_imports': total,
        'counts': counts,
        'details': {k: sorted(v) for k, v in results.items()},
        'try_wrapped': {k: sorted(v) for k, v in try_wrapped.items()},
    }, indent=2))
    sys.exit(0)

hard_third_party = []
try_wrapped_list = []
for top in sorted({x[2].split('.')[0] for x in results.get('third-party', [])}):
    if top in try_wrapped:
        try_wrapped_list.append(top)
    else:
        hard_third_party.append(top)

print(f'Stdlib-or-Not Audit | {TARGET}')
print('=' * 60)
for key in ['stdlib', 'internal', 'third-party', 'unresolved', 'unknown']:
    items = results.get(key, [])
    if not items:
        continue
    label = key.upper()
    print(f'\n  {label} ({len(items)})')
    for f, line, name in sorted(set(items))[:12]:
        print(f'    {f}:{line}  {name}')
    if len(items) > 12:
        print(f'    ... and {len(items) - 12} more')
print()
print(f'  TRY-WRAPPED THIRD-PARTY ({sum(len(v) for v in try_wrapped.values())})')
for mod, locs in sorted(try_wrapped.items()):
    print(f'    {mod}: {len(locs)} occurrence(s)')
print(f'\n  VERDICT:')
print(f'    Runtime deps (hard third-party): {len(hard_third_party)}')
print(f'    Runtime deps (try-wrapped): {len(try_wrapped_list)}')
print(f'    Internal/sibling packages: {counts.get(\"internal\", 0)}')
print(f'    Unresolved (may be metadata-only): {counts.get(\"unresolved\", 0)}')
print(f'\n  TOTAL: {total} imports')
for k, v in sorted(counts.items()):
    if v:
        pct = v / total * 100
        label = k.upper()
        print(f'    {label}: {v} ({pct:.0f}%)')
"
```
