---
name: governed-compression
description: Governed compression experiments — quantization and approximation primitives with governance receipts
version: 0.1.0
execution-mode: advisory
argument-hint: "[governed-compression] <import CompressionConfig, quantize_reference, mean_squared_error>"
category: governance-compliance
status: candidate
---
# governed-compression

Governed compression experiments — quantization and approximation primitives with governance receipts. Provides CPU reference baselines, experiment run logging, and distortion metrics for compression research.

## When to Use

- You need a CPU reference quantization baseline for compression experiments
- You want to compute distortion metrics (MSE) between reference and compressed vectors
- You need to log compression experiment runs as structured tuples
- You want to configure compression methods with governance-aware parameters
- You are building compression benchmarks that require numpy array operations

## Usage

```bash
governed-compression
```

## Python API

```python
from governed_compression.core.config import CompressionConfig, DEFAULT_CONFIG
from governed_compression.core.reference import quantize_reference, approximate_dot
from governed_compression.experiment.tuples import CompressionRun
from governed_compression.bench.distortion import mean_squared_error
```

## Key Concepts

- **CompressionConfig**: Frozen dataclass with method, bits_per_channel, residual_enabled; validates bits_per_channel ≥ 0
- **quantize_reference()**: Trivial reference quantizer — maps 1D vector to discrete levels based on bits_per_channel; provides a correctness anchor and benchmark baseline
- **approximate_dot()**: Computes dot product in float32 for approximate comparison
- **CompressionRun**: Frozen dataclass for experiment logging (run_id, method, bits_per_channel, dataset, benchmark)
- **mean_squared_error()**: Distortion metric between reference and candidate numpy arrays
- **CLI**: Scaffold-only (`governed-compression` prints readiness message)

## Install

```bash
cd /work/active/oss/packages/python/governed-compression/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/governed-compression/`
- **License**: Apache-2.0
- **Dependencies**: numpy>=2.4.6, hummbl-governance>=1.4.2 (intentional exception to stdlib-only convention)
