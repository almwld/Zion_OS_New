---
name: hummbl-bus
description: Secure append-only TSV coordination bus for multi-agent systems
version: 0.2.0
execution-mode: advisory
argument-hint: "[post_message | audit_bus | classify_message | push_task]"
category: fleet-ops
status: candidate
---
# HUMMBL Bus

Secure append-only TSV coordination bus for multi-agent systems. Provides TSV-based message bus with injection protection through base64 encoding of payloads. Includes autonomy tiers, inference tier escalation, lane classification, and a work queue.

## When to Use

- Posting coordination messages to the shared fleet bus from Python code
- Auditing bus integrity (read-only scan for tampering or injection)
- Classifying message lanes (foreground vs background) and model tiers
- Managing a work queue (push/pull/claim/complete tasks)
- Enforcing autonomy tier permissions for agent actions

## Usage

```bash
[hummbl-bus] post_message(bus_path, "devin", "all", "STATUS", "deploy complete")
[hummbl-bus] audit_bus(bus_path)
[hummbl-bus] classify_message("STATUS", body="deploy complete")
```

## Python API

```python
from hummbl_bus import (
    # Core bus
    post_message,
    read_verified_messages,
    verify_bus_message,
    audit_bus,
    BusMessage,
    BusSecurityPolicy,
    get_bus_policy,
    SecureTSVEncoder,
    SecureTSVDecoder,
    # Autonomy ladder
    tier_label,
    can_execute,
    required_tier_for_action,
    validate_action_tier,
    # Inference tier
    baseline_tier,
    recommended_tier,
    escalate_tier,
    estimate_cost,
    # Lane classifier
    classify_message,
    is_foreground,
    is_background,
    expected_model_tier,
    # Work queue
    push_task,
    pull_tasks,
    claim_task,
    complete_task,
    TaskSpec,
    TaskItem,
)
```

## Key Concepts

- **Append-only TSV**: Five tab-separated columns — `timestamp_utc`, `from`, `to`, `type`, `message`. Payloads are base64-encoded to prevent injection.
- **Lazy imports**: Heavy submodules (bus_verifier, bus_writer, autonomy_ladder, inference_tier, lane_classifier, work_queue) are lazily loaded via `__getattr__` to keep import time fast.
- **Security policy**: Configurable via `BUS_SECURITY_POLICY` env var. `get_bus_policy()` returns the active policy.
- **Autonomy ladder**: Tier-based action permissions — `tier_label()`, `can_execute()` gate actions by agent trust level.
- **Inference tier**: Model cost escalation — `baseline_tier()` → `recommended_tier()` → `escalate_tier()`.
- **Lane classification**: Foreground (interactive) vs background (async) message routing.
- **Work queue**: Distributed task queue with claim/complete semantics for multi-agent coordination.

## Install

```bash
cd /work/active/oss/packages/python/hummbl-bus/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-bus/`
- **License**: Apache 2.0
- **Dependencies**: `hummbl-governance>=1.2.2` (runtime); `cryptography` (test only)
