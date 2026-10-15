---
name: hummbl-taxonomy
description: HUMMBL Governed Intelligence Tier Taxonomy & Classifier
version: 0.1.0
execution-mode: advisory
argument-hint: "[hummbl-taxonomy] <import classify, ClassificationInput, ClassificationResult>"
category: governance-compliance
status: candidate
---
# hummbl-taxonomy

HUMMBL Governed Intelligence Tier Taxonomy & Classifier. Classifies intelligence artifacts into governed tiers using a deterministic classifier.

## When to Use

- You need to classify an intelligence artifact into a HUMMBL governed tier
- You want deterministic, reproducible classification results
- You need to integrate tier classification into a governance pipeline
- You want to validate that an artifact meets a specific tier's criteria

## Usage

```bash
# No CLI — use as a Python library
python -c "from hummbl_taxonomy import classify, ClassificationInput; print(classify(ClassificationInput(...)))"
```

## Python API

```python
from hummbl_taxonomy import ClassificationInput, ClassificationResult, classify
```

## Key Concepts

- **ClassificationInput**: Input dataclass representing the artifact to classify
- **ClassificationResult**: Output dataclass containing the determined tier and classification metadata
- **classify()**: Deterministic classifier function that maps a `ClassificationInput` to a `ClassificationResult`
- **Governed tiers**: The classifier maps artifacts into HUMMBL's governed intelligence tier hierarchy

## Install

```bash
cd /work/active/oss/packages/python/hummbl-taxonomy/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-taxonomy/`
- **License**: MIT OR Apache-2.0
- **Dependencies**: stdlib only
