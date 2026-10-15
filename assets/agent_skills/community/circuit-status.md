---
name: circuit-status
description: Show circuit breaker state per adapter.
version: 0.1.0
execution-mode: advisory
argument-hint: "[all | adapter ADAPTER_NAME]"
category: security
status: candidate
---
# Circuit Status Command

Display the circuit breaker state for each service adapter.

## Usage

```bash
[circuit-status]       # Show all circuit breaker states
```

## Execution

### 1. Query circuit breaker state

Use Python to import and inspect the circuit breaker registry:
```python
from hummbl_governance.services.circuit_breaker import CircuitBreaker
# Inspect all registered breakers
```

Or check for a persistent state file if breakers store state to disk.

### 2. For each adapter, report:
- Breaker name (adapter it wraps)
- Current state: CLOSED (healthy), HALF_OPEN (testing), OPEN (tripped)
- Failure count
- Last failure time
- Time until next retry (if OPEN)

## Output Format

```
Circuit Breakers | <YYYY-MM-DD HH:MMZ>
═══════════════════════════════════════

| Adapter | State | Failures | Last Failure | Next Retry |
|---------|-------|----------|-------------|------------|
| GitHub Events | CLOSED | 0 | — | — |
| Google Calendar | CLOSED | 0 | — | — |
| Linear | OPEN | 5 | 2m ago | in 3m |
| Cost Tracker | CLOSED | 0 | — | — |
| Security | CLOSED | 0 | — | — |
| Local LLM | OPEN | — | — | disabled |
| Signal | HALF_OPEN | 2 | 5m ago | testing |

## Summary
- CLOSED: 4/7 adapters healthy
- OPEN: 2/7 adapters tripped
- HALF_OPEN: 1/7 testing recovery

<if any OPEN>
## Tripped Breakers
<detail on each OPEN breaker: failure history, recommended action>
</if>
```

## Constraints

- READ-ONLY. Do not reset or modify circuit breaker state.
- Pairs with `[adapter-status]` for a complete adapter health picture.
- Do not fabricate states -- always query actual breaker objects.
- If circuit breaker module fails to import, report the error.
