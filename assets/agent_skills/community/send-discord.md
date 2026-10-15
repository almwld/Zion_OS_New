---
name: send-discord
description: "Send Discord webhook messages through hummbl_governance.gateway.dispatch with named webhooks and circuit-breaker protection."
version: 0.1.0
execution-mode: side_effecting
argument-hint: <server> <message>
category: governance-compliance
status: candidate
---
# Send Discord

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=send-discord] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Send a message to a Discord channel via webhook. Single HTTP POST, stdlib only, no bot token or gateway needed.

Hermes Discord bot apps are retired. Use webhooks only, not deleted Discord application bot tokens.

## Usage

```
[send-discord] team-lead "Forge update: all 37 tasks complete"
[send-discord] owner "Morning briefing attached"
[send-discord] default "System alert: kill switch engaged"
```

## Shortcuts

- `dan` → team Discord server (Forge channel)
- `owner` → the owner's Discord server
- `default` or empty → default webhook

## Implementation

Uses `hummbl_governance.gateway.dispatch` for delivery with circuit-breaker protection.

```bash
cd $PROJECT_ROOT && python3 << 'PYEOF'
from hummbl_governance.gateway.dispatch import dispatch, GatewayConfig

config = GatewayConfig.from_env()
result = dispatch(
    recipient="$RECIPIENT",
    message="""$MESSAGE""",
    channel="discord",
    config=config,
)
if result.success:
    print(f"SENT to Discord ({result.detail})")
else:
    print(f"FAILED: {result.detail}")
PYEOF
```

## Arguments

- `$ARGUMENTS` is parsed as: `<server> "<message>"`
- Server maps to a named webhook: `DISCORD_WEBHOOK_team`, `DISCORD_WEBHOOK_owner`, or `DISCORD_WEBHOOK_URL` (default)
- If `$ARGUMENTS` is empty, ask the user for server and message

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `DISCORD_WEBHOOK_URL` | Default webhook URL |
| `DISCORD_WEBHOOK_team` | team server webhook |
| `DISCORD_WEBHOOK_owner` | the owner's server webhook |

## Setup

1. In Discord: Server Settings → Integrations → Webhooks → New Webhook
2. Copy the webhook URL
3. Add to `~/.zshrc` or env: `export DISCORD_WEBHOOK_team="https://discord.com/api/webhooks/..."`

## Features

- Named webhooks — route to specific servers by name
- Circuit breaker — auto-trips after 3 consecutive failures, recovers after 60s
- Fallback — if used in a dispatch chain, falls through to next channel on failure
- No bot token, no WebSocket, no gateway process needed

## Skill Chains

### Mandatory (MUST pass before send)

- **`[content-review]`** MUST pass for all outbound Discord content. No exception.

### Advisory

- **After send**: `[bus]` (STATUS message)

## Authority

- **T1 (TRUSTED)**: May send without pre-approval
- **T2 (Active/High)**: May send with `[content-review]` passed
- **T3 (Medium)**: MUST get operator approval AND `[content-review]` passed
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
- **Operator**: Override any restriction
