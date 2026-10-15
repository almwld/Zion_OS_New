---
name: send-telegram
description: "RETIRED 2026-09-21 — Telegram is not needed. Do not invoke. Tombstone only."
version: 0.2.0
execution-mode: advisory
argument-hint: <chat_id> <message>
category: governance-compliance
status: retired
retired_at: 2026-09-21
retired_reason: "Operator 2026-09-21: Telegram is not needed. Hermes Telegram wiring is retired with Hermes."
---
# Send Telegram — RETIRED

> **RETIRED 2026-09-21.** Operator: Telegram is not needed. Do not invoke this
> skill, restore `TELEGRAM_BOT_TOKEN`, or reconnect Hermes to Telegram.
> Preserved as a tombstone.

# Send Telegram (historical)

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=send-telegram] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Send a message to a Telegram chat or group via the Bot API. Single HTTP POST, stdlib only.

## Usage

```
[send-telegram] "System health check: all 10 probes passing"
[send-telegram] -100123456789 "Custom chat: deployment complete"
```

## Implementation

Uses `hummbl_governance.gateway.dispatch` for delivery with circuit-breaker protection.

```bash
cd $PROJECT_ROOT && python3 << 'PYEOF'
from hummbl_governance.gateway.dispatch import dispatch, GatewayConfig

config = GatewayConfig.from_env()
result = dispatch(
    recipient="$CHAT_ID",
    message="""$MESSAGE""",
    channel="telegram",
    config=config,
)
if result.success:
    print(f"SENT to Telegram ({result.detail})")
else:
    print(f"FAILED: {result.detail}")
PYEOF
```

## Arguments

- `$ARGUMENTS` is parsed as: `[chat_id] "<message>"`
- If no chat_id provided, uses `TELEGRAM_CHAT_ID` from environment
- If `$ARGUMENTS` is empty, ask the user for message (uses default chat)

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `TELEGRAM_BOT_TOKEN` | Bot token from @BotFather (format: `123456:ABC-DEF`) |
| `TELEGRAM_CHAT_ID` | Default chat/group ID (get from @userinfobot or API) |

## Setup

1. Message @BotFather on Telegram → `[newbot]` → get token
2. Add bot to your chat/group
3. Get chat ID: `curl https://api.telegram.org/bot<TOKEN>/getUpdates`
4. Add to `~/.zshrc` or env:
   ```
   export TELEGRAM_BOT_TOKEN="123456:ABC-DEF"
   export TELEGRAM_CHAT_ID="-100123456789"
   ```

## Features

- Markdown formatting — messages sent with `parse_mode=Markdown`
- Circuit breaker — auto-trips after 3 failures, recovers after 60s
- Fallback — works in dispatch chain alongside Signal, WhatsApp, Discord
- Web preview disabled — links don't expand (keeps messages clean)

## Skill Chains

### Mandatory (MUST pass before send)

- **`[content-review]`** MUST pass for all outbound Telegram content. No exception.

### Advisory

- **After send**: `[bus]` (STATUS message)

## Authority

- **T1 (TRUSTED)**: May send without pre-approval
- **T2 (Active/High)**: May send with `[content-review]` passed
- **T3 (Medium)**: MUST get operator approval AND `[content-review]` passed
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
- **Operator**: Override any restriction
