---
name: context-export
description: Export live machine context as a pasteable block for claude.ai conversations
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--copy] to also copy to clipboard"
category: hummbl-research
status: candidate
---
# Context Export

Generate a pasteable context block for claude.ai conversations. Combines intent, health, bus state, and recent session info into a markdown block that gives web Claude awareness of your live infrastructure.

## When to Use
- Before switching to claude.ai for an ops conversation
- When you want to give web Claude current machine state
- At start of a claude.ai Project conversation

## Execution

```bash
./scripts/export-context.sh --copy
```

The script:
### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=context-export] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. Reads `_state/cognition/intent.md` (sprint, goals, active focus)
2. Runs the health probe (all adapters + services)
3. Scans bus for blockers and health transitions (last 24h)
4. Extracts last session close summary
5. Formats as markdown and copies to clipboard

## Output

Markdown block ready to paste into claude.ai. Includes:
- Current sprint and goals
- System health (per-adapter status)
- Bus pulse (entry count, last activity, active blockers)
- Last session close summary

## Usage

```
[context-export]         # print to terminal
[context-export] --copy  # also copy to clipboard
```

After running, switch to claude.ai and paste (Cmd+V) at the start of your message.

## Notes
- Health probe takes ~5s (network calls to adapters)
- Bus parsing is instant (local file)
- Intent is read directly from cognition state (no computation)
- The `--copy` flag uses macOS `pbcopy`

## Skill Chains

### Mandatory

None — read-only export; generates a text block from existing state without modifying anything.

### Advisory

- After `[context-export]` → paste into claude.ai conversation (manual step)
- Before `[context-export]` → `[health]` to ensure adapters are responsive for accurate export

## Authority

- **T1 (TRUSTED)**: May run freely
- **T2 (Active/High)**: May run freely
- **T3 (Medium)**: May run freely
- **T4 (Probationary)**: May run (read-only export — no state modified)
- **Operator**: Override any restriction
