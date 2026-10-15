---
name: model-lifecycle
description: Track new model releases, vendor deprecations/sunsets, and component topologies (kernels, harnesses, skills, engines).
version: 1.0.0
execution-mode: advisory
argument-hint: "[--crawl | --audit | --summary]"
category: model-operations
status: active
---
# Model Lifecycle & Component Topology Engine

A continuous discovery, audit, and governance system tracking all foundation models worldwide, their lifecycle states (Active GA, Deprecated, Sunset, Unmaintained), and their complete component topologies:
- **Engines / Runtimes**: Cloud APIs, Wafer-Scale LPUs (Cerebras), LPUs (Groq), local runtimes (vLLM, Ollama)
- **Acceleration Kernels**: FlashAttention-3, Triton/CuTile, CUDA-Q quantum hybrid, TensorRT-LLM FP8
- **Evaluation Harnesses**: Base120 Hexad (`scripts/hexad_harness.py`), Global BHRI Matrix (`scripts/global_hexad_matrix.py`), Vendor Gen Eval (`scripts/vendor_gen_eval.py`)
- **Fleet Skills**: `base120`, `vendor-gen-eval`, `cudaq-guide`, `model-router`, `model-card`

## When to Use

- When surveying the worldwide model landscape to detect newly released models across all vendors.
- When verifying whether a model has been deprecated, scheduled for shutdown, or sunset by its vendor.
- When determining which kernels, harnesses, and skills are required to execute, accelerate, and evaluate a specific model.
- Before benchmarking a newly released model in the Global Base120 Hexad Evaluation Matrix.
- To produce refreshed human-readable and machine-readable markdown/JSON audits for CI and stakeholders.

## CLI Usage

```bash
# Ingest live catalog across OpenRouter (450+ models), Cerebras, Anthropic, and update registries
python scripts/model_lifecycle_engine.py --crawl

# Audit lifecycle status, flag vendor deprecations and sunset timelines
python scripts/model_lifecycle_engine.py --audit

# Print estate summary
python scripts/model_lifecycle_engine.py --summary
```

## Key Output Artifacts

- `registry/models/canonical_models.json`: Full canonical inventory of models with context lengths, architectures, and pricing.
- `registry/models/lifecycle.json`: Lifecycle registry tracking status, sunset dates, and replacement models.
- `registry/models/topology.json`: Component mapping linking every model to its engines, kernels, harnesses, and skills.
- `docs/research/models/GLOBAL_MODEL_REGISTRY.md`: Human-readable markdown catalog organized by vendor.
- `docs/research/models/LIFECYCLE_RADAR.md`: Radar of recent releases and sunset/deprecated models.
- `docs/research/models/COMPONENT_TOPOLOGY.md`: Full cross-reference table of model-to-component mappings.

## Python API

```python
from scripts.model_lifecycle_engine import (
    crawl_openrouter_catalog,
    crawl_cerebras_catalog,
    crawl_anthropic_catalog,
    infer_component_topology,
    run_lifecycle_engine,
)

# Run full crawl and registry sync
stats = run_lifecycle_engine(crawl_live=True)
print(f"Tracked {stats['total_models']} models worldwide.")
```

## Skill Chains

### Mandatory

None — this skill provides discovery and lifecycle monitoring.

### Advisory

- Model discovery → `[model-router]` or `[vendor-gen-eval]`
- Flagged deprecations → `[deprecation-track]`

