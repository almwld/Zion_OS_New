---
name: hummbl-axis
description: Ladder that selects which Atlas contradiction to act on
version: 0.1.0
execution-mode: advisory
argument-hint: "[hummbl-axis] scan --atlas-dir ~/docs [--inventory inv.json] [--cycle-state .axis-state.json]"
category: governance-compliance
status: candidate
---
# hummbl-axis

Ladder that selects which Atlas contradiction to act on. Closes the lattice-ladder-loop: Atlas (observe) → Axis (select) → Human (act) → Atlas (re-observe).

## When to Use

- You need to diff claimed state against observed state from Atlas evidence cuts
- You want to prioritize contradictions by severity (P0–P3) and confidence
- You need cycle-state tracking with automatic exit conditions (stuck after 3 unchanged cycles, or healthy after 0 new for 3 cycles)
- You want to route prioritized contradictions to a human via the coordination bus
- You need to check Atlas evidence cut freshness against scoring-standard windows

## Usage

```bash
axis scan --atlas-dir ~/docs --inventory path/to/inventory.json --observed-counts observed.json
axis scan --atlas-dir ~/docs --cycle-state .axis-state.json --bus-post axis --host agent-node
axis report --cycle-state .axis-state.json
axis contradictions --atlas-dir ~/docs
axis scan --atlas-dir ~/docs --check-freshness --freshness-category security
```

## Python API

```python
from hummbl_axis.contradiction import Contradiction, CycleState, prioritize
from hummbl_axis.atlas_reader import scan_ledger_directory, diff_counts, scan_freshness
from hummbl_axis.cli import main
```

## Key Concepts

- **Contradiction**: Frozen dataclass with deterministic ID (SHA-256 of scope+claim+observation), severity (P0–P3), confidence (0.0–1.0), volatility (low/medium/high)
- **CycleState**: Tracks contradiction persistence across cycles; exits when stuck (3+ unchanged) or healthy (0 new for 3 cycles)
- **prioritize()**: Sorts contradictions by severity (P0 first), then confidence (high first)
- **Atlas reader**: Scans markdown ledger directories for evidence cuts, diffs claimed vs observed counts, checks freshness windows (metadata=30d, dependency=90d, security=7d)
- **Bus routing**: Posts SITREP summaries to the coordination bus via bus-global.py or fallback TSV append

## Install

```bash
cd /work/active/oss/packages/python/hummbl-axis/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-axis/`
- **License**: MIT OR Apache-2.0
- **Dependencies**: stdlib only
