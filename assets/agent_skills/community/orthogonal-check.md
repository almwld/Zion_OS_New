---
name: orthogonal-check
description: Verify that system components vary independently -- no hidden coupling or unintended correlation. Maps to DE17.
version: 0.1.0
execution-mode: advisory
argument-hint: <two systems or features to check for independence>
category: dev-tools
status: candidate
---
# Orthogonal Check (DE17: Orthogonalization)

Verify that components that SHOULD be independent actually ARE independent. Hidden coupling is a source of cascading failures and unexpected behavior.

## When to Use
- After adding a new service (does it affect unrelated services?)
- After changing config (does BUS_SIGNING_SECRET affect non-bus code?)
- Verifying test isolation (does test A's setup leak into test B?)
- Checking feature flags (does enabling IDP affect non-IDP paths?)
- Validating agent isolation (does Gemini's failure affect Claude's workflow?)

## Execution

### 1. Identify the components
What two things SHOULD be independent?

```
A: Bus signing (BUS_SIGNING_SECRET)
B: Ledger writing (cognition/ledger_writer.py)
Hypothesis: A should not affect B
```

### 2. Test independence

**Method 1: Config toggle**
```bash
# Run with A enabled
BUS_SIGNING_SECRET="test" python -m pytest tests/unit/test_cognition_ledger.py -q

# Run with A disabled
BUS_SIGNING_SECRET="" python -m pytest tests/unit/test_cognition_ledger.py -q

# Results should be identical
```

**Method 2: Failure injection**
```bash
# Break A, verify B still works
# (e.g., corrupt bus file, verify ledger still writes)
```

**Method 3: Import analysis**
```bash
# Check if A and B share any imports beyond stdlib
python3 -c "
import ast
a_imports = set()
b_imports = set()
for n in ast.walk(ast.parse(open('bus/bus_writer.py').read())):
    if isinstance(n, ast.ImportFrom) and n.module:
        a_imports.add(n.module)
for n in ast.walk(ast.parse(open('cognition/ledger_writer.py').read())):
    if isinstance(n, ast.ImportFrom) and n.module:
        b_imports.add(n.module)
shared = a_imports & b_imports - {'__future__', 'os', 'json', 'logging', 'pathlib'}
print(f'Shared non-stdlib imports: {shared or \"none\"}')"
```

### 3. Grade orthogonality

| Grade | Meaning |
|-------|---------|
| **Fully orthogonal** | Changing A has zero effect on B |
| **Weakly coupled** | Changing A affects B's performance but not correctness |
| **Coupled** | Changing A can break B |
| **Entangled** | A and B cannot be understood independently |

## Output Format
```
Orthogonal Check | A: <component> vs B: <component>
════════════════════════════════════════════════════

Hypothesis: A and B are independent

## Test Results
| Method | A state | B behavior | Independent? |
|--------|---------|------------|:---:|
| Config toggle | enabled | <result> | Y/N |
| Config toggle | disabled | <result> | Y/N |
| Failure injection | A broken | B works? | Y/N |

## Grade: [ORTHOGONAL | WEAKLY COUPLED | COUPLED | ENTANGLED]

## Coupling Points (if any)
- <shared resource or dependency>

## Fix (if coupled)
- <how to decouple>
```

## Base120 Context
- Primary: **DE17** (Orthogonalization)
- Related: **DE3** (Modularization), **DE14** (Variable Control), **SY2** (System Boundaries)
