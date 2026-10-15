---
name: pair-mode
description: Structured pair programming with driver/navigator roles, rotation timer, shared context notes, and session summary
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<goal> [--rotate MINUTES] [--role driver|navigator]"
category: dev-tools
status: candidate
---
# Pair Mode

Structured pair programming session between the user and Claude. Establishes driver/navigator roles with timed rotations, maintains shared context notes throughout, and produces a session summary with learnings and decisions at the end.

## When to Use
- Tackling a complex feature that benefits from real-time collaboration
- Debugging a tricky issue where two perspectives help
- Onboarding onto unfamiliar code where narrated exploration builds understanding
- Writing safety-critical code that benefits from continuous review

## Execution
### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=pair-mode] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. Parse `$ARGUMENTS` for the session goal, rotation interval (default 15 minutes), and starting role.
2. Establish roles: **Driver** writes code, **Navigator** reviews, asks questions, and catches issues in real time.
3. Start the session with a brief plan: break the goal into small steps.
4. Track shared context notes as work progresses -- decisions made, alternatives considered, gotchas found.
5. At each rotation interval, prompt for role swap. Summarize what was accomplished in that rotation.
6. When the goal is complete or the user signals end, produce the session summary.
7. Record any learnings or decisions worth persisting.

## Output Format
```
Pair Mode | {goal}

## Session Setup
- Goal: {goal}
- Rotation: {N} minutes
- Starting roles: User={role}, Claude={role}

## Rotation {N} ({HH:MM - HH:MM})
- Driver: {who}
- Completed: {what was done}
- Notes: {decisions, gotchas, alternatives}

## Session Summary
- Goal status: {COMPLETE | PARTIAL | BLOCKED}
- Rotations: {N}
- Key decisions: {list}
- Gotchas found: {list}
- Code changed: {files list}

## Learnings
- {anything worth persisting to ledger or memory}

No further action needed. | Consider [retrospective] for deeper reflection.
```

## Skill Chains

### Mandatory

None — development workflow; local session management with no external impact.

### Advisory

- Session complete with learnings → `[retrospective]` to persist patterns
- Used TDD during pairing → `[tdd]` for continued red-green-refactor
- Want to adjust collaboration style → `[tempo]` to change interaction mode

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (local session, no external impact)
- **Operator**: Override any restriction
