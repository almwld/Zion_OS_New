---
name: send-signal
description: "Send Signal messages through hummbl_governance.gateway.dispatch with circuit-breaker protection and explicit gateway configuration."
version: 0.2.0
execution-mode: side_effecting
argument-hint: <to> <message>
category: governance-compliance
status: candidate
---
# Send Signal

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=send-signal] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Send a Signal message through the maintained `hummbl_governance.gateway.dispatch` path. This replaces the old inline JSON-RPC/SSH tunnel snippet.

## Usage

```
[send-signal] team-lead "Hey, Arbiter brief is in your email"
[send-signal] owner "Test message"
[send-signal] +15551234567 "Direct number"
```

## Shortcuts

- `dan` or `team-lead` -> env `SIGNAL_DAN_NUMBER` or `SIGNAL_TEAM_LEAD`
- `owner` or `self` -> env `SIGNAL_REUBEN_NUMBER` or `SIGNAL_OWNER_NUMBER`

## Implementation

Uses the shared gateway with the Signal channel forced. The gateway resolves `SIGNAL_RPC_URL`, `SIGNAL_ACCOUNT`, circuit breaker state, and signal-cli RPC behavior.

```bash
cd $PROJECT_ROOT && python3 << 'PYEOF'
import os
import sys

from hummbl_governance.gateway.dispatch import GatewayConfig, dispatch

SHORTCUTS = {
    "dan": os.environ.get("SIGNAL_DAN_NUMBER") or os.environ.get("SIGNAL_TEAM_LEAD", ""),
    "team-lead": os.environ.get("SIGNAL_DAN_NUMBER") or os.environ.get("SIGNAL_TEAM_LEAD", ""),
    "owner": os.environ.get("SIGNAL_REUBEN_NUMBER") or os.environ.get("SIGNAL_OWNER_NUMBER", ""),
    "self": os.environ.get("SIGNAL_REUBEN_NUMBER") or os.environ.get("SIGNAL_OWNER_NUMBER", ""),
}

to = "$TO"
message = """$MESSAGE"""
recipient = SHORTCUTS.get(to, to)

if not recipient:
    print(f"ERROR: no Signal recipient for {to!r}. Provide +E.164 number, group ID, or configured shortcut.", file=sys.stderr)
    sys.exit(2)

result = dispatch(
    recipient=recipient,
    message=message,
    channel="signal",
    config=GatewayConfig.from_env(),
)

if result.success:
    print(f"SENT via Signal to {to} ({result.detail})")
else:
    print(f"FAILED Signal send to {to}: {result.detail}", file=sys.stderr)
    sys.exit(1)
PYEOF
```

## Arguments

- `$ARGUMENTS` parsed as: `<to> "<message>"`
- If no message is provided, generate concise content from current context before sending.
- Recipient may be a phone number, Signal group ID, or shortcut.

## Environment

| Variable | Purpose |
| --- | --- |
| `SIGNAL_RPC_URL` | Optional signal-cli JSON-RPC endpoint. If empty, gateway default resolution applies. |
| `SIGNAL_ACCOUNT` | Optional registered signal-cli account number. |
| `SIGNAL_DAN_NUMBER` / `SIGNAL_TEAM_LEAD` | Team lead shortcut. |
| `SIGNAL_REUBEN_NUMBER` / `SIGNAL_OWNER_NUMBER` | Owner/self shortcut. |

## Fallback

If Signal fails, use `[send-email]` for human-critical delivery:

```
[send-email] team-lead "Subject" "Message that was meant for Signal"
```

Signal depends on the gateway and signal-cli RPC availability. Email is the reliable fallback.

## Skill Chains

### Mandatory (MUST pass before send)

- **`[content-review]`** MUST pass for all outbound Signal content. No exception.

### Advisory

- **After send**: `[bus]` (STATUS message)
- **Fallback**: `[send-email]` if Signal unavailable

## Authority

- **T1 (TRUSTED)**: May send without pre-approval
- **T2 (Active/High)**: May send with `[content-review]` passed
- **T3 (Medium)**: MUST get operator approval AND `[content-review]` passed
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
- **Operator**: Override any restriction
