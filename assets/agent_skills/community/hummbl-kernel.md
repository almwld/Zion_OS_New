---
name: hummbl-kernel
description: HUMMBL orchestration kernel — lightweight workflow execution with security, compliance, and fleet coordination
version: 0.1.0
execution-mode: advisory
argument-hint: "[MissionModeKernel | FleetConfig | ComplianceFramework]"
category: governance-compliance
status: candidate
---
# HUMMBL Kernel

HUMMBL orchestration kernel — lightweight workflow execution with security, compliance, and fleet coordination. Implements a hybrid conductor-kernel architecture with deterministic mission orchestration, compliance audit trails, and fleet coordination between user-supplied compute nodes.

## When to Use

- Orchestrating multi-step agent missions with compliance audit trails
- Enforcing security policies (capability risk classification, admission gates)
- Coordinating fleet compute nodes (primary, GPU, fallback)
- Tracking mission lifecycle events (requested → admitted → planned → running → completed)
- Running SOC 2 / ISO 27001 / PCI compliance-aware workflows

## Usage

```bash
[hummbl-kernel] MissionModeKernel(fleet=FleetConfig(...))
[hummbl-kernel] kernel.admit_mission(mission_request)
[hummbl-kernel] kernel.run_mission(mission_id)
```

## Python API

```python
from hummbl_kernel import MissionModeKernel
from hummbl_kernel.kernel import (
    FleetConfig,
    AuditEvent,
    EventStatus,
    RiskClass,
    ComplianceFramework,
)
```

## Key Concepts

- **Mission Mode**: Deterministic orchestration — missions pass through admission, planning, execution, and completion phases with full audit trails.
- **Compliance frameworks**: SOC 2, ISO 27001, PCI — select which framework governs audit event recording.
- **Fleet config**: User-supplied compute node names and endpoints (no internal defaults). Override via env vars (`PRIMARY_OLLAMA_URL`, `PRIMARY_BUS_URL`, `GPU_GITEA_URL`).
- **Risk classification**: Capabilities classified as LOW / MEDIUM / HIGH / CRITICAL — gates admission.
- **Event lifecycle**: REQUESTED → ADMITTED → PLANNED → RUNNING → COMPLETED (or DENIED / BLOCKED / FAILED / CANCELLED / ESCALATED).
- **Reasoning integration**: Optional `[reasoning]` extra (`pip install "hummbl-kernel[reasoning]"`) enables hummbl reasoning artifacts as kernel inputs.

## Install

```bash
cd /work/active/oss/packages/python/hummbl-kernel/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-kernel/`
- **License**: Apache 2.0
- **Dependencies**: stdlib only (optional: `hummbl>=0.1.0` via `[reasoning]` extra)
