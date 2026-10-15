---
name: hummbl-lint-config
description: Shared ruff lint configuration for the HUMMBL fleet
version: 0.1.0
execution-mode: advisory
argument-hint: "[hummbl-lint-config] <extend ruff.toml in your project's ruff config>"
category: governance-compliance
status: candidate
---
# hummbl-lint-config

Shared ruff lint configuration for the HUMMBL fleet. Provides a centralized `ruff.toml` that repos extend to get consistent lint rules across all HUMMBL Python packages.

## When to Use

- You need consistent ruff lint rules across a HUMMBL Python project
- You want to extend a shared baseline config rather than duplicating lint settings
- You need pyupgrade, isort, simplification, and error-handling lint rules pre-configured
- You want per-file ignores for tests and evals (magic numbers allowed)

## Usage

```bash
# In your project's ruff.toml or pyproject.toml [tool.ruff] section:
# extend = "hummbl-lint-config/ruff.toml"
# Or after pip install:
# extend = "hummbl_lint_config/ruff.toml"
```

## Python API

```python
# This is a configuration package, not a runtime library.
# Import the ruff.toml path:
from hummbl_lint_config import __doc__
import hummbl_lint_config
from pathlib import Path
ruff_toml = Path(hummbl_lint_config.__file__).parent / "ruff.toml"
```

## Key Concepts

- **ruff.toml**: The shared configuration file — target-version py311, line-length 120
- **Selected rules**: PLW1514 (missing encoding on open), B904 (raise from err), SIM (simplifications), I (isort), UP (pyupgrade)
- **Ignored rules**: SIM108 (if-else to ternary), SIM117 (nested with statements) — for readability
- **Per-file ignores**: tests/* and evals/* allow PLR2004 (magic numbers)
- **Usage pattern**: Extend from the installed package path or direct file path in your project's ruff config

## Install

```bash
cd /work/active/oss/packages/python/hummbl-lint-config/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-lint-config/`
- **License**: MIT OR Apache-2.0
- **Dependencies**: stdlib only (ruff is used by consuming projects, not a runtime dependency)
