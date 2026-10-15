---
name: ui-audit
description: Audit UI code for quality — scores against the vibe-coded→engineered spectrum (60-point scale)
version: 1.0.0
execution-mode: advisory
argument-hint: <path> (defaults to $PROJECT_ROOT/dashboard/web/)
category: governance-compliance
status: candidate
---
# UI Audit

Score UI code against the vibe-coded → engineered spectrum.

## Usage

```bash
[ui-audit]                          # Audit the dashboard
[ui-audit] $PROJECT_ROOT/dashboard/web/components/  # Specific directory
[ui-audit] output/target.tsx    # Single file
```

## Execution

### 1. Resolve target path
Default: `$PROJECT_ROOT/dashboard/web/`
If `$ARGUMENTS` provided, use that path.

### 2. Run the audit engine

```python
from your_project.modules.domain.ui_arbiter import run_audit
result = run_audit(target_path)
```

Run this via Bash:
```bash
python3 -c "
from your_project.modules.domain.ui_arbiter import run_audit
result = run_audit('TARGET_PATH')
print(result.summary)
print()
for f in result.findings:
    icon = '✓' if f.score == 2 else ('⚠' if f.score == 1 else '✗')
    print(f'  {icon} {f.criterion}: {f.message}')
    if f.evidence:
        print(f'    Evidence: {f.evidence}')
print()
print(f'Files scanned: {result.files_scanned}')
print(f'Grade: {result.grade.value} ({result.total_score}/{result.max_score})')
"
```

### 3. Format output

```
UI Audit | <target> | Grade <X> (<score>/<max>)
═══════════════════════════════════════════════

## Score Breakdown
| Category       | Score | Max | Status |
|----------------|-------|-----|--------|
| Foundation     | X     | 16  | ✓/⚠/✗  |
| States         | X     | 12  | ✓/⚠/✗  |
| Interaction    | X     | 12  | ✓/⚠/✗  |
| Accessibility  | X     | 8   | ✓/⚠/✗  |
| Performance    | X     | 6   | ✓/⚠/✗  |
| Craft          | X     | 6   | ✓/⚠/✗  |

## Failures (must fix)
- ✗ <criterion>: <message>
  Evidence: <evidence>

## Warnings (should fix)
- ⚠ <criterion>: <message>

## Passing
- ✓ <criterion>: <message>

## Grade Scale
F (0-15): Vibe-coded — unreviewed AI output
D (16-25): Lightly edited — some customization
C (26-35): Functional — works but lacks craft
B (36-45): Professional — intentional decisions
A (46-55): Engineered — design system, states, a11y
S (56-60): Craft-grade — Linear/Vercel tier
```

## Constraints
- Read-only analysis. Does not modify files.
- Static analysis only — cannot render or screenshot.
- Calibrated for React + Tailwind + shadcn stack.
- False positives possible on component libraries (shadcn ui/ directory).
