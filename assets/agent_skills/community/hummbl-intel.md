---
name: hummbl-intel
description: INT taxonomy framework for agent intelligence collection
version: 0.1.0
execution-mode: advisory
argument-hint: "[hummbl-intel] <import and use IntelligenceDiscipline, SourceGrade, fuse_into_finding>"
category: fleet-ops
status: candidate
---
# hummbl-intel

INT taxonomy framework for agent intelligence collection. Categorizes agent intelligence into the canonical DoD/ODNI taxonomy (SIGINT, HUMINT, OSINT, GEOINT, MASINT, FININT, TECHINT, IMINT, ALL-SOURCE) and provides tools for source grading, collection posture, and structured all-source fusion.

## When to Use

- You need to categorize intelligence collection into canonical INT disciplines (SIGINT, HUMINT, OSINT, etc.)
- You want to grade sources using NATO-style reliability (A–F) × credibility (1–6) scales
- You need to track per-INT collection posture (GREEN/YELLOW/RED)
- You want to fuse multiple intelligence sources into structured findings with competing hypotheses and estimative probability
- You need to assign INT manager stewardship roles to fleet agents

## Usage

### 1. Fleet Intelligence Collector CLI

Run the multi-discipline all-source intelligence collector across SIGINT, OSINT, HUMINT, GEOINT, TECHINT:

```bash
# Print formatted All-Source Intelligence Brief to stdout
python scripts/fleet_intel_collector.py

# Emit raw JSON telemetry for ingestion
python scripts/fleet_intel_collector.py --json

# Save report directly to file
python scripts/fleet_intel_collector.py -o docs/research/2026-09-25_fleet_all_source_intel_brief.md
```

### 2. Python Library Usage

```bash
python -c "from hummbl_intel import IntelligenceDiscipline, list_disciplines; print(list_disciplines())"
```

## Python API

```python
from hummbl_intel import (
    IntelligenceDiscipline, INT_LABELS, CollectionSurface, CANONICAL_SURFACES,
    from_bus_prefix, get_surface, list_disciplines,
    SourceReliability, ContentCredibility, SourceGrade, GradedAssertion,
    grade_human_source, grade_automated_source, grade_research_source,
    grade_uncorroborated, upgrade_with_corroboration,
    PostureStatus, SurfaceStatus, DisciplinePosture, CollectionPostureReport,
    build_default_posture,
    EstimativeProbability, WEP_RANGES, Hypothesis, CompetingHypothesesAnalysis,
    FusedFinding, AllSourceProduct, fuse_into_finding,
    INTManager, CANONICAL_MANAGERS, get_manager, get_disciplines_for_agent,
    manager_summary_table, to_dict,
)
```

## Key Concepts

- **IntelligenceDiscipline**: Enum covering 9 INT types (SIGINT, HUMINT, OSINT, GEOINT, MASINT, FININT, TECHINT, IMINT, ALL_SOURCE)
- **Source grading**: Reliability (A–F) × credibility (1–6) per NATO intelligence doctrine; helper functions for human, automated, research, and uncorroborated sources
- **Collection posture**: Per-INT health tracking with GREEN/YELLOW/RED status and surface-level granularity
- **All-source fusion**: `fuse_into_finding()` combines graded assertions into `FusedFinding` objects with competing hypotheses analysis and WEP (Words of Estimative Probability) ranges
- **INT managers**: Canonical steward role definitions mapping agents to discipline responsibilities

## Install

```bash
cd /work/active/oss/packages/python/hummbl-intel/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-intel/`
- **License**: MIT OR Apache-2.0
- **Dependencies**: stdlib only
