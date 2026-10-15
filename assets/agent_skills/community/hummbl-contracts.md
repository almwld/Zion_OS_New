---
name: hummbl-contracts
description: HUMMBL contract schemas and stdlib-only JSON Schema validator
version: 0.1.0
execution-mode: advisory
argument-hint: "[validate <file> <schema> | list_schemas | load_schema <name>]"
category: governance-compliance
status: candidate
---
# HUMMBL Contracts

HUMMBL contract schemas and stdlib-only JSON Schema validator. Provides a Draft 2020-12 subset validator with bundled contract schemas for the HUMMBL ecosystem across 8 domains: cognition, governance, foundry, idp, knowledge, lexicon, registry, and eal.

## When to Use

- Validating JSON instances against HUMMBL contract schemas
- Loading and listing bundled contract schemas by name
- Validating ledger entries or shared state dicts programmatically
- Validating files (instance + schema) from the command line
- Checking contract compliance for agent artifacts

## Usage

```bash
[hummbl-contracts] hummbl-contracts list
[hummbl-contracts] hummbl-contracts validate instance.json schema.json
[hummbl-contracts] hummbl-contracts validate-inline '{"key": "value"}'
```

## Python API

```python
from hummbl_contracts import (
    validate,
    validate_file,
    validate_entry_dict,
    validate_state_dict,
    load_schema,
    list_schemas,
    ValidationError,
)

# Validate an instance against a schema dict
errors = validate(instance, schema)

# Validate files
ok, errors = validate_file("instance.json", "schema.json")

# Validate entry/state dicts against bundled schemas
ok, errors = validate_entry_dict(entry_dict)
ok, errors = validate_state_dict(state_dict)

# Load and list bundled schemas
schema = load_schema("cognition.entry")
names = list_schemas()
```

## Key Concepts

- **Stdlib-only validator**: Implements a JSON Schema Draft 2020-12 subset using only Python stdlib — no `jsonschema` dependency required at runtime.
- **Bundled schemas**: 13 contract schemas across 8 domains (cognition, governance, foundry, idp, knowledge, lexicon, registry, eal) shipped with the package.
- **Validation functions**: `validate()` returns a list of error strings (empty = valid). `validate_file()` returns `(bool, list[str])` tuple. `validate_entry_dict()` and `validate_state_dict()` validate against bundled cognition schemas.
- **Schema loader**: `load_schema(name)` loads a bundled schema by name. `list_schemas()` returns all available schema names.
- **ValidationError**: Raised on validation failure when using the exception-based API.
- **CLI**: `hummbl-contracts` command provides `list`, `validate`, and `validate-inline` subcommands.

## Install

```bash
cd /work/active/oss/packages/python/hummbl-contracts/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-contracts/`
- **License**: MIT OR Apache 2.0
- **Dependencies**: stdlib only
