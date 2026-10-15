---
name: hyperfocus-exit
description: Exit hyperfocus mode — transition cogstate to TRANSITION then RECOVERY, restore interrupt availability, log session.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<optional: completion note or next state>"
category: data-science
status: candidate
---
# Hyperfocus Exit

Gracefully exits HYPERFOCUS state. Transitions through TRANSITION → RECOVERY
(the safe path). Restores briefing delivery and interrupt availability.
Logs session duration and outcome to the cognition ledger.

## When to Use
- Finishing a deep work session
- "Done with hyperfocus", "exiting flow", "coming up for air", "back online"
- After a natural break point in focused work

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=hyperfocus-exit] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Read current state
```bash
python3 -c "
import json
from hummbl_governance.services.cogstate import create_cogstate_manager, CogState
from pathlib import Path
mgr = create_cogstate_manager(state_dir=Path.home() / '.agents' / '_state' / 'cognition')
print(f'CURRENT: {mgr.current_state.value}')
print(f'SINCE: {mgr.current_record.timestamp}')
print(f'REASON: {mgr.current_record.reason}')
"
```

### 2. Somatic body scan (MANDATORY — Fitness Intervention)
Before transitioning, ask the operator to check body state:
- "How's your body right now?" → options: Energized / Okay / Tired / Depleted / Numb
- "Have you eaten in the last 4 hours?" → Yes / No / Don't remember
- "Any tension or pain?" → None / Some / Significant

This bridges the Somatic gap identified in the BKI assessment (So1=3, So3=3).
The transition window is where somatic signals get dropped — catching them HERE
prevents the "hyperfocus → crash" pattern.

Log the body scan result alongside the cogstate transition in the bus post.

### 3. Transition: HYPERFOCUS → TRANSITION → RECOVERY
```bash
python3 -c "
from hummbl_governance.services.cogstate import create_cogstate_manager, CogState
from pathlib import Path
mgr = create_cogstate_manager(state_dir=Path.home() / '.agents' / '_state' / 'cognition')
if mgr.current_state == CogState.HYPERFOCUS:
    mgr.transition(CogState.TRANSITION, reason='hyperfocus-exit: context switch')
    mgr.transition(CogState.RECOVERY, reason='$ARGUMENTS' if '$ARGUMENTS' else 'post-hyperfocus recovery')
    print(f'STATE: {mgr.current_state.value}')
else:
    print(f'SKIP: already {mgr.current_state.value}')
"
```

### 4. Log session to ledger
```bash
python3 -m hummbl_governance.cognition post-verified \
  --vendor "${AGENT_VENDOR:?set AGENT_VENDOR to the provider actually running}" --model "${AGENT_MODEL:?set AGENT_MODEL to the model actually running}" \
  --type lesson --scope session \
  --content "Hyperfocus session complete. Topic: <from entry record>. Exit reason: $ARGUMENTS" \
  --confidence 0.9 --tags "cogstate hyperfocus session-log audhd" \
  --assurance-level SELF
# The skill invocation runtime injects the caller's canonical identity as agent.
```

### 5. Post to bus
Post STATUS to the bus confirming exit to RECOVERY.
```
Type: STATUS
To: all
Message: HYPERFOCUS exited → RECOVERY. is_safe_to_interrupt=true. Briefing delivery restored.
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 6. Report + surface deferred items

Output format:
```
HYPERFOCUS EXIT | recovered
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
State now   RECOVERY → AVAILABLE (after rest)
Duration    <time since entry>
Exit note   $ARGUMENTS (or "session complete")
Interrupts  RESTORED — briefing delivery live
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Deferred while in HYPERFOCUS:
  • Check bus for messages since entry: tail -20 _state/coordination/messages.tsv
  • Any briefing delivery that was gated will run at next briefing cycle

Next:  rest before context-switching; [find-work] when AVAILABLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Rules
- If not in HYPERFOCUS, report current state and suggest the correct exit path
- Always go through TRANSITION before RECOVERY — never jump directly
- Surface deferred bus messages but do not deliver them automatically
- Suggest rest before immediately diving into next task (masking tax recovery)
- If exit reason suggests burnout ("crash", "burned out", "done"), transition to
  DEPLETED instead of RECOVERY and flag it

## Skill Chains

### Mandatory

None — cogstate transition is a local state change with no external dependencies.

### Advisory

- `[hyperfocus-enter]` — should have been run prior; exit assumes a prior HYPERFOCUS entry
- `[find-work]` — consider after RECOVERY completes and cogstate returns to AVAILABLE

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (cogstate management is personal)
- **Operator**: Override any restriction
