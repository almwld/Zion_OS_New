---
name: pattern-tile
description: Identify repeating patterns in code/architecture and extract reusable templates. Maps to CO11.
version: 0.1.0
execution-mode: advisory
argument-hint: <codebase area to analyze for patterns>
category: dev-tools
status: candidate
---
# Pattern Tile (CO11: Pattern Composition / Tiling)

Find repeating structural patterns in the codebase and extract them into reusable templates or abstractions.

## When to Use
- Noticing the same code structure in multiple adapters
- Seeing similar test patterns repeated across files
- Finding copy-paste patterns that should be a shared utility
- Designing a new module that follows existing conventions

## Execution

### 1. Identify candidate patterns
Look for structural repetition:

```bash
# Find similar function signatures across files
python3 -c "
import ast
from pathlib import Path
from collections import Counter

patterns = Counter()
for f in Path('${TARGET:-services}').rglob('*.py'):
    if '.venv' in str(f): continue
    try:
        tree = ast.parse(f.read_text())
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                # Extract pattern: (arg_count, has_try, has_return, has_logging)
                arg_count = len(node.args.args)
                has_try = any(isinstance(n, ast.Try) for n in ast.walk(node))
                has_return = any(isinstance(n, ast.Return) for n in ast.walk(node))
                pattern = f'args={arg_count},try={has_try},return={has_return}'
                patterns[pattern] += 1
    except: pass
for p, c in patterns.most_common(5):
    print(f'  {c:3d}x {p}')
"
```

### 2. Extract the repeating tile
What's the minimal reusable unit?

**Common tiles in this codebase:**
- **Adapter pattern**: try/except + circuit breaker + fallback data + DCT delegation
- **Health probe pattern**: check condition + return status dict + timeout handling
- **CLI entry point pattern**: argparse + main() + if __name__ == "__main__"
- **Test pattern**: _make_fixture() + TestClass + happy path + error path + edge case
- **Bus write pattern**: validate + escape + flock + append + harden permissions

### 3. Decide: extract or document?

| Repetition Count | Action |
|-----------------|--------|
| 2x | Document the pattern (don't abstract yet) |
| 3-4x | Consider extraction if the pattern is stable |
| 5+x | Extract into a shared utility or base class |

### 4. If extracting
- Create the shared utility with the MINIMAL interface
- Migrate ONE consumer first, verify tests pass
- Then migrate the rest one at a time
- Three similar lines is better than a premature abstraction

## Output Format
```
Pattern Tile | <target>
═════════════════════════

## Detected Patterns
| Pattern | Count | Files |
|---------|-------|-------|
| <description> | Nx | <file list> |

## Recommended Extractions
- <pattern>: extract to <location> (N consumers)

## Templates
<reusable template for each pattern>
```

## Base120 Context
- Primary: **CO11** (Pattern Composition / Tiling)
- Related: **RE5** (Fractal Reasoning), **DE3** (Modularization), **CO2** (Chunking)
