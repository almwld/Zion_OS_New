---
name: hummbl-validation
description: HUMMBL validation framework — invariant checks, schema validation, external validation tests for the design system. Ensures governance contracts and schemas are correct.
version: 0.1.0
execution-mode: advisory
argument-hint: "[validate SCHEMA.json | invariants | test-suite | design-system]"
category: governance-compliance
status: candidate
---
# HUMMBL Validation

Invariant and schema validation primitives for the HUMMBL fleet. Provides stdlib-only JSON Schema validation, invariant checking, and external validation tests for the design system.

## When to Use

- Validating governance contracts against their JSON Schema
- Checking invariants on governance tuples
- Running the design system validation test suite
- Validating agent identity data
- Ensuring contract schemas are correct before deployment

## Usage

```bash
[hummbl-validation] validate contract.json
[hummbl-validation] invariants --tuples tuples.json
[hummbl-validation] test-suite --package design-tokens
[hummbl-validation] design-system --full
```

## Python API

```python
from hummbl_validation import (
    SchemaValidator,
    InvariantChecker,
    ValidationResult,
)

# Validate a JSON document against a schema
validator = SchemaValidator()
result = validator.validate(document, schema)
if not result.valid:
    for error in result.errors:
        print(f"  {error.path}: {error.message}")

# Check invariants
checker = InvariantChecker()
violations = checker.check(tuples)
```

## Install

```bash
cd /work/active/oss/packages/python/hummbl-validation
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-validation/`
- **License**: Apache 2.0
- **Dependencies**: stdlib only
