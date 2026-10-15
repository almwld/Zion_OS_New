---
name: hyperfocus-enter
description: Enter hyperfocus mode — transition cogstate to HYPERFOCUS, silence non-critical interrupts, set session intent.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<optional: task or topic to hyperfocus on>"
category: data-science
status: candidate
---
# Hyperfocus Enter

Transitions cognitive state to HYPERFOCUS. Silences briefing delivery and
non-critical agent messages. Sets session intent so the system knows what
you're focused on.

## When to Use
- Starting a deep work session (coding, writing, research)
- Entering a flow state you don't want interrupted
- "Starting hyperfocus", "entering flow", "deep work mode", "do not disturb"

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=hyperfocus-enter] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Transition cogstate
```bash
python3 -c "
from hummbl_governance.services.cogstate import create_cogstate_manager, CogState
from pathlib import Path
mgr = create_cogstate_manager(state_dir=Path.home() / '.agents' / '_state' / 'cognition')
mgr.transition(CogState.HYPERFOCUS, reason='$ARGUMENTS' if '$ARGUMENTS' else 'hyperfocus-enter skill')
print(f'STATE: {mgr.current_state.value}')
print(f'RECORD: {mgr.current_record.record_id}')
"
```

### 2. Post to bus
Post STATUS to the bus confirming entry to HYPERFOCUS.
```
Type: STATUS
To: all
Message: HYPERFOCUS entered. Topic: $ARGUMENTS. is_safe_to_interrupt=false. Briefing delivery gated.
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 3. Set session intent (optional, if $ARGUMENTS provided)
If task/topic was specified, update `_state/cognition/intent.md` with the focus context:
- Read current intent
- Prepend `## Active Hyperfocus Session\n**Topic:** $ARGUMENTS\n**Started:** <UTC>\n\n`
- Write back

### 4. Confirm to user

Output format:
```
HYPERFOCUS | entered
━━━━━━━━━━━━━━━━━━━━━━━━━━
State       HYPERFOCUS
Topic       $ARGUMENTS (or "unspecified")
Interrupts  GATED — briefing delivery suspended
            is_safe_to_interrupt() → false
Exit        [hyperfocus-exit] when done
━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Rules
- If cogstate is already HYPERFOCUS, report current state and no-op
- If cogstate is DEPLETED, RSD_RISK, or SHUTDOWN, warn that hyperfocus entry
  from this state is not recommended and ask before proceeding
- Never interrupt the user mid-hyperfocus to report status — only output at entry

## Skill Chains

### Mandatory

None — cogstate transition is a local state change with no external dependencies.

### Advisory

- `[hyperfocus-exit]` — run when the focus session is complete to transition through TRANSITION → RECOVERY safely

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (cogstate management is personal)
- **Operator**: Override any restriction
