---
name: hummbl-governance
description: HUMMBL governance primitives — kill switch, circuit breaker, cost governor, delegation tokens, audit log, identity registry, schema validation, coordination bus, compliance mapper.
version: 0.1.0
execution-mode: advisory
argument-hint: "[kill-switch | circuit-breaker | cost-governor | delegation | audit | identity | schema | bus | compliance]"
category: governance-compliance
status: candidate
---
# HUMMBL Governance

Governance primitives for AI agent orchestration. Provides the building blocks for governing autonomous agent fleets: kill switches, circuit breakers, cost governors, delegation tokens, audit logs, identity registries, schema validation, coordination bus, compliance mapping, health probes, BaseNTuple governance tuples, AdversarialTupleGenerator, MerkleAnchor, SovereignCryptosystem.

## When to Use

- Implementing kill switch / circuit breaker for an agent
- Managing delegation tokens for agent authority
- Auditing agent actions
- Registering agent identities
- Validating governance schemas
- Compliance mapping (NIST, ISO, EU AI Act)
- Health probes for fleet monitoring

## Usage

```bash
[hummbl-governance] kill-switch status
[hummbl-governance] circuit-breaker check "agent_name"
[hummbl-governance] cost-governor report
[hummbl-governance] delegation issue "agent_name" --scope "read"
[hummbl-governance] audit query --agent "devin" --since "2026-09-01"
[hummbl-governance] identity list
[hummbl-governance] schema validate contract.json
```

## Python API

```python
from hummbl_governance import (
    KillSwitch,
    CircuitBreaker,
    CostGovernor,
    DelegationToken,
    AuditLog,
    IdentityRegistry,
    SchemaValidator,
    ComplianceMapper,
    HealthProbe,
)

# Kill switch
ks = KillSwitch()
ks.activate("agent_name", reason="safety violation")
ks.status()

# Circuit breaker
cb = CircuitBreaker(threshold=5, reset_timeout=60)
if cb.is_tripped("agent_name"):
    print("Agent circuit breaker tripped")

# Delegation tokens
token = DelegationToken(agent="devin", scope="read", expires_in=3600)

# Audit log
audit = AuditLog()
audit.record(agent="devin", action="file_write", target="/path/to/file")

# Identity registry
registry = IdentityRegistry()
registry.register(name="devin", trust_tier="MEDIUM-HIGH", role="coordinator")
```

## Key Concepts

- **Kill switch**: Emergency stop for agents — can be activated by operator or automated safety rules
- **Circuit breaker**: Automatic trip when error threshold exceeded, auto-reset after timeout
- **Cost governor**: Tracks and limits spending per agent
- **Delegation tokens**: Scoped, time-limited authority tokens
- **Audit log**: Append-only record of all agent actions
- **Identity registry**: Canonical agent identity store
- **Compliance mapper**: Maps controls to NIST AI RMF, ISO 42001, EU AI Act

## Install

```bash
cd /work/active/oss/packages/python/hummbl-governance
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-governance/`
- **License**: Apache 2.0
- **PyPI**: Published (1.4.2)
- **Dependencies**: stdlib only
