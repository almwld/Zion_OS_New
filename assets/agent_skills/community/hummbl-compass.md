---
name: hummbl-compass
description: HUMMBL Directional Navigation & Multi-Agent Routing Algorithms
version: 0.1.0
execution-mode: advisory
argument-hint: "[Compass | route \"<query>\" | --by-base120 SY20 | --by-layer L5 | --gaps | --stats]"
category: governance-compliance
status: candidate
---
# HUMMBL Compass

HUMMBL Directional Navigation & Multi-Agent Routing Algorithms. A decision router for the hummbl-* repo ecosystem. Loads `hummbl-topology.json` and provides natural-language task routing, Base120 transformation lookup, layer-based filtering, bridge traversal, and gap reporting.

## When to Use

- Routing a natural-language task description to the best-matching HUMMBL repo
- Looking up repos by Base120 code (e.g., SY20) or layer (e.g., L5)
- Exploring bridge connections between repos in the ecosystem
- Reporting ecosystem gaps (under-represented Base120 models)
- Getting ecosystem statistics (repo counts by layer and domain)

## Usage

```bash
[hummbl-compass] python -m hummbl_compass "benchmark a kernel on Metal"
[hummbl-compass] python -m hummbl_compass --by-base120 SY20
[hummbl-compass] python -m hummbl_compass --by-layer L5
[hummbl-compass] python -m hummbl_compass --bridges hummbl-governance
[hummbl-compass] python -m hummbl_compass --gaps
[hummbl-compass] python -m hummbl_compass --stats
```

## Python API

```python
from hummbl_compass import Compass, Repo, RouteResult

c = Compass()
results = c.route("benchmark a kernel on Metal", top_k=3)
for r in results:
    print(r.repo.name, r.confidence, r.reasons)

# Lookups
repos = c.by_layer("L5")
repos = c.by_base120("SY20")
bridges = c.bridges("hummbl-governance")

# Ecosystem analysis
gaps = c.report_gaps()
stats = c.stats()
```

## Key Concepts

- **Topology JSON**: Loads `hummbl-topology.json` describing all hummbl-* repos with Base120 codes, layers, bridges, and status.
- **Natural-language routing**: `route(query)` scores repos by keyword matching against name, description, Base120 domain keywords, and layer keywords. Returns `RouteResult` with confidence score and match reasons.
- **Base120 domains**: Six reasoning domains — P (Perspective), IN (Invert), CO (Combine), DE (Decompose), RE (Recursion), SY (System). Each domain has keyword lists for matching.
- **Layers**: L0 (meta/cross-cutting) through L6 (production/ops) — repos are classified by architectural layer.
- **Bridges**: Explicit cross-repo connections — `bridges(repo_name)` returns linked repos.
- **Gap analysis**: `report_gaps()` returns proposed repos for under-represented Base120 models with priority and justification.
- **Stats**: `stats()` returns total repo count, counts by layer, and counts by Base120 domain.

## Install

```bash
cd /work/active/oss/packages/python/hummbl-compass/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-compass/`
- **License**: MIT OR Apache 2.0
- **Dependencies**: stdlib only
