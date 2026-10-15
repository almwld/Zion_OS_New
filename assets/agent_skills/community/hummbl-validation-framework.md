---
name: hummbl-validation-framework
description: HUMMBL Validation Framework — external validation tests for the design system
version: 0.1.0
execution-mode: advisory
argument-hint: "[command]"
category: governance-compliance
status: candidate
---
# Hummbl Validation Framework

HUMMBL Validation Framework — external validation tests for the design system

## When to Use

- When you need to use hummbl-validation-framework
- See the package README for detailed use cases

## Usage

```bash
[hummbl-validation-framework] <command>
```

## Python API

```python
from hummbl_validation_framework import TestStatus, ValidationResult, ValidationSuite, ValidationTest, add_result, all_complete, average_score, create_api_correlation_test, create_color_identification_test, create_heraldic_recognition_test  # + 17 more
```

## Install

```bash
cd /work/active/oss/packages/python/hummbl-validation-framework/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-validation-framework/`
- **License**: Apache 2.0
- **Dependencies**: requires: pytest, https, https, hummbl_validation_framework, tests
