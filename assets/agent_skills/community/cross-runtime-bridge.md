---
provider-specific: true
name: cross-runtime-bridge
description: Delegate tasks from Devin to opencode (background execution runtime). One-shot delegation, persistent server mode, and session continuation. Uses coordination bus for state sharing.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[delegate|serve|attach|sessions|status] [--message MSG] [--workdir DIR]"
category: fleet-ops
status: candidate
---
# Cross-Runtime Bridge

Delegates tasks from Devin (foreground orchestrator) to opencode (background execution runtime). This bridges the gap between Devin's interactive session and opencode's headless execution, enabling parallel work streams.

## When to Use
- Devin needs to delegate a coding task to opencode for background execution
- Running a long task in opencode while Devin continues other work
- Continuing an opencode session with follow-up questions
- Starting a persistent opencode server for multiple delegations

## Operations

### Delegate a task (one-shot)
```bash
python ~/bin/cross_runtime_bridge.py delegate "Fix the failing test in tests/test_foo.py" --workdir ~\Projects\hummbl-governance --auto
python ~/bin/cross_runtime_bridge.py delegate "Review this PR" --model cloudflare-workers-ai/glm-5.2 --auto
```

### Continue a session
```bash
python ~/bin/cross_runtime_bridge.py delegate "What did you find?" --session ses_xxxxx --workdir ~\Projects\hummbl-governance --auto
```

### Start a persistent server
```bash
python ~/bin/cross_runtime_bridge.py serve --port 4096
```

### Attach to a running server
```bash
python ~/bin/cross_runtime_bridge.py attach --url http://localhost:4096 --message "Run the tests"
```

### List sessions
```bash
python ~/bin/cross_runtime_bridge.py sessions
```

### Check bridge status
```bash
python ~/bin/cross_runtime_bridge.py status
```

## Architecture

```
Devin (foreground)                    opencode (background)
     |                                      |
     |-- delegate() --> opencode run ------->|
     |                       |               |
     |<-- response ---------|<-- JSON events|
     |                                      |
     |-- bus post (DELEGATION) ------------>|
     |                                      |
     |-- attach() --> opencode run --attach->|
     |   (to running server)                |
```

## State Management

- **Bridge state**: `~/_state/cross_runtime/bridge_state.json`
  - Server PID, URL, start time
  - Delegation history (last 5 shown in status)
  - Session registry (all known opencode session IDs)
- **Coordination bus**: Posts DELEGATION messages for cross-runtime visibility
- **opencode sessions**: Managed by opencode internally; bridge tracks IDs for continuation

## Delegation Flow

1. Devin calls `delegate()` with a message and optional workdir/model
2. Bridge posts to bus: "Delegating to opencode..."
3. Bridge runs `opencode run --format json --auto "<message>"`
4. opencode executes the task, streaming JSON events
5. Bridge parses events, extracts response text and session ID
6. Bridge posts to bus: "Delegation completed"
7. Response is returned to Devin

## Session Continuation

opencode sessions persist between calls. To continue a session:
1. Note the session ID from the first delegation (shown in stderr)
2. Pass `--session ses_xxxxx` to the next delegation
3. opencode resumes with full context

## Options

| Option | Description |
|--------|-------------|
| `--workdir` | Working directory for opencode |
| `--model` | Model to use (provider/model format) |
| `--auto` | Auto-approve permissions (dangerous but needed for headless) |
| `--agent` | opencode agent to use |
| `--session` | Continue an existing session |
| `--continue` | Continue the last session |
| `--timeout` | Timeout in seconds (default 300) |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCODE_BIN` | `opencode` | Path to opencode binary |
| `HUMMBL_BUS_BIN` | `~/bin/bus-global.py` | Path to bus writer |

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| Task delegated | Check status with `cross-runtime-bridge status` |
| Need to continue | Use `--session` with the returned session ID |
| Server mode needed | `cross-runtime-bridge serve` then `attach` |
| Track usage | `[usage-monitor]` to log Neuron consumption |

## Mandatory

None — delegation is advisory; operator confirms before execution.

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Operator notification required
- **T4 (Probationary)**: May not run
- **Operator**: Override any restriction
