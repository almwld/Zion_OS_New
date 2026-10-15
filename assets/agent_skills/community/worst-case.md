---
name: worst-case
description: Find conditions that maximize failure -- inverse optimization for stress testing. Maps to IN16.
version: 0.1.0
execution-mode: advisory
argument-hint: <system or feature to stress test>
category: dev-tools
status: candidate
---
# Worst Case (IN16: Inverse Optimization)

Instead of optimizing for success, optimize for failure. Find the exact conditions that break the system.

## Execution

### 1. Identify the system under test
What are we trying to break? A service, a pipeline, a workflow, a data model?

### 2. Enumerate failure dimensions
| Dimension | Worst-Case Value |
|-----------|-----------------|
| Input size | Maximum (4KB ledger entry, 200-line MEMORY.md, 10MB bus file) |
| Concurrency | All agents writing simultaneously |
| Timing | OAuth token expires mid-briefing |
| Network | Tailscale drops during SSH operation |
| Disk | Full disk during bus append |
| State | Corrupted JSON in state.json mid-write |
| Dependency | All external APIs down simultaneously |
| Sequence | Operations arrive in worst possible order |

### 3. Construct the worst-case scenario
Combine dimensions to find the **most damaging realistic scenario**:
```
"At 6:57 AM, the briefing scheduler starts. OAuth token is 2 minutes from expiry.
Ollama is OOM-killed. The bus file has a partial write from a crashed agent.
Codex posts a DIRECTIVE (unauthorized). The kill switch file is corrupted."
```

### 4. Test it
- Can you reproduce it? (Even partially)
- What actually happens? (Crash? Silent failure? Data corruption? Graceful degradation?)
- How long until someone notices?

### 5. Harden
For each worst-case that isn't handled gracefully:
- Add a guard, timeout, or circuit breaker
- Add monitoring that would detect it
- Add a test that exercises the condition

## Output Format
```
Worst Case Analysis | <system>
═══════════════════════════════

## Failure Dimensions
<dimension table>

## Worst Realistic Scenario
<narrative description>

## What Actually Happens
<tested or predicted behavior>

## Detection Time
<how long until someone notices>

## Hardening Recommendations
1. <specific fix for the worst case>
```

## Base120 Context
- Primary: **IN16** (Inverse Optimization)
- Related: **IN2** (Premortem), **DE13** (FMEA), **SY14** (Risk & Resilience)
