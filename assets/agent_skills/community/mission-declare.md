---
name: mission-declare
description: Declare a new mission-mode session with structured packet schema.
version: 0.1.0
execution-mode: side_effecting
category: fleet-ops
status: candidate
---

# Mission Declare

## When to Use

- Operator says "mission mode" or "declare a mission"
- A critical objective with existential or time-bound stakes needs singular focus
- Before high-tempo execution where review compression is appropriate

## Entry Criteria (from mission-mode.md v0.2)

Before declaring, answer the 3-Question Test:
1. Does missing the deadline cause irreversible harm?
2. Is the window shorter than the normal cross-check cycle?
3. Can the work be paused and resumed without material cost?

If 2+ are "yes", mission mode is appropriate.

## Usage

```bash
[mission-declare] <mission_statement> <duration_minutes> [options]
```

Or invoke via the standalone mission-mode CLI:
```bash
cd ~/PROJECTS/mission-mode
python -m mission_mode.cli init "Fix CI pipeline" \
  --intent "Restore green CI on hummbl-governance" \
  --mission-type ops \
  --risk-tier medium \
  --reversibility reversible
```

**hummbl-governance adapter (read-only):**
```python
from hummbl_governance.integrations.mission_mode_adapter import declare_mission

result = declare_mission(
    title="Fix CI pipeline",
    intent="Restore green CI on hummbl-governance",
    mission_type="ops",
    risk_tier="medium",
)
# result: {"slug": "fix-ci-pipeline", "path": "missions/fix-ci-pipeline", "stdout": "..."}
```

## Required Fields

| Field | Description | Example |
|---|---|---|
| `agent_id` | Canonical bus identity | `devin`, `codex`, `claude-code` |
| `mission_statement` | One-line objective (1-280 chars) | "Fix CI pipeline" |
| `mission_type` | `ops`, `build`, `research`, `govern`, `ship`, `recovery` | `ops` |
| `expected_duration_minutes` | Max 480 (8h session ceiling) | `30` |
| `risk` | `P0`, `P1`, `P2`, `P3` | `P1` |
| `host` | `workstation`, `huxley`, `remote-node` (dormant since 2026-07-01), `unknown` | `huxley` |

## Optional Fields

| Field | Default | Description |
|---|---|---|
| `reversible` | `True` | Can the mission be undone? |
| `operator_initiated` | `False` | Was this declared by operator chat? |
| `auto_abort_on_cost_exceeded` | `True` | Auto-exit if budget exhausted |
| `cost_budget_usd` | `0.0` | API/compute budget |
| `sacrifice_list` | `[]` | Lanes/tasks paused during mission |
| `crew_list` | `[]` | Multi-agent mission crew |
| `destructive_ops_list` | `[]` | Destructive operations planned |
| `protected_surface_touch` | `False` | Does this touch protected surfaces? |

## Bus Metadata

After declaring, the agent MUST post to bus:
```
lane=mission/<agent>/<slug>; mode=mission; risk=...; host=...;
MISSION: <mission_statement>
Duration: <duration>m. Budget: $<budget>.
```

## Output

- `mission_id` (e.g., `msn-a1b2c3d4e5f6`)
- Registry entry in `_state/coordination/missions.jsonl`

## Anti-Patterns

- **Mission mode for routine work** — If fewer than 2 of the 3-Question Test answers are "yes", use normal operations instead.
- **Self-declared missions without operator ACK** — An agent may NOT unilaterally enter mission mode. The operator must know and ACK.
- **Using mission mode to skip safety guardrails** — Safety rules (no `--no-verify`, no destructive ops without approval, bus identity rules, data tier restrictions) are NEVER suspended in mission mode.
- **Perpetual mission mode across sessions** — Missions are session-scoped. If a mission spans multiple sessions, each session must re-declare with operator ACK. A mission left dangling across sessions without re-declaration is a process failure.

## Related

- `mission-mode.md` v0.2 — canonical rule
- `mission-status` skill — query active missions
- `mission-abort` skill — exit a mission

## Skill Chains

### Mandatory (MUST pass before mission declaration)

- **3-Question Test** MUST be answered (2+ "yes" required) — built into entry criteria
- **Operator ACK** MUST be confirmed — agents may NOT unilaterally enter mission mode

### Advisory

- **After declare**: `[bus]` (STATUS post with mission metadata), `[mission-status]` (verify registration)
- **During mission**: `[session-metrics]` (track burn rate), `[cost-status]` (budget check)
- **Exit**: `[mission-abort]` (abort), `[aar]` (after action report on completion)

## Authority

- **T1 (TRUSTED)**: May declare with operator ACK (mandatory)
- **T2 (Active/High)**: MUST get operator ACK (mandatory — no self-declared missions)
- **T3 (Medium)**: MUST get operator ACK (mandatory — no self-declared missions)
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill (mission mode authority)
- **Operator**: Override any restriction — operator-initiated missions bypass agent tier checks
