---
name: hummbl-tuples
description: HUMMBL Typed Tuples governance model
version: 0.2.0
execution-mode: advisory
argument-hint: "[TypedTuple | IDPTuple | ContractTuple | DCTTuple | NodezeroTuple]"
category: governance-compliance
status: candidate
---
# HUMMBL Tuples

HUMMBL Typed Tuples governance model. Provides a typed tuple framework for agent governance, delegation, evidence, and audit across the HUMMBL ecosystem. Tuples are structured dataclass-like records that carry provenance and type information for multi-agent coordination.

## When to Use

- Creating typed governance records (contracts, evidence, attestations)
- Issuing delegation capability tokens (DCT, DCTX) with cryptographic binding
- Recording BaseN experiment tuples (model candidates, transformations, reasoning paths)
- Tracking remote-node experiment control (base profiles, control modes, registry pins)
- Managing trace artifacts (pretraining, posttraining) with typed provenance

## Usage

```bash
[hummbl-tuples] ContractTuple(contract_id="c-001", ...)
[hummbl-tuples] DCTTuple(token_id="t-001", issuer="devin", ...)
[hummbl-tuples] ModelCandidateTuple(model_id="qwen-32b", ...)
```

## Python API

```python
from hummbl_tuples import (
    # Base classes
    TypedTuple,
    IDPTuple,
    BaseNTuple,
    NodezeroTuple,
    NodezeroExperimentTuple,
    TraceArtifact,
    # IDP governance tuples
    ContractTuple,
    DCTTuple,
    DCTXTuple,
    PromotionReceiptTuple,
    RevocationTuple,
    EvidenceTuple,
    AttestTuple,
    SystemTuple,
    # BaseN experiment tuples
    ModelCandidateTuple,
    ModelSelectedTuple,
    TransformationCandidateTuple,
    TransformationSelectedTuple,
    HitlOverrideTuple,
    ReasoningPathTuple,
    PathComparisonTuple,
    TraceEvidenceTuple,
    # remote-node experiment-control tuples
    BaseProfileIssuedTuple,
    ControlModeSetTuple,
    ExperimentRunAssignedTuple,
    RegistryVersionPinnedTuple,
    # Trace artifacts
    PretrainingTrace,
    PosttrainingTrace,
)
```

## Key Concepts

- **TypedTuple**: Base class for all typed governance records — provides type-safe fields, serialization, and provenance tracking.
- **IDP governance tuples**: The delegation chain — `DCTXTuple` (context) → `ContractTuple` (contract) → `EvidenceTuple` (evidence) → `AttestTuple` (attestation) → `DCTTuple` (capability token) → governance bus. Plus `PromotionReceiptTuple` and `RevocationTuple` for lifecycle management.
- **BaseN experiment tuples**: Model selection and transformation tracking — `ModelCandidateTuple`, `ModelSelectedTuple`, `TransformationCandidateTuple`, `TransformationSelectedTuple`, `HitlOverrideTuple`, `ReasoningPathTuple`, `PathComparisonTuple`, `TraceEvidenceTuple`.
- **remote-node control tuples**: Experiment control plane — `BaseProfileIssuedTuple`, `ControlModeSetTuple`, `ExperimentRunAssignedTuple`, `RegistryVersionPinnedTuple`.
- **Trace artifacts**: `PretrainingTrace`, `PosttrainingTrace`, `TraceArtifact` for model training provenance.
- **governance.yml**: Package includes a `governance.yml` config file defining tuple schemas and validation rules.

## Install

```bash
cd /work/active/oss/packages/python/hummbl-tuples/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-tuples/`
- **License**: Apache 2.0
- **Dependencies**: stdlib only
