---
name: bulk-edit
description: Apply the same edit across many files safely -- find, preview, apply, verify.
version: 0.1.0
execution-mode: remedial
argument-hint: "\"PATTERN\" \"REPLACEMENT\" [in DIRECTORY]"
category: dev-tools
status: candidate
---
# Bulk Edit

Apply a consistent change across multiple files with preview and verification.

## Execution

### 1. Find affected files
```bash
grep -rl "PATTERN" DIRECTORY --include="*.py" | head -20
echo "---"
grep -rc "PATTERN" DIRECTORY --include="*.py" | grep -v ":0$" | sort
```

### 2. Preview the change
Show what will change WITHOUT modifying:
```bash
grep -rn "PATTERN" DIRECTORY --include="*.py" | head -20
```

### 3. Show the user the plan
```
Bulk Edit Plan
══════════════
Pattern: "OLD"
Replacement: "NEW"
Files affected: N
Total occurrences: M

Preview (first 5):
  file1.py:42: <before> -> <after>
  file2.py:17: <before> -> <after>
  ...

Proceed? [Y/n]
```

### 4. Apply (after approval)
```bash
# macOS sed (BSD):
find DIRECTORY -name "*.py" -exec sed -i '' 's/OLD/NEW/g' {} +

# Or Python for complex replacements:
python3 -c "
from pathlib import Path
for f in Path('DIRECTORY').rglob('*.py'):
    text = f.read_text()
    if 'OLD' in text:
        f.write_text(text.replace('OLD', 'NEW'))
        print(f'  Updated: {f}')
"
```

### 5. Verify
```bash
# Check no OLD pattern remains
grep -r "OLD" DIRECTORY --include="*.py" | head -5
# Should return nothing

# Run affected tests
python -m pytest DIRECTORY -q --tb=short
```

## Rules
- ALWAYS preview before applying
- ALWAYS get user approval for >5 files
- ALWAYS run tests after applying
- Never bulk-edit files you haven't grepped first
- For regex replacements, test the regex on ONE file first
- Keep a record of what was changed for git commit message

## Common Patterns
| Task | Pattern | Replacement |
|------|---------|-------------|
| Rename function | `old_name(` | `new_name(` |
| Update import | `from old.module` | `from new.module` |
| Change permission mode | `0o600` | `0o660` |
| Fix version string | `version: 0.1.0---` | `version: 0.1.0\n---` |
