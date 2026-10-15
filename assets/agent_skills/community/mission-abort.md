---
name: mission-abort
description: Exit a mission-mode session with partial-work receipt.
version: 0.1.0
execution-mode: side_effecting
category: fleet-ops
status: candidate
---

# Mission-Abort

## When to Use

- Operator says "abort", "stop", "drop it", or equivalent
- Kill switch engages during a mission
- Cost ceiling is breached
- Session ends without mission completion
- Operator explicitly ends the mission

## Usage

```bash
[mission-abort] <mission_id> [reason]
```

Or invoke via the standalone mission-mode CLI:
```bash
cd ~/PROJECTS/mission-mode
python -m mission_mode.cli set-status --mission fix-ci-pipeline blocked
python -m mission_mode.cli receipt --mission fix-ci-pipeline STATUS "Aborted: CI config updated but tests not yet passing"
```

**hummbl-governance adapter:**
```python
from hummbl_governance.integrations.mission_mode_adapter import abort_mission, add_receipt

abort_mission("fix-ci-pipeline")
add_receipt(
    slug="fix-ci-pipeline",
    receipt_type="STATUS",
    message="Aborted: CI config updated but tests not yet passing",
)
```

## Abort Protocol (from mission-mode.md v0.2)

1. Stop work immediately
2. Do not complete the current tool call if destructive/irreversible
3. Post `STATUS` with `mode=mission-exit` and `reason=operator-abort`
4. Include partial-work receipt: what was done, what was in flight, what next session needs
5. Do not treat abort as failure — it is a valid exit condition

## Required Fields

| Field | Description | Example |
|---|---|---|
| `mission_id` | Mission to abort | `msn-a1b2c3d4e5f6` |
| `exit_criterion` | Why aborted | `operator-abort`, `kill-switch`, `budget-exhausted`, `session-end` |
| `verdict` | `success`, `partial`, `abort` | `abort` |
| `agent_id` | Aborting agent | `devin` |
| `time_elapsed_minutes` | Time spent before abort | `14` |

## Optional Fields

| Field | Description |
|---|---|
| `partial_work_receipt` | What was done + what next session needs |
| `aborted_by` | Who initiated abort |
| `abort_cause` | Detailed cause |
| `artifacts_produced` | Files/outputs created before abort |
| `next_owner` | Who should resume this mission |

## Bus Post

```
lane=mission/<agent>/<slug>; mode=mission-exit; reason=operator-abort; host=...;
ABORT: Mission <mission_id> exited after <time>m.
Partial work: <receipt>
Next owner: <agent>
```

## Related

- `mission-mode.md` v0.2 — canonical rule
- `mission-declare` skill — declare a mission
- `mission-status` skill — query missions

## Skill Chains

### Mandatory

- None — mission-abort is an emergency exit. The abort protocol (step 1-5) is the built-in check.
  Abort is always allowed when operator requests it or kill switch engages.

### Advisory

- **After abort**: `[handoff]` (partial-work receipt for next session), `[bus]` (STATUS post)
- **If resuming later**: `[mission-declare]` (re-declare with operator ACK)
- **Post-incident abort**: `[incident]`, `[postmortem]`, `[aar]`

## Authority

- **T1 (TRUSTED)**: May abort any mission (abort is a safety action)
- **T2 (Active/High)**: May abort any mission (abort is a safety action)
- **T3 (Medium)**: May abort any mission (abort is a safety action)
- **T4 (Probationary)**: May abort any mission (abort is a safety action — always allowed)
- **Operator**: Override any restriction — operator abort is absolute
