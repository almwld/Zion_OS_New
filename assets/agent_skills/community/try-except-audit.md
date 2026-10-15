---
name: try-except-audit
description: Audit exception handling for overly broad catches, swallowed errors, and missing context.
version: 0.1.0
execution-mode: advisory
argument-hint: <directory or file to audit>
category: dev-tools
status: candidate
---
# Try-Except Audit

Find problematic exception handling patterns that hide bugs.

## What to Flag

### Critical (likely hiding bugs)
- `except Exception:` with no re-raise or logging
- `except:` (bare except -- catches SystemExit, KeyboardInterrupt)
- `except Exception as e: pass` (swallowed error)
- `except Exception as e: return None` (silent failure)

### Warning (may be intentional but risky)
- `except Exception:` spanning more than 5 lines of try block
- `except (TypeError, ValueError, KeyError, ...):` with 4+ exception types
- `except Exception as e: logger.warning(...)` without re-raise (logs but continues)
- Nested try/except blocks (complexity smell)

### Info (style improvements)
- `except Exception as e:` where a more specific exception is appropriate
- Try block covering an entire function body
- Except block that's longer than the try block

## Execution

```bash
python3 -c "
import ast, sys
from pathlib import Path

target = sys.argv[1] if len(sys.argv) > 1 else '.'
for f in sorted(Path(target).rglob('*.py')):
    if '.venv' in str(f) or '__pycache__' in str(f): continue
    try:
        tree = ast.parse(f.read_text())
        for node in ast.walk(tree):
            if isinstance(node, ast.ExceptHandler):
                handler_body = ast.dump(node)
                if node.type is None:
                    print(f'  CRITICAL {f}:{node.lineno} bare except (catches SystemExit)')
                elif isinstance(node.type, ast.Name) and node.type.id == 'Exception':
                    # Check if body is just pass
                    if len(node.body) == 1 and isinstance(node.body[0], ast.Pass):
                        print(f'  CRITICAL {f}:{node.lineno} except Exception: pass (swallowed)')
                    elif not any(isinstance(n, ast.Raise) for n in ast.walk(ast.Module(body=node.body, type_ignores=[]))):
                        print(f'  WARNING {f}:{node.lineno} except Exception without re-raise')
    except: pass
" "$TARGET"
```

## Output Format
```
Try-Except Audit | <target>
════════════════════════════

CRITICAL: N findings (likely hiding bugs)
WARNING: N findings (risky patterns)
INFO: N findings (style improvements)

## Critical Findings
- <file:line>: <description>

## Recommendations
- <specific fixes>
```
