---
name: fleet-status
description: Unified view of all machines (MBP, Windows desktop, $REMOTE_HOST) -- health, sync state, tool versions, drift, plus mesh algebraic connectivity from the coordination bus
version: 0.3.0
execution-mode: advisory
argument-hint: "[--check health|sync|tools|mesh|all] [--mesh-file PATH] [--canonical] [--min-msgs N] [--json] [--no-append-history]"
category: fleet-ops
status: candidate
---
# Fleet Status

Produce a unified dashboard of all machines in the fleet (MBP, Windows desktop, remote server), covering health probes, sync state, tool versions, configuration drift, and agent mesh topology. Identifies machines that are out of date or unreachable, and quantifies mesh fragmentation.

## When to Use
- Morning check to see which machines are online and healthy
- Before syncing skills or config to verify fleet state
- After a tool upgrade to confirm all machines have the new version
- Debugging cross-machine issues (Tailscale, SSH, sync failures)
- Assessing agent mesh health before high-stakes coordination events (swarms, handoffs, multi-agent pipelines)

## Execution
1. Parse `$ARGUMENTS` for `--check` filter (default: all), `--canonical` flag, and `--mesh-file` / `--min-msgs` overrides.
2. For local machine: collect hostname, OS, Python version, git status, disk usage, and uptime.
3. For remote machines ($REMOTE_HOST, Windows desktop): probe via Tailscale ping and SSH to collect the same metrics.
4. For `sync`: compare skill file counts, hook versions, settings.json, and MEMORY.md across machines.
5. For `tools`: compare Python, git, Claude Code, Node.js, and other key tool versions.
6. For `health`: run disk-check, port-map, and process-check logic on each reachable machine.
7. For `mesh` (or `all`): run `mesh_algebraic_connectivity.py` against the global bus TSV. Default path is auto-resolved (Workstation mirror → repo-relative → MBP canonical); override with `--mesh-file PATH` or `FM_BUS_PATH` env var. Report unnormalized algebraic connectivity (λ₂), normalized spectral gap, connected status, component breakdown, and isolates.
8. **Natural accumulation**: Unless `--no-append-history` is passed, append the `--json` result to `hummbl_governance/_state/coordination/mesh_history.jsonl`. This builds the time-series baseline for percentile-based thresholds. One-liner: `python mesh_algebraic_connectivity.py --canonical --json >> _state/coordination/mesh_history.jsonl`
9. Thresholds (unnormalized algebraic connectivity on largest component):
   - λ₂ < 0.1 → CRITICAL (mesh near disconnection)
   - 0.1 ≤ λ₂ < 1.0 → WARNING (fragile connectivity)
   - λ₂ ≥ 1.0 → OK (well-connected)
10. Flag any unreachable machines, version mismatches, sync drift, or mesh fragmentation.

## Output Format
```
Fleet Status | all checks

| Machine | OS | Status | Python | Claude Code | Disk Free | Skills |
|---------|-----|--------|--------|-------------|-----------|--------|
| MBP (local) | macOS 15.3 | ONLINE | 3.12.4 | 1.0.16 | 42GB | 220 |
| Windows Desktop | Win 11 | ONLINE | 3.12.4 | 1.0.16 | 180GB | 218 |
| $REMOTE_HOST | macOS 14.5 | ONLINE | 3.11.9 | 1.0.14 | 95GB | 205 |

Drift:
- [WARNING] $REMOTE_HOST Claude Code is 1.0.14 (latest: 1.0.16)
- [WARNING] $REMOTE_HOST has 15 fewer skills than MBP
- [OK] Python versions consistent across fleet

Mesh Topology (canonical agents, min 50 msgs):
| Metric | Value | Threshold |
|--------|-------|-----------|
| Agents analyzed (total) | 50 | -- |
| Largest connected component | 21 | -- |
| Isolates (singletons) | 25 | -- |
| Small components (>1 agent) | 2 | -- |
| Algebraic connectivity (λ₂) | 1.041493 | >= 1.0 OK |
| Normalized spectral gap | 0.336945 | reference |
| Status | OK (well-connected) | -- |
| Fiedler bipartition balance | 18 / 3 | ~even |

Hub degree (weighted, largest component):
- lead-doctor: 1625
- broadcast: 1607
- codex: 534
- codex-1: 533
- claude-code: 514

Mesh: [OK] λ₂ = 1.041 on largest component (21/50 agents, 25 isolates)

Next action: Run `[mesh-sync] push` to update $REMOTE_HOST.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Inherits context from | `/$REMOTE_HOST` for remote ops, `[tailscale-status]` for connectivity |
| Skill drift detected | `[mesh-sync]` to push updates to lagging machines |
| Config drift detected | `[config-drift]` agent to investigate differences |
| Low lambda2 (< 1.0) | Review bus activity, check for silent agents, verify bus write paths |

## Notes
- Default bus path is auto-resolved via `FM_BUS_PATH` env var → repo-relative → Workstation mirror → MBP canonical. On any machine, set `FM_BUS_PATH` for deterministic behavior.
- The algebraic connectivity metric is computed on the **largest connected component only**. Isolates and small components are reported separately.
- `--canonical` filters to the approved bus identity set (see `agent-roster.md`). Without it, `thread_*` and ephemeral agents inflate the graph.
- `--json` emits compact one-line JSON (with `timestamp` and `mode` injected) suitable for appending to `mesh_history.jsonl`. No formatted output is printed.
- **Thresholds are arbitrary until baseline is established.** After 7 days of natural accumulation (N>=7 samples), switch to percentile-based thresholds (10th %ile = CRITICAL, 25th %ile = WARNING). Until then, the fixed thresholds are conservative overestimates.
- Do not commit `mesh_history.jsonl` — it lives in `_state/` (local-only). Each machine maintains its own history from its own perspective.
