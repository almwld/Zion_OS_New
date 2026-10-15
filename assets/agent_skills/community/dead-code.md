---
name: dead-code
description: Find and report unused code -- functions, imports, variables, files.
version: 0.1.0
execution-mode: advisory
argument-hint: <directory or file to scan>
category: dev-tools
status: candidate
---
# Dead Code Finder

Detect unused code that can be safely removed.

## Execution

### 1. Unused imports
```bash
python3 -c "
import ast, sys
from pathlib import Path

target = sys.argv[1] if len(sys.argv) > 1 else 'services'
for f in Path(target).rglob('*.py'):
    try:
        tree = ast.parse(f.read_text())
        source = f.read_text()
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    name = alias.asname or alias.name.split('.')[-1]
                    # Count uses beyond the import line
                    uses = source.count(name) - 1
                    if uses <= 0:
                        print(f'  {f}:{node.lineno} unused import: {alias.name}')
            elif isinstance(node, ast.ImportFrom) and node.names:
                for alias in node.names:
                    name = alias.asname or alias.name
                    uses = source.count(name) - 1
                    if uses <= 0:
                        print(f'  {f}:{node.lineno} unused from-import: {name}')
    except: pass
" "$TARGET"
```

### 2. Unused functions
```bash
# Find function definitions, then check if they're called anywhere
python3 -c "
import ast, sys
from pathlib import Path

target = sys.argv[1] if len(sys.argv) > 1 else 'services'
all_files = list(Path(target).rglob('*.py'))
all_source = ''.join(f.read_text() for f in all_files)

for f in all_files:
    try:
        tree = ast.parse(f.read_text())
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef) and not node.name.startswith('_'):
                # Skip test functions, __dunder__, and property setters
                if node.name.startswith('test_'): continue
                uses = all_source.count(node.name) - 1  # minus definition
                if uses <= 0:
                    print(f'  {f}:{node.lineno} possibly unused: def {node.name}()')
    except: pass
" "$TARGET"
```

### 3. Unused files
```bash
# Find .py files not imported anywhere
for f in $(find $TARGET -name "*.py" ! -name "__init__.py" ! -name "test_*"); do
    module=$(basename "$f" .py)
    imports=$(grep -r "import.*$module\|from.*$module" $TARGET --include="*.py" -l | grep -v "$f" | wc -l)
    if [ "$imports" -eq 0 ]; then
        echo "  $f: not imported anywhere"
    fi
done
```

## Rules
- Never auto-delete. Report findings for human review.
- `__init__.py` re-exports are NOT dead code (they're public API).
- Test files are never dead code.
- CLI entry points (`if __name__ == "__main__"`) may look unused but aren't.
- Functions with `@property`, `@staticmethod`, `@classmethod` may be called dynamically.
