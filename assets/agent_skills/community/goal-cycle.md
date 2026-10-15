---
name: goal-cycle
description: Persistent goal-loop harness for selecting, completing, and immediately reselecting agent goals in a repeatable sequence.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "add|select|complete|block|loop|seed"
category: fleet-ops
status: candidate
---
# Goal Cycle Harness

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=goal-cycle] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Use this when an agent needs an explicit loop surface for bounded repetitive work:
pick one goal, complete it, then reselect the next goal.

## When to use

- You need a long-running local queue for agent tasks.
- You want explicit handoff evidence via a durable state + event log.
- You need a deterministic next-goal picker and completion marker before moving on.

## Commands

- Initialize:
  - `python $HOME/.agents/scripts/goal-harness.py init`
- Shortcut wrapper:
  - `powershell -ExecutionPolicy Bypass -File $HOME/.agents/scripts/goal-cycle.ps1 -Agent codex -Auto -Forever`
- Add one goal:
  - `python $HOME/.agents/scripts/goal-harness.py add "Goal title" --agent codex --details "..." --priority 80 --command "..."`
- One-shot loop:
  - `powershell -ExecutionPolicy Bypass -File $HOME/.agents/scripts/goal-cycle.ps1 -Agent codex -Auto`
- Select current goal:
  - `python $HOME/.agents/scripts/goal-harness.py select --agent codex`
- Complete:
  - `python $HOME/.agents/scripts/goal-harness.py complete --agent codex --notes "done with evidence"`
- Block (if can't progress):
  - `python $HOME/.agents/scripts/goal-harness.py block --agent codex --reason "dependency missing"`
- Filter per-agent queues:
  - `python $HOME/.agents/scripts/goal-harness.py list --agent codex --status open`
- Loop forever:
  - `python $HOME/.agents/scripts/goal-harness.py loop --agent codex --forever --poll 60`
- Seed from sample file (all goals assigned to the agent flag):
  - `python $HOME/.agents/scripts/goal-harness.py seed --agent codex --seed $HOME/.agents/goal-harness/seed-sample.json`
- Auto mode with timeout:
  - `python $HOME/.agents/scripts/goal-harness.py loop --agent codex --auto --forever --timeout 120`

## Suggested loop behavior

1. Keep goals scoped and bounded (one sentence title, one completion criterion).
2. Use `--command` for deterministic auto-complete loops.
3. In manual mode, pair `select` and `complete`.
4. Post bus receipts when a completed goal changes shared state, CI, or coordination artifacts.

## Operator-on-loop gate

**The persistent loop (`loop --auto --forever`) is operator-on-loop only.** Per `rules/goal-harness-operator-gate.md`, the goal-harness must not be deployed unattended. The `loop` subcommand requires an explicit `--operator-present` flag to run in `--auto --forever` mode; without it, the loop refuses to start.

- **Operator present** → `goal-harness.py loop --auto --forever --operator-present --agent <agent>` (or manual mode without `--auto`, which is operator-paced by definition).
- **Operator stepping away / unattended** → use `autoresearch-mode` (skill) or the `autoresearch-pipeline` / `autoresearch-reports` repos. Do NOT deploy the goal-harness.

One-shot commands (`add`, `select`, `complete`, `block`, `seed`, `list`, `record-verdict`) and `loop --once` are unaffected — only autonomous `--auto --forever` deployment is gated.

## Skill Chains

### Mandatory

None — goal management; uses `[goal-selection]` which is advisory (operator confirms goals).

### Advisory

- `[goal-selection]` — deterministic next-goal picker for selecting the current goal
- Post bus receipts when a completed goal changes shared state, CI, or coordination artifacts

## Authority

- **T1 (TRUSTED)**: May run (add, select, complete, block, loop, seed — all commands)
- **T2 (Active/High)**: May run (add, select, complete, block, loop, seed — all commands)
- **T3 (Medium)**: May run (add, select, complete, block, loop, seed — all commands)
- **T4 (Probationary)**: May run (advisory — operator confirms goals before execution)
- **Operator**: Override any restriction
