---
name: weekly-digest
description: Weekly operational digest covering CRM pipeline, email activity, calendar, and content metrics.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--send] to email the digest to self, otherwise displays in terminal"
category: fleet-ops
status: candidate
---
# Weekly Digest

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=weekly-digest] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Generate a weekly operational digest covering CRM pipeline, email activity, content performance, calendar lookahead, and system health. Designed to run every Sunday at 4pm ET (manual or scheduled).

## Usage

```
[weekly-digest]          # Display digest in terminal
[weekly-digest] --send   # Display and email digest to $USER_EMAIL
```

## Arguments

- `$ARGUMENTS` is checked for `--send` flag
- If `--send` is present, the digest is emailed after display
- If `$ARGUMENTS` is empty, digest is displayed in terminal only

## Implementation

Execute the following sections in order. Each section is independent — if one fails (missing OAuth, unavailable API), skip it with a `[SKIPPED]` note and continue to the next.

### Section 1: CRM Pipeline Summary

Read the Google Sheets CRM. Use the Sheets API with the same OAuth credentials as Gmail.

```bash
python3 << 'PYEOF'
import json, urllib.request, urllib.parse, datetime

KEYS_PATH = "$HOME/.gmail-mcp/gcp-oauth.keys.json"
CREDS_PATH = "$HOME/.gmail-mcp/credentials.json"

def get_token():
    with open(KEYS_PATH) as f:
        keys = json.load(f)["installed"]
    with open(CREDS_PATH) as f:
        creds = json.load(f)
    data = urllib.parse.urlencode({
        "client_id": keys["client_id"],
        "client_secret": keys["client_secret"],
        "refresh_token": creds["refresh_token"],
        "grant_type": "refresh_token",
    }).encode()
    req = urllib.request.Request("https://oauth2.googleapis.com/token", data=data, method="POST")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())["access_token"]

# NOTE: Replace SPREADSHEET_ID with the actual CRM sheet ID.
# To find it: open the Google Sheet, copy the ID from the URL:
#   https://docs.google.com/spreadsheets/d/SPREADSHEET_ID/edit
SPREADSHEET_ID = "YOUR_CRM_SPREADSHEET_ID"

def fetch_sheet(sheet_name):
    token = get_token()
    url = f"https://sheets.googleapis.com/v4/spreadsheets/{SPREADSHEET_ID}/values/{urllib.parse.quote(sheet_name)}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read()).get("values", [])
    except Exception as e:
        print(f"[SKIPPED] Could not read sheet '{sheet_name}': {e}")
        return []

# Attempt to read CRM tabs — adjust tab names to match your actual sheet
for tab in ["Consulting Pipeline", "Job Search", "Network"]:
    rows = fetch_sheet(tab)
    if rows:
        print(f"\n### {tab}")
        print(f"Total rows: {len(rows) - 1}")  # minus header
        # Print header and first few rows for Claude to summarize
        for row in rows[:20]:
            print("\t".join(str(c) for c in row))
    else:
        print(f"\n### {tab}\n[No data or tab not found]")
PYEOF
```

Claude then summarizes the CRM output into:
- **Consulting pipeline**: count per stage, new leads this week, stale leads (no update >14 days)
- **Job search pipeline**: count per stage, applications sent this week, interviews scheduled
- **Network**: new connections this week
- **Action items**: contacts needing immediate follow-up

If the Sheets API is unavailable (scope not granted, sheet ID not set), output:
```
### CRM Pipeline
[SKIPPED] Google Sheets API not configured. Set SPREADSHEET_ID in the skill
and ensure Sheets API is enabled in your GCP project.

Required scope: https://www.googleapis.com/auth/spreadsheets.readonly
```

### Section 2: Email Activity Summary

For each Gmail account, query the last 7 days of email activity.

```bash
python3 << 'PYEOF'
import json, urllib.request, urllib.parse, datetime

KEYS_PATH = "$HOME/.gmail-mcp/gcp-oauth.keys.json"
CREDS_PATH = "$HOME/.gmail-mcp/credentials.json"

def get_token():
    with open(KEYS_PATH) as f:
        keys = json.load(f)["installed"]
    with open(CREDS_PATH) as f:
        creds = json.load(f)
    data = urllib.parse.urlencode({
        "client_id": keys["client_id"],
        "client_secret": keys["client_secret"],
        "refresh_token": creds["refresh_token"],
        "grant_type": "refresh_token",
    }).encode()
    req = urllib.request.Request("https://oauth2.googleapis.com/token", data=data, method="POST")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())["access_token"]

token = get_token()
seven_days_ago = (datetime.datetime.now() - datetime.timedelta(days=7)).strftime("%Y/%m/%d")

# --- Unread count ---
def get_unread_count():
    url = "https://gmail.googleapis.com/gmail/v1/users/me/labels/UNREAD"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read())
            return data.get("messagesTotal", "?")
    except Exception:
        # Fallback: query INBOX for unread
        url2 = "https://gmail.googleapis.com/gmail/v1/users/me/labels/INBOX"
        req2 = urllib.request.Request(url2, headers={"Authorization": f"Bearer {token}"})
        with urllib.request.urlopen(req2) as resp:
            data = json.loads(resp.read())
            return data.get("messagesUnread", "?")

# --- Messages received this week ---
def count_messages(query):
    url = f"https://gmail.googleapis.com/gmail/v1/users/me/messages?q={urllib.parse.quote(query)}&maxResults=1"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
        return data.get("resultSizeEstimate", 0)

# --- Starred messages ---
def get_starred_count():
    url = "https://gmail.googleapis.com/gmail/v1/users/me/labels/STARRED"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
        return data.get("messagesTotal", 0)

try:
    unread = get_unread_count()
    received = count_messages(f"after:{seven_days_ago} in:inbox")
    sent = count_messages(f"after:{seven_days_ago} in:sent")
    starred = get_starred_count()

    print("### Email Activity ($USER_EMAIL)")
    print(f"- Unread: {unread}")
    print(f"- Received this week: {received}")
    print(f"- Sent this week: {sent}")
    print(f"- Starred/flagged: {starred}")
except Exception as e:
    print(f"### Email Activity\n[SKIPPED] Gmail API error: {e}")

# Note: $RESEARCH_EMAIL and $ORG_EMAIL require separate
# OAuth tokens. If additional credential files exist, repeat the pattern.
# For now, only the primary account is queried.
print("\n### Email Activity ($RESEARCH_EMAIL)")
print("[SKIPPED] Separate OAuth token required. Add credentials to enable.")
print("\n### Email Activity ($ORG_EMAIL)")
print("[SKIPPED] Separate OAuth token required. Add credentials to enable.")
PYEOF
```

### Section 3: Calendar Lookahead

Use the Google Calendar API (same OAuth as above) to fetch next week's events.

```bash
python3 << 'PYEOF'
import json, urllib.request, urllib.parse, datetime

KEYS_PATH = "$HOME/.gmail-mcp/gcp-oauth.keys.json"
CREDS_PATH = "$HOME/.gmail-mcp/credentials.json"

def get_token():
    with open(KEYS_PATH) as f:
        keys = json.load(f)["installed"]
    with open(CREDS_PATH) as f:
        creds = json.load(f)
    data = urllib.parse.urlencode({
        "client_id": keys["client_id"],
        "client_secret": keys["client_secret"],
        "refresh_token": creds["refresh_token"],
        "grant_type": "refresh_token",
    }).encode()
    req = urllib.request.Request("https://oauth2.googleapis.com/token", data=data, method="POST")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())["access_token"]

token = get_token()

# Next Monday through Sunday
today = datetime.date.today()
days_until_monday = (7 - today.weekday()) % 7
if days_until_monday == 0:
    days_until_monday = 7
next_monday = today + datetime.timedelta(days=days_until_monday)
next_sunday = next_monday + datetime.timedelta(days=6)

time_min = f"{next_monday.isoformat()}T00:00:00Z"
time_max = f"{next_sunday.isoformat()}T23:59:59Z"

url = (
    "https://www.googleapis.com/calendar/v3/calendars/primary/events"
    f"?timeMin={urllib.parse.quote(time_min)}"
    f"&timeMax={urllib.parse.quote(time_max)}"
    "&singleEvents=true&orderBy=startTime&maxResults=50"
)
req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})

try:
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
        events = data.get("items", [])

    print(f"### Calendar: {next_monday} to {next_sunday}")
    print(f"Total events: {len(events)}\n")

    for ev in events:
        start = ev.get("start", {}).get("dateTime", ev.get("start", {}).get("date", "?"))
        end = ev.get("end", {}).get("dateTime", ev.get("end", {}).get("date", ""))
        summary = ev.get("summary", "(No title)")
        location = ev.get("location", "")
        attendees = ev.get("attendees", [])
        att_count = len(attendees)

        print(f"- {start} | {summary}")
        if location:
            print(f"  Location: {location}")
        if att_count > 0:
            print(f"  Attendees: {att_count}")

    if not events:
        print("No events scheduled.")
except Exception as e:
    print(f"### Calendar Lookahead\n[SKIPPED] Calendar API error: {e}")
    print("Ensure Calendar API is enabled and OAuth scope includes:")
    print("https://www.googleapis.com/auth/calendar.readonly")
PYEOF
```

Claude then reviews the event list and flags:
- Consulting calls (prep needed)
- Interviews (prep needed)
- Conflicts or back-to-back meetings (<15 min gap)
- All-day events or deadlines

### Section 4: Content and Growth Metrics

```bash
# GitHub stars/forks for pinned repos
echo "### GitHub Metrics (your-org)"
for repo in your-package mcp-server base120 arbiter agentic-patterns governed-iac-reference; do
    stats=$(gh api "repos/your-org/$repo" --jq '"\(.stargazers_count) stars, \(.forks_count) forks, \(.open_issues_count) open issues"' 2>/dev/null)
    if [ -n "$stats" ]; then
        echo "- $repo: $stats"
    else
        echo "- $repo: [unavailable]"
    fi
done

echo ""

# PyPI downloads for your-package
echo "### PyPI Downloads (your-package)"
curl -s "https://pypistats.org/api/packages/your-package/recent" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)['data']
    print(f\"- Last day: {data.get('last_day', '?')}\")
    print(f\"- Last week: {data.get('last_week', '?')}\")
    print(f\"- Last month: {data.get('last_month', '?')}\")
except Exception as e:
    print(f'[SKIPPED] PyPI stats unavailable: {e}')
"

echo ""
echo "### Manual Entry (update these weekly)"
echo "- Linktree clicks: ___"
echo "- X followers: ___"
echo "- X impressions (7d): ___"
echo "- LinkedIn connections: ___"
echo "- LinkedIn post impressions (7d): ___"
echo "- Newsletter subscribers: ___"
```

### Section 5: Bus and System Health

```bash
echo "### Coordination Bus (last 7 days)"
# Count messages by type from the last 7 days
python3 << 'PYEOF'
import datetime, os

BUS_PATH = os.path.expanduser("~/$PROJECT_ROOT/_state/coordination/messages.tsv") if os.path.exists(os.path.expanduser("~/$PROJECT_ROOT/_state/coordination/messages.tsv")) else os.path.expanduser("$HOME/$PROJECT_ROOT/_state/coordination/messages.tsv")

# Try both possible paths
for path in ["$HOME/$PROJECT_ROOT/_state/coordination/messages.tsv", "$HOME/$PROJECT_ROOT/_state/coordination/messages.tsv"]:
    if os.path.exists(path):
        BUS_PATH = path
        break
else:
    print("[SKIPPED] Bus file not found")
    import sys; sys.exit(0)

cutoff = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=7)).isoformat()
type_counts = {}
agent_counts = {}
total = 0

with open(BUS_PATH) as f:
    for line in f:
        parts = line.strip().split("\t")
        if len(parts) < 5:
            continue
        ts, frm, to, mtype, msg = parts[0], parts[1], parts[2], parts[3], parts[4] if len(parts) > 4 else ""
        if ts >= cutoff[:10]:  # rough date comparison
            total += 1
            type_counts[mtype] = type_counts.get(mtype, 0) + 1
            agent_counts[frm] = agent_counts.get(frm, 0) + 1

print(f"Total messages (7d): {total}")
print("\nBy type:")
for t, c in sorted(type_counts.items(), key=lambda x: -x[1]):
    print(f"  {t}: {c}")
print("\nBy agent:")
for a, c in sorted(agent_counts.items(), key=lambda x: -x[1]):
    print(f"  {a}: {c}")
PYEOF

echo ""

# Health probe (if available)
echo "### System Health"
cd $HOME && python3 -m hummbl_governance.services.health 2>/dev/null || echo "[SKIPPED] Health probe unavailable"
```

### Section 6: Compile and Output

Claude compiles all section outputs into a single markdown digest with this structure:

```markdown
# Weekly Operational Digest
**Week of {monday} to {sunday}** | Generated {timestamp}

---

## CRM Pipeline
{Section 1 summary}

## Email Activity
{Section 2 summary}

## Calendar Lookahead
{Section 3 summary with flags}

## Content & Growth
{Section 4 metrics}

## System Health
{Section 5 summary}

---

## Action Items
1. {highest priority items extracted from all sections}
2. ...

## Notes
- {any skipped sections and why}
- {manual entry placeholders to fill}
```

### Section 7: Send (if --send flag)

If `$ARGUMENTS` contains `--send`, email the compiled digest:

Read `$HOME/.agents/skills/send-email/SKILL.md` and use its Gmail API pattern to send:
- **To**: $USER_EMAIL
- **Subject**: `Weekly Digest -- {monday} to {sunday}`
- **Body**: The full markdown digest

Use the send-email skill's `get_token()` and `send()` pattern. The body should be the complete digest text.

### Section 8: Bus Receipt

Post a STATUS to the bus naming the digest completion.
```
Type: STATUS
To: all
Message: Weekly digest generated for {monday} to {sunday}
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

## Setup: Scheduled Execution

To run automatically every Sunday at 4pm ET, create a launchd plist:

```bash
cat > ~/Library/LaunchAgents/com.yourorg.weekly-digest.plist << 'XML'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.yourorg.weekly-digest</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>cd $HOME &amp;&amp; $HOME/.claude/bin/claude -p "Run [weekly-digest] --send" --allowedTools Bash,Read,Write,WebFetch 2>&1 >> /tmp/weekly-digest.log</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>20</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/weekly-digest-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/weekly-digest-stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
        <key>HOME</key>
        <string>$HOME</string>
    </dict>
</dict>
</plist>
XML

launchctl load ~/Library/LaunchAgents/com.yourorg.weekly-digest.plist
```

Note: `Weekday=0` is Sunday. `Hour=20` is 8pm UTC = 4pm ET (during EDT). Adjust to `Hour=21` during EST (November-March).

To test the schedule:
```bash
launchctl start com.yourorg.weekly-digest
```

To unload:
```bash
launchctl unload ~/Library/LaunchAgents/com.yourorg.weekly-digest.plist
```

## Prerequisites

- OAuth credentials at `~/.gmail-mcp/gcp-oauth.keys.json` and `~/.gmail-mcp/credentials.json`
- Gmail API enabled on your GCP project (already done for send-email skill)
- Google Calendar API enabled (already done for hummbl-governance calendar adapter)
- Google Sheets API enabled (may need to be added for CRM section)
- `gh` CLI authenticated (for GitHub metrics)
- `curl` available (for PyPI stats)
- Bus writer module at `hummbl_governance.bus.bus_writer` (for receipt posting)

## Scopes Required

The OAuth token needs these scopes (some may already be granted):
- `https://www.googleapis.com/auth/gmail.readonly` -- email activity
- `https://www.googleapis.com/auth/gmail.send` -- sending the digest (if --send)
- `https://www.googleapis.com/auth/calendar.readonly` -- calendar lookahead
- `https://www.googleapis.com/auth/spreadsheets.readonly` -- CRM pipeline

If a scope is missing, that section is skipped with a `[SKIPPED]` note.

## Error Handling

- Each section runs independently. A failure in one does not block others.
- `invalid_grant` on token refresh: re-auth via `cd ~/.npm/_npx/952459504b2da320/node_modules/@gongrzhe/server-gmail-autoauth-mcp && node dist/index.js auth`
- `403 insufficient permissions`: the required API or scope is not enabled. Note which one in the skip message.
- Network errors: note and skip. The digest still generates with available data.
- Missing CRM spreadsheet ID: the CRM section is skipped until configured. Set the ID in Section 1.

## Skill Chains

### Mandatory

None — read-only aggregation. No pre-chain required; this skill reads existing data sources and compiles a digest.

### Advisory

- `[weekly-digest]` → `[send-email]` — if `--send` flag is used, email the digest to self
- `[weekly-digest]` → `[investor-update]` — if the digest surfaces metrics worth a formal update
- `[weekly-digest]` → `[follow-up]` — if CRM pipeline shows stale leads needing action
- Run after `[evening-touchdown]` on Sundays for the full weekly close sequence

## Authority

- **T1 (TRUSTED)**: Full run — generate, display, and send digest
- **T2 (Active/High)**: Full run — generate, display, and send digest
- **T3 (Medium)**: Full run — generate, display, and send digest
- **T4 (Probationary)**: Read-only — may generate and display the digest but must not send email without operator approval
- **Operator**: Override any restriction
