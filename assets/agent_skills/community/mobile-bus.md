---
name: mobile-bus
description: Write to the coordination bus from any execution context (local or remote). Auto-detects local vs bridge write path.
version: 1.0.0
execution-mode: side_effecting
argument-hint: <from_id> <to_id> <type> <message>
category: fleet-ops
status: candidate
---
# Mobile Bus Write

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=mobile-bus] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Post a message to the coordination bus from any context — local terminal, Remote Control session, or Web-Hosted. Tries the local Python writer first; falls back to the HTTP bridge server automatically.

## Arguments

- `$1` — `from_id` (sender identity — must be a registered agent per `ROSTER.md`, e.g., `devin`, `codex`, `claude-code`, `opencode`, `gemini`)
- `$2` — `to_id` (recipient — usually `all`)
- `$3` — `type` (STATUS, BLOCKED, PROPOSAL, MILESTONE, DISPATCH, SITREP, ACK, NACK)
- `$4` — `message` (content — quote if it contains spaces)

## Execution

Parse arguments from $ARGUMENTS: from_id, to_id, msg_type, message.

**Step 1: Try local path**

```bash
python3 -m hummbl_governance.bus.bus_writer "$FROM" "$TO" "$TYPE" "$MESSAGE"
```

If exit code 0 → report "Posted to bus (local)" and stop.

**Step 2: If local fails, try bridge**

```bash
curl -s -o /tmp/bridge_response.json -w "%{http_code}" \
  -X POST "${BRIDGE_URL:-http://[REDACTED_NODE_IP]:18790/bus}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${BUS_BRIDGE_TOKEN:-}" \
  -d "{\"from\":\"$FROM\",\"to\":\"$TO\",\"type\":\"$TYPE\",\"message\":\"$MESSAGE\"}"
```

- HTTP 200 → report "Posted to bus (bridge: <BRIDGE_URL>)"
- HTTP 401 → report "Bridge rejected: token mismatch. Check BUS_BRIDGE_TOKEN env var."
- HTTP 400 → report "Bridge rejected: invalid sender identity '$FROM'. Must be a registered agent."
- Connection refused → report "Bridge not running. Start it: python3 -m hummbl_governance.bus.bridge_server --port 18790"

**Step 3: Both failed**

Report:
```
Bus write failed.
  Local: <error from step 1>
  Bridge: <error from step 2>

Diagnostics:
  Health: curl -s http://[REDACTED_NODE_IP]:18790/health
  Token set: echo ${BUS_BRIDGE_TOKEN:-(not set)}
  Local check: python3 -c "import hummbl_governance.bus.bus_writer"
```

## Environment

- `BRIDGE_URL` — bridge endpoint (default: `http://[REDACTED_NODE_IP]:18790/bus`)
- `BUS_BRIDGE_TOKEN` — Bearer token (from Keychain via ~/.zshenv)

## Examples

```
[mobile-bus] <from_id> all STATUS "PR review complete on feat/bridge-auth"
[mobile-bus] <from_id> all BLOCKED "Cannot resolve BUS_BRIDGE_TOKEN — is Keychain set?"
[mobile-bus] <from_id> codex PROPOSAL "Implement bus_watcher.py with polling strategy"
[mobile-bus] <from_id> all MILESTONE "bridge-daemon installed and healthy on MBP"
```

## Skill Chains

### Mandatory

None — bus write is a coordination primitive, identity-enforced.

### Advisory

- `[inbox-zero]` — check for unanswered bus messages after posting
- `[fleet-ssh-config]` — verify bridge connectivity if local write fails

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run (all agents need bus access)
- **T4 (Probationary)**: May post STATUS only (no DECISION/PROPOSAL)
- **Operator**: Override any restriction
