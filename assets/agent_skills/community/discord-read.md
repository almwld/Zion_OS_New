---
name: discord-read
description: Read Discord channel history via Bot API — stdlib only, read-only, no writes
version: 0.1.0
execution-mode: advisory
argument-hint: "<channel-name> [--limit N] [--since YYYY-MM-DD]"
category: fleet-ops
status: candidate
---
# Discord Read

Pull message history from Discord channels via Bot API. Read-only — never posts, edits, or deletes.

## Usage

```
[discord-read] sovereign
[discord-read] phantom --limit 50
[discord-read] general --since 2026-04-14
[discord-read] all --limit 10
```

## Channel Map

The Forge server (Dan Matha's Discord, guild `1477041621164884148`):

| Shortcut | Channel | ID | Agent |
|----------|---------|-----|-------|
| `general` | #general | 1477041624117936160 | Brand Voice |
| `sovereign` | #sovereign | 1481830166861713460 | Sovereign |
| `phantom` | #phantom | 1481830182737285181 | Phantom |
| `forge` | #forge | 1481830177204994069 | Forge |
| `briefing` | #morning-briefing | 1477853929491398737 | Herald |
| `sov-fm` | #sov-foundermode | 1487172536767615209 | Sov |
| `sov-jsr` | #sov-jsr | 1487172701566275697 | Sov |
| `sov-pc` | #sov-peptidecheck | 1487172655315419258 | Sov |

## Token Resolution

The skill reads the bot token from remote-node's OpenClaw config via SSH (remote-node dormant since 2026-07-01 — SSH expected UNREACHABLE, use Keychain fallback):

```bash
TOKEN=$(ssh -o ConnectTimeout=5 mini 'python3 -c "
import json
with open(\"$REMOTE_HOST/.openclaw-dan/openclaw.json\") as f:
    print(json.load(f)[\"channels\"][\"discord\"][\"token\"])
"' 2>/dev/null)  # remote-node dormant since 2026-07-01 — expected UNREACHABLE
```

Fallback: MBP Keychain (`security find-generic-password -s "DISCORD_BOT_TOKEN" -a "$(whoami)" -w`).

Note: The `.env` token (`MTQ4NzE2...`, Sov bot) is **stale** — returns 403 on all endpoints.
The working token is in `openclaw.json` (`MTQ3NzA0...`, Forge Bot) — works for channel reads but 403 on `/users/@me`.

## Implementation

```python
#!/usr/bin/env python3
"""Discord channel reader — stdlib only."""

import json
import urllib.request
import sys
import os
from datetime import datetime, timezone

DISCORD_EPOCH = 1420070400000
GUILD_ID = "1477041621164884148"

CHANNELS = {
    "general": "1477041624117936160",
    "sovereign": "1481830166861713460",
    "phantom": "1481830182737285181",
    "forge": "1481830177204994069",
    "briefing": "1477853929491398737",
    "sov-fm": "1487172536767615209",
    "sov-jsr": "1487172701566275697",
    "sov-pc": "1487172655315419258",
}


def snowflake_to_date(sid: str) -> str:
    ts = ((int(sid) >> 22) + DISCORD_EPOCH) / 1000
    return datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%Y-%m-%d %H:%M UTC")


def date_to_snowflake(date_str: str) -> str:
    dt = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    ms = int(dt.timestamp() * 1000)
    return str((ms - DISCORD_EPOCH) << 22)


def get_token() -> str:
    """Try remote-node SSH first, then Keychain. (remote-node dormant since 2026-07-01 — SSH expected to fail)"""
    import subprocess

    # Method 1: SSH to remote-node (dormant since 2026-07-01 — expected to fail)
    try:
        result = subprocess.run(
            ["ssh", "-o", "ConnectTimeout=5", "mini",
             'python3 -c "import json; f=open(\\"$REMOTE_HOST/.openclaw-dan/openclaw.json\\"); print(json.load(f)[\\"channels\\"][\\"discord\\"][\\"token\\"])"'],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except Exception:
        pass

    # Method 2: Keychain
    try:
        result = subprocess.run(
            ["security", "find-generic-password", "-s", "DISCORD_BOT_TOKEN",
             "-a", os.environ.get("USER", "others"), "-w"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except Exception:
        pass

    return ""


def fetch_messages(token: str, channel_id: str, limit: int = 50,
                   after: str | None = None) -> list[dict]:
    """Fetch messages from a Discord channel. Paginates if limit > 100."""
    headers = {"Authorization": f"Bot {token}", "User-Agent": "FounderMode/1.0"}
    all_msgs = []
    remaining = limit

    while remaining > 0:
        batch = min(remaining, 100)
        url = f"https://discord.com/api/v10/channels/{channel_id}/messages?limit={batch}"
        if after:
            url += f"&after={after}"

        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=15) as resp:
            msgs = json.loads(resp.read())

        if not msgs:
            break

        all_msgs.extend(msgs)
        remaining -= len(msgs)

        if len(msgs) < batch:
            break

        # For pagination: use the oldest message ID as the next "before"
        if not after:
            # Going backwards (newest first) — use last msg as before
            url_base = f"https://discord.com/api/v10/channels/{channel_id}/messages?limit={min(remaining, 100)}&before={msgs[-1]['id']}"
            # Re-fetch with before
            after = None
        else:
            after = msgs[0]["id"]

        import time
        time.sleep(0.5)  # Rate limit courtesy

    # Return in chronological order
    all_msgs.reverse()
    return all_msgs


def format_message(msg: dict) -> str:
    author = msg.get("author", {}).get("username", "?")
    content = msg.get("content", "") or ""
    ts = msg.get("timestamp", "")[:19]
    embeds = msg.get("embeds", [])

    embed_text = ""
    if embeds:
        for emb in embeds:
            if emb.get("title"):
                embed_text += f" [EMBED: {emb['title']}]"
            if emb.get("description"):
                embed_text += f" {emb['description'][:100]}"

    return f"[{ts}] {author}: {content[:300]}{embed_text}"


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Read Discord channel history")
    parser.add_argument("channel", help="Channel name or 'all'")
    parser.add_argument("--limit", type=int, default=20, help="Messages per channel")
    parser.add_argument("--since", type=str, help="Only messages after YYYY-MM-DD")
    parser.add_argument("--json", action="store_true", help="Output raw JSON")
    args = parser.parse_args()

    token = get_token()
    if not token:
        print("ERROR: No Discord bot token found (tried SSH + Keychain)")
        sys.exit(1)

    targets = CHANNELS if args.channel == "all" else {args.channel: CHANNELS.get(args.channel)}
    if None in targets.values():
        print(f"Unknown channel: {args.channel}")
        print(f"Available: {', '.join(CHANNELS.keys())}")
        sys.exit(1)

    after = date_to_snowflake(args.since) if args.since else None

    for name, ch_id in targets.items():
        msgs = fetch_messages(token, ch_id, limit=args.limit, after=after)
        if args.json:
            print(json.dumps(msgs, indent=2))
        else:
            print(f"\n{'=' * 60}")
            print(f"# {name} ({len(msgs)} messages)")
            print(f"{'=' * 60}")
            for m in msgs:
                print(format_message(m))


if __name__ == "__main__":
    main()
```

## Examples

```bash
# Quick check — last 5 messages from sovereign
python3 discord_read.py sovereign --limit 5

# Full channel dump as JSON
python3 discord_read.py phantom --limit 100 --json > /tmp/phantom.json

# Messages since a date
python3 discord_read.py general --since 2026-04-14

# All channels, 3 messages each (overview)
python3 discord_read.py all --limit 3
```

## Notes

- **Read-only.** This skill never writes, edits, reacts, or deletes anything in Discord.
- **Token source**: Dan's OpenClaw config on remote-node (dormant since 2026-07-01 — SSH expected UNREACHABLE, use Keychain fallback). Protected surface — we read the token, never modify the config.
- **Rate limiting**: 0.5s delay between pagination requests. Discord rate limit is 5 req/5s per channel.
- **The `/users/@me` endpoint returns 403** with this token, but channel reads work. This is a Discord permission quirk — the bot has channel access but not the identify scope.
