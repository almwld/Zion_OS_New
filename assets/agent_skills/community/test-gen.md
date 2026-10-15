---
name: test-gen
description: Generate test scaffolding from source code or specs. Creates test files, fixtures, and test cases by analyzing existing code.
version: 0.1.0
execution-mode: advisory
argument-hint: "<module path or function name> [--type unit|integration|property] [--framework pytest|unittest]"
category: dev-tools
status: candidate
---
# Test Gen Command

Generate test scaffolding from source code or specifications. Analyzes existing
code to produce test files, fixtures, and test cases that follow the repo's
existing test conventions.

## When to Use

- New module or function with no tests yet
- Coverage gap identified by `[coverage]` skill
- After adding a new feature that needs test scaffolding
- Onboarding to a repo with established test patterns
- Before a PR to ensure new code has test coverage

## Usage

```bash
[test-gen] src/mymodule.py                    # Generate tests for a module
[test-gen] src/mymodule.py::MyClass.method    # Generate tests for a specific method
[test-gen] src/mymodule.py --type property    # Generate property-based tests
[test-gen] src/mymodule.py --type integration # Generate integration test scaffolding
[test-gen] src/mymodule.py --framework unittest  # Force unittest instead of pytest
```

## Execution

### Phase 1: Analyze target

1. **Parse the target** — read the source file and identify:
   - Public functions and classes (skip `_private` unless `--include-private`)
   - Method signatures, type hints, docstrings
   - Exceptions raised, return types
   - Dependencies (imports that would need mocking)

2. **Detect repo conventions**:
   ```bash
   # Framework
   grep -l 'import pytest' $PROJECT_ROOT/tests/*.py 2>/dev/null | head -1 && echo "pytest" || echo "unittest"
   # Test directory structure
   ls -d $PROJECT_ROOT/tests/*/ 2>/dev/null | xargs -I{} basename {}
   # Naming pattern
   ls $PROJECT_ROOT/tests/test_*.py 2>/dev/null | head -3
   # Fixture patterns
   grep -rh '@pytest.fixture' $PROJECT_ROOT/tests/ 2>/dev/null | head -5
   # conftest.py
   [ -f $PROJECT_ROOT/tests/conftest.py ] && echo "has conftest"
   ```

3. **Read existing tests** in the same module's test directory (if any) to
   match style: assertion style, fixture patterns, naming, imports.

### Phase 2: Generate test file

1. **Create the test file** at `$PROJECT_ROOT/tests/test_<module>.py` (or
   the repo's convention if different).

2. **Generate test cases** for each public function/method:
   - **Happy path**: typical input → expected output
   - **Edge cases**: empty input, boundary values, None, empty string
   - **Error cases**: invalid input → expected exception
   - **Type errors**: wrong type input → TypeError (if type hints present)

3. **Generate fixtures** for complex dependencies:
   - Use `@pytest.fixture` for pytest repos
   - Use `setUp`/`tearDown` for unittest repos
   - Mock external dependencies (network, file I/O, DB)

4. **Property-based tests** (when `--type property`):
   - Use Hypothesis if available: `from hypothesis import given, strategies as st`
   - Generate strategies from type hints
   - Test invariants rather than specific values

### Phase 3: Verify

1. **Run the generated tests**:
   ```bash
   python -m pytest $PROJECT_ROOT/tests/test_<module>.py -v --tb=short
   ```

2. **Hard gate**: Tests must at least collect without errors. Tests that
   fail on assertions are OK (they're scaffolding for the developer to
   fill in expected values). Collection errors mean the test file has
   import or syntax problems that must be fixed.

3. **Report coverage delta**:
   ```bash
   python -m pytest $PROJECT_ROOT/tests/test_<module>.py --cov=<module> --cov-report=term-missing 2>/dev/null
   ```

## Output Format

```
Test Gen | <target>
═══════════════════════════════════════════════
Framework:     <pytest | unittest>
Test file:     <path>
Test cases:    <count>
  - happy path:  <count>
  - edge cases:  <count>
  - error cases: <count>
  - property:    <count> (if --type property)
Fixtures:      <count>
Mocks:         <count>
Coverage:      <module % before> → <module % after>
Status:        <PASS | FAIL | PARTIAL>
```

## Generation Rules

1. **Match existing style**: Read sibling test files first. If the repo uses
   `assert x == y`, don't use `self.assertEqual(x, y)`. If it uses
   `pytest.raises`, don't use `assertRaises`.

2. **Don't generate trivial tests**: Skip `test_init` for dataclasses with no
   logic. Skip `test_repr` unless the repr has custom logic.

3. **Use type hints for test generation**: If `def foo(x: int) -> str:`, generate
   tests with int inputs and str assertions. If no type hints, use generic
   strategies.

4. **Mock at the boundary**: Mock network calls, file I/O, DB queries, and
   external service calls. Don't mock the module under test.

5. **Generate TODO markers for expected values**: When the correct expected
   value isn't determinable from the source, use:
   ```python
   # TODO: verify expected value
   assert result == <expected>
   ```

6. **Respect `--framework` flag**: Default to the repo's detected framework.
   Only override if `--framework` is explicitly passed.

7. **Don't overwrite existing tests**: If `test_<module>.py` exists, append
   new test cases or create `test_<module>_generated.py` with a comment
   pointing to the original.

## Limitations

- Cannot generate tests for code that requires complex runtime state (e.g.,
  GPU initialization, hardware access, network services)
- Property-based tests require Hypothesis to be installed
- Cannot determine expected values for functions with side effects — generates
  TODO markers instead
- Does not generate integration test environments (docker-compose, testcontainers)
- Does not generate mock servers or fixtures for external APIs
