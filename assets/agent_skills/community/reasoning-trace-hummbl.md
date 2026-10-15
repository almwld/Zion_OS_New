---
name: reasoning-trace-hummbl
description: >
  Produces and consumes the native HUMMBL ReasoningTrace JSON format (ReasoningStep → ReasoningTrace → TypedTuple).
  This is the canonical cognitive trace format for HUMMBL agents, supporting tree/chain topologies,
  step typing (hypothesis, action, observation, evaluation, decision, reflection), confidence scoring,
  and metadata attachment. Compatible with hummbl-governance TypedTuple primitives.
version: 0.1.0
execution-mode: advisory
tags:
  - cognition
  - reasoning
  - trace
  - hummbl
  - typedtuple
  - structured
category: fleet-ops
status: candidate
providers:
  required: [python]
---

# HUMMBL Reasoning Trace (Native Format)

Produces and consumes the **native HUMMBL ReasoningTrace** JSON format — the canonical
cognitive trace format for HUMMBL agents. Built on `ReasoningStep` → `ReasoningTrace`
→ `TypedTuple` primitives from `hummbl-governance`.

## When to Use

- Recording structured agent reasoning for audit, replay, or distillation
- Cross-agent cognitive alignment (shared trace format)
- Post-session analysis of decision quality and confidence calibration
- Integration with `hummbl-governance` TypedTuple primitives for cryptographic anchoring

## ReasoningTrace Format (v1)

```json
{
  "id": "trace-{session_id}",
  "topology": "tree|chain|dag",
  "domain": "string",
  "created_at": "unix_timestamp",
  "tags": ["string"],
  "outcome": "COMPLETE_PHASE_MINUS_ONE|COMPLETE|FAILED|PARTIAL|...",
  "steps": [
    {
      "id": "step-{NNN}",
      "type": "hypothesis|action|observation|evaluation|decision|reflection",
      "content": "string",
      "parent_id": "string|null",
      "children_ids": ["string"],
      "metadata": {
        "user_prompt": "string",
        "model_matrix": "string",
        "cells": "int",
        "subagent_count": "int",
        "domains": "int",
        "base120_models": ["SY1", "IN3", "CO3", "DE2", "P1"],
        "receipt_id": "string",
        "server_count": "int",
        "modules_found": ["string"],
        "doctrine": "string",
        "archive_status": "string",
        "target": "string",
        "forensic_status": "string"
      },
      "confidence": "float (0.0-1.0)"
    }
  ]
}
```

## Step Types

| Type | Purpose | Typical Metadata |
|------|---------|------------------|
| `hypothesis` | Initial framing / strategic pivot | `user_prompt` |
| `action` | Concrete operation performed | `model_matrix`, `cells`, `subagent_count`, `domains`, `receipt_id`, `server_count`, `modules_found` |
| `observation` | Result / data gathered | `subagent_status`, `modules_found` |
| `evaluation` | Quality assessment / alignment check | `base120_models`, `alignment_score` |
| `decision` | Commitment to path | `doctrine`, `archive_status`, `target` |
| `reflection` | Post-hoc synthesis | `forensic_status`, `lessons_learned` |

## Topologies

- **tree**: Hierarchical reasoning (default) — each step has 0..N children, 0..1 parent
- **chain**: Linear sequence — each step has 0..1 child, 0..1 parent
- **dag**: Directed acyclic graph — steps can have multiple parents (convergent reasoning)

## Confidence Scoring

Each step carries `confidence: float (0.0-1.0)`:
- `1.0` = Certain (direct observation, cryptographic verification)
- `0.8-0.99` = High (multiple corroborating sources)
- `0.5-0.79` = Moderate (single source, reasonable inference)
- `0.0-0.49` = Low (speculative, uncorroborated)

## Execution Procedure

### Generate Trace (during session)
```python
trace = {
    "id": f"trace-{session_id}",
    "topology": "tree",
    "domain": "omni_meta_aggregator_discovery",
    "created_at": time.time(),
    "tags": ["huaomp", "mtsmu", "meta_aggregator", "base120", "session_forensics", "governed_rag"],
    "outcome": "COMPLETE_PHASE_MINUS_ONE",
    "steps": []
}

# For each reasoning step:
step = {
    "id": f"step-{step_num:03d}",
    "type": "hypothesis|action|observation|evaluation|decision|reflection",
    "content": "Description of reasoning",
    "parent_id": parent_step_id or None,
    "children_ids": [],
    "metadata": {...},
    "confidence": 1.0
}
trace["steps"].append(step)
# Update parent's children_ids
```

### Consume Trace (post-session)
```python
# Load trace
with open("session_reasoning_trace.json") as f:
    trace = json.load(f)

# Analyze
print(f"Topology: {trace['topology']}")
print(f"Total Steps: {len(trace['steps'])}")
print(f"Outcome: {trace['outcome']}")

# Confidence analysis
confidences = [s["confidence"] for s in trace["steps"]]
print(f"Avg confidence: {sum(confidences)/len(confidences):.2f}")

# Step type distribution
from collections import Counter
types = Counter(s["type"] for s in trace["steps"])
print(f"Type distribution: {dict(types)}")
```

## Integration with hummbl-governance

The trace can be converted to `TypedTuple` primitives for cryptographic anchoring:

```python
# Each step → TypedTuple
from hummbl_governance import TypedTuple

for step in trace["steps"]:
    tuple = TypedTuple(
        kind="reasoning_step",
        payload=step,
        metadata={"trace_id": trace["id"], "domain": trace["domain"]}
    )
    # Emit to Cognitive Ledger (Merkle anchor)
```

## Output Location

- **Primary**: `.gemini/antigravity-cli/brain/{session_id}/session_reasoning_trace.json`

## Integration with Session Lifecycle

| Phase | Action |
|-------|--------|
| Step initiated | Append new step to trace |
| Step completed | Update step confidence, metadata |
| Sub-step added | Append child, update parent's `children_ids` |
| Session end | Finalize `outcome`, emit trace |

## AIP Scope Compliance

- Trace emission is `AGENT_LOCAL_CONFIG` (permitted)
- No credential values in trace content
- Trace confined to session brain directory

## Related Skills

- `session-forensics-manifest` — consumes trace for manifest generation
- `forensic-telemetry-sidecar` — cross-references trace steps with tool calls
- `opencode-forensic-brief` — generates auditor briefing from trace

## Evidence Sources

- Reference trace: `session_reasoning_trace.json` from session `b93f413b-0a68-480e-b623-7f90cba61eec` (11 steps, tree topology, outcome=COMPLETE_PHASE_MINUS_ONE)
- hummbl-governance TypedTuple primitives: `hummbl_governance/cognition/typed_tuple.py`

## Skill Chains
- For free-tier inference for reasoning trace generation -> `[reasoning-router]` (`route`)
