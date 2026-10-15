---
name: hummbl-free-models
description: HUMMBL Open-Weights & Free-Tier Model Registry Generator
version: 0.1.0
execution-mode: advisory
argument-hint: "[generate.py | validate.py | crawl.py | --provider groq | --family llama]"
category: governance-compliance
status: candidate
---
# HUMMBL Free Models

HUMMBL Open-Weights & Free-Tier Model Registry Generator. Generates and maintains a registry of real (model × provider) pairs — every combination of model family, parameter size, variant, and provider that serves traffic on a free tier. Includes a live crawler to verify and extend the registry against provider `/models` endpoints.

## When to Use

- Generating the full free-model registry from curated taxonomy YAML files
- Validating the registry for required fields, uniqueness, and referential integrity
- Crawling live provider `/models` endpoints to verify and discover new free models
- Filtering models by provider, family, size, or variant
- Producing TypeScript exports of the registry for frontend consumption

## Usage

```bash
[hummbl-free-models] python -m hummbl_free_models.generate
[hummbl-free-models] python -m hummbl_free_models.generate --dry-run
[hummbl-free-models] python -m hummbl_free_models.generate --provider groq --family llama
[hummbl-free-models] python -m hummbl_free_models.validate
[hummbl-free-models] python -m hummbl_free_models.validate --verbose --strict
[hummbl-free-models] python -m hummbl_free_models.crawl
[hummbl-free-models] python -m hummbl_free_models.crawl --provider groq --stats
```

## Python API

```python
from hummbl_free_models.generate import (
    generate_registry,
    compose_entry,
    compose_id,
    compose_slug,
    merge_registries,
    load_existing,
)
from hummbl_free_models.validate import (
    validate,
    REQUIRED_FIELDS,
    BOOLEAN_FIELDS,
)
from hummbl_free_models.crawl import (
    crawl_provider,
    crawl_all,
    match_to_registry,
    fetch_json,
    infer_family_from_slug,
    infer_size_from_slug,
    infer_variant_from_slug,
)
```

## Key Concepts

- **Compositional axes**: Registry entries are composed from 5 axes — family (llama, qwen, gemma...), size (7B, 70B...), variant (instruct, chat, vision, reasoning, code...), provider (groq, sambanova, openrouter-free...), and capabilities (multimodal, function_calling, search_grounding...).
- **Curated taxonomy**: `data/providers.yaml` and `data/families.yaml` define the known model universe. Every registry entry must correspond to a real model endpoint.
- **Generation**: `generate_registry()` composes all valid (family × size × variant × provider) tuples. Idempotent on IDs — never overwrites existing entries. Merges with existing registry to preserve `verified` flags.
- **Validation**: `validate()` checks required fields, unique IDs, unique slugs per provider, valid API compat types, valid free-tier types, positive context windows, and boolean field types.
- **Crawler**: `crawl.py` fetches live `/models` endpoints, matches against the curated registry (exact, partial, keyword), marks entries as `verified=True`, and discovers new models not in the taxonomy (source=`"crawler"`).
- **Output**: Registry written to `registry/registry.json` and `registry/registry.ts` (TypeScript export with `ModelEntry` interface).
- **Free-tier types**: `permanent` (always free), `trial_credits` (free with trial credits), `freemium` (free tier with paid upgrades).

## Install

```bash
cd /work/active/oss/packages/python/hummbl-free-models/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-free-models/`
- **License**: MIT OR Apache 2.0
- **Dependencies**: `pyyaml>=6.0` (runtime)
