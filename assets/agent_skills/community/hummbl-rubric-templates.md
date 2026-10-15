---
name: hummbl-rubric-templates
description: HUMMBL Standard Evaluation Rubric Templates & Automated Validators
version: 0.1.0
execution-mode: advisory
argument-hint: "[hummbl-rubric-templates] validate template.yaml | validate --all"
category: governance-compliance
status: candidate
---
# hummbl-rubric-templates

HUMMBL Standard Evaluation Rubric Templates & Automated Validators. Validates rubric templates against the master schema to ensure YAML validity, required field presence, weight sum validation, scoring anchor completeness, and hard gate configuration validity.

## When to Use

- You need to validate a rubric template YAML file against the HUMMBL master schema
- You want to batch-validate all templates in the templates directory
- You need to check that weighted dimensions sum to 100 and have complete scoring anchors
- You want to verify hard gate configuration (fail_condition, max_score_if_failed, severity)
- You need to ensure required outputs are present (numeric_score, hard_gate_status, weighted_breakdown, etc.)

## Usage

```bash
python -m hummbl_rubric_templates.validate_template template.yaml
python -m hummbl_rubric_templates.validate_template --all
```

## Python API

```python
from hummbl_rubric_templates.validate_template import (
    validate_template, load_yaml_file,
    validate_parameters, validate_hard_gates,
    validate_weighted_dimensions, validate_required_outputs,
)
```

## Key Concepts

- **validate_template()**: Main entry point — takes a `Path`, returns `(bool, List[str])` (is_valid, errors)
- **Parameters**: Required fields include context_name, framework_reference, evaluation_scope, artifact_types
- **Hard gates**: Each gate requires fail_condition, max_score_if_failed (0–100), and severity (critical/high/medium/low)
- **Weighted dimensions**: Each dimension needs weight, description, and scoring_anchors; total weight must equal 100
- **Required outputs**: numeric_score, hard_gate_status, weighted_breakdown, top_3_strengths, top_3_weaknesses, score_caps_triggered, next_validation_test, limitations
- **Evaluation scopes**: single_document, multi_phase, fleet_wide, cross_repo

## Install

```bash
cd /work/active/oss/packages/python/hummbl-rubric-templates/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-rubric-templates/`
- **License**: MIT OR Apache-2.0
- **Dependencies**: pyyaml>=6.0 (runtime)
