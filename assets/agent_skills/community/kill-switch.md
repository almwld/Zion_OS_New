---
name: kill-switch
description: Inspect kill switch state (read-only by default, engage with explicit command).
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[status | engage <mode> --reason \"...\"]"
category: security
status: candidate
---
## Context Gathering

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=kill-switch] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Before executing this skill, gather the following context:
- **Kill switch mode**: Run `python3 -c "from hummbl_governance.kill_switch import KillSwitch; from pathlib import Path; ks=KillSwitch(state_dir=Path.home()/'.local'/'share'/'hummbl'/'governance'); print(ks.mode.name if hasattr(ks.mode,'name') else ks.mode)" 2>/dev/null || echo "unknown"`

# Kill Switch Command

Inspect or control the kill switch. Read-only by default.

## Usage

```bash
[kill-switch]                                    # Show current status
[kill-switch] status                             # Same as above
[kill-switch] engage HALT_NONCRITICAL --reason "investigating cost spike"
[kill-switch] engage HALT_ALL --reason "security incident"
[kill-switch] engage EMERGENCY --reason "active breach"
[kill-switch] disengage --reason "incident resolved"
```

## Modes

| Mode | Effect |
|------|--------|
| `DISENGAGED` | Normal operation, all agents active |
| `HALT_NONCRITICAL` | Stop non-critical agents, briefing continues |
| `HALT_ALL` | Stop all agents except kill switch itself |
| `EMERGENCY` | Immediate halt, requires manual recovery |

## Execution

### Status (default)
```python
from pathlib import Path
from hummbl_governance.kill_switch import KillSwitch

ks = KillSwitch(state_dir=Path.home() / ".local" / "share" / "hummbl" / "governance")
print(ks.mode)
print(ks.get_history())
```

### Engage
**Requires explicit user command with `engage` keyword and `--reason`.**
```python
from hummbl_governance.kill_switch import KillSwitchMode

ks.engage(KillSwitchMode.HALT_ALL, reason=reason, triggered_by="operator")
```
Post to coordination bus after engaging.

### Disengage
```python
ks.disengage(triggered_by="operator")
```

## Output Format

```
Kill Switch | <YYYY-MM-DD HH:MMZ>
══════════════════════════════════

Current Mode: DISENGAGED
Last Transition: <timestamp> — <from> → <to> (<reason>)

## Transition History (Last 10)
| Time | From | To | Reason |
|------|------|----|--------|
| ... | ... | ... | ... |
```

## Constraints

- **READ-ONLY by default.** Only engage/disengage when the user explicitly requests it with the `engage` or `disengage` keyword.
- Always require a `--reason` for state changes.
- Post to coordination bus after any state change.
- EMERGENCY mode should trigger a confirmation prompt before engaging.
- Do not fabricate state -- always query the actual kill switch.

## Skill Chains

### Mandatory

None — read-only inspection; engagement requires explicit operator command.

### Advisory

- `[health]` — check overall system health before engaging HALT modes

## Authority

- **T1 (TRUSTED)**: May inspect; engagement requires operator approval
- **T2 (Active/High)**: May inspect; engagement requires operator approval
- **T3 (Medium)**: May inspect; engagement requires operator approval
- **T4 (Probationary)**: May inspect (read-only); engagement requires operator approval
- **Operator**: Override any restriction (engagement at ALL tiers requires operator approval)
