---
name: follow-up
description: Check CRM for stale leads and consulting contacts needing follow-up, draft emails
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--send] to actually send drafts, otherwise just shows what would be sent"
category: sales-marketing
status: candidate
---
# Follow-Up

Check the CRM for stale leads and consulting contacts that need follow-up. Drafts stage-appropriate emails and optionally sends them.

## Usage

```
[follow-up]              # Show drafts only (dry run)
[follow-up] --send       # Send follow-up emails and update CRM
```

## Arguments

- `--send` flag: actually send the drafted emails via Gmail API
- Without `--send`: display drafts for review, no emails sent, no CRM updates

## Workflow

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=follow-up] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### Step 1 -- Read CRM Data

Fetch all rows from the Consulting pipeline sheet.

```bash
python3 << 'PYEOF'
import json, urllib.request, urllib.parse

KEYS_PATH = "$HOME/.gmail-mcp/gcp-oauth.keys.json"
CREDS_PATH = "$HOME/.gmail-mcp/credentials.json"

# CONFIGURE: Set your Google Sheets spreadsheet ID
SPREADSHEET_ID = "$SPREADSHEET_ID"  # Replace with actual CRM spreadsheet ID
RANGE = "Consulting!A:G"  # Columns: Name, Email, Source, Stage, Notes, Date Added, Last Interaction

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

def read_crm():
    token = get_token()
    url = (
        f"https://sheets.googleapis.com/v4/spreadsheets/{SPREADSHEET_ID}"
        f"/values/{urllib.parse.quote(RANGE)}"
    )
    req = urllib.request.Request(
        url, headers={"Authorization": f"Bearer {token}"}, method="GET",
    )
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read())
        rows = result.get("values", [])
        # Print as JSON for parsing
        print(json.dumps(rows))

read_crm()
PYEOF
```

### Step 2 -- Identify Stale Contacts

Parse the CRM data and find contacts needing follow-up based on stage and last interaction date:

| Stage | Stale After |
|-------|-------------|
| Proposal | 3 days |
| Discovery | 5 days |
| Lead | 7 days |
| Qualified | 7 days |

Skip contacts in stages: Won, Lost, Closed, On Hold.

```bash
python3 << 'PYEOF'
import json, sys, datetime

# Input: JSON array of rows from Step 1 (passed via variable or stdin)
# Row format: [Name, Email, Source, Stage, Notes, Date Added, Last Interaction]

STALE_THRESHOLDS = {
    "Proposal": 3,
    "Discovery": 5,
    "Lead": 7,
    "Qualified": 7,
}

SKIP_STAGES = {"Won", "Lost", "Closed", "On Hold", ""}

def find_stale(rows):
    today = datetime.date.today()
    stale = []
    # Skip header row
    for i, row in enumerate(rows[1:], start=2):
        if len(row) < 7:
            continue
        name, email, source, stage, notes, date_added, last_interaction = row[:7]
        if stage in SKIP_STAGES:
            continue
        threshold = STALE_THRESHOLDS.get(stage)
        if threshold is None:
            continue
        try:
            last_date = datetime.date.fromisoformat(last_interaction)
        except (ValueError, TypeError):
            continue
        days_since = (today - last_date).days
        if days_since >= threshold:
            stale.append({
                "row": i,
                "name": name,
                "email": email,
                "source": source,
                "stage": stage,
                "notes": notes,
                "last_interaction": last_interaction,
                "days_since": days_since,
            })
    print(json.dumps(stale, indent=2))

# Replace $CRM_JSON with the output from Step 1
rows = json.loads("""$CRM_JSON""")
find_stale(rows)
PYEOF
```

### Step 3 -- Draft Follow-Up Emails

For each stale contact, generate an email appropriate to their stage:

**Lead / Qualified:**
```
Subject: Following up -- your organization

Hi {first_name},

I wanted to follow up on your inquiry. I specialize in AI platform
engineering, infrastructure automation, and developer tooling -- and
I'd love to learn more about what you're working on.

If you'd like to set up a quick call, here's my calendar:
https://cal.com/hummbl

Happy to answer any questions in the meantime.

Best,
$USER_NAME
Your Company -- consulting signature
$USER_EMAIL
```

**Discovery:**
```
Subject: Following up on our conversation -- your organization

Hi {first_name},

I wanted to check in after our conversation. I've been thinking about
your situation and have a few ideas I'd like to share.

Do you have any questions about the approach we discussed? Happy to
hop on another call if it would be helpful:
https://cal.com/hummbl

Best,
$USER_NAME
Your Company -- consulting signature
$USER_EMAIL
```

**Proposal:**
```
Subject: Checking in on the proposal -- your organization

Hi {first_name},

I wanted to check if you've had a chance to review the proposal I sent
over. I'm happy to walk through any of the details or adjust the scope
if needed.

Let me know if you'd like to schedule a quick call:
https://cal.com/hummbl

Best,
$USER_NAME
Your Company -- consulting signature
$USER_EMAIL
```

### Step 4 -- Send or Display

**If `--send` flag is present:** Send each email via Gmail API from $USER_EMAIL.

```bash
python3 << 'PYEOF'
import json, base64, urllib.request, urllib.parse
from email.mime.text import MIMEText

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

def send(to, subject, body):
    token = get_token()
    msg = MIMEText(body)
    msg["to"] = to
    msg["from"] = "$USER_EMAIL"
    msg["subject"] = subject
    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
    payload = json.dumps({"raw": raw}).encode()
    req = urllib.request.Request(
        "https://gmail.googleapis.com/gmail/v1/users/me/messages/send",
        data=payload,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read())
        print(f"SENT | to={to} | id={result['id']} | thread={result['threadId']}")

# Called per contact: send("$TO", "$SUBJECT", """$BODY""")
PYEOF
```

**If no `--send` flag:** Display each draft for review:

```
Follow-Up Drafts | 3 contacts need follow-up

  1. Jane Smith (jane@example.com)
     Stage: Proposal | Last contact: 5 days ago
     Subject: Checking in on the proposal -- your organization
     [Draft body preview...]

  2. Alex Chen (alex@chen.io)
     Stage: Lead | Last contact: 10 days ago
     Subject: Following up -- your organization
     [Draft body preview...]

  Run `[follow-up] --send` to send these emails.
```

### Step 5 -- Update CRM Last Interaction (only if --send)

After sending, update the "Last Interaction" column for each contact that received a follow-up.

```bash
python3 << 'PYEOF'
import json, urllib.request, urllib.parse, datetime

KEYS_PATH = "$HOME/.gmail-mcp/gcp-oauth.keys.json"
CREDS_PATH = "$HOME/.gmail-mcp/credentials.json"
SPREADSHEET_ID = "$SPREADSHEET_ID"

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

def update_last_interaction(row_number):
    """Update column G (Last Interaction) for a given row."""
    token = get_token()
    today = datetime.date.today().isoformat()
    cell_range = f"Consulting!G{row_number}"
    payload = json.dumps({"values": [[today]]}).encode()
    url = (
        f"https://sheets.googleapis.com/v4/spreadsheets/{SPREADSHEET_ID}"
        f"/values/{urllib.parse.quote(cell_range)}"
        f"?valueInputOption=USER_ENTERED"
    )
    req = urllib.request.Request(
        url, data=payload,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="PUT",
    )
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read())
        print(f"CRM_UPDATED | row={row_number} | cell={cell_range} | date={today}")

# Called per contact: update_last_interaction($ROW_NUMBER)
PYEOF
```

### Step 6 -- Post Bus Message

Post STATUS to the bus with the follow-up summary.
```
Type: STATUS
To: all
Message: Follow-up check: $SENT_COUNT emails sent, $STALE_COUNT stale contacts found
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### Step 7 -- Output Summary

```
Follow-Up | $DATE

  Contacts checked:  $TOTAL_COUNT
  Stale found:       $STALE_COUNT
  Emails sent:       $SENT_COUNT (or "0 -- dry run, use --send to send")

  Details:
    - Jane Smith (Proposal, 5 days) -- SENT
    - Alex Chen (Lead, 10 days) -- SENT
    - Bob Lee (Discovery, 3 days) -- not yet stale (threshold: 5 days)

  Next action: Run again in 2-3 days, or [lead-intake] for new leads
```

## Prerequisites

- OAuth credentials at `~/.gmail-mcp/gcp-oauth.keys.json`
- Refresh token at `~/.gmail-mcp/credentials.json`
- Google Sheets API enabled on the `hummbl` GCP project
- Gmail API enabled with send scope
- `$SPREADSHEET_ID` must be set to the actual CRM spreadsheet ID before first use

## Setup Note

Before first use, replace `$SPREADSHEET_ID` in Steps 1, 5 with the actual Google Sheets ID for the Consulting CRM. The sheet should have columns: Name, Email, Source, Stage, Notes, Date Added, Last Interaction.

## Error Handling

- `invalid_grant` -- refresh token expired. Re-auth via: `cd ~/.npm/_npx/952459504b2da320/node_modules/@gongrzhe/server-gmail-autoauth-mcp && node dist/index.js auth`
- `403 insufficient permissions` -- Sheets or Gmail API not enabled, or scopes missing
- If CRM read fails, report error and stop (no data to work with)
- If an individual email fails, continue with remaining contacts and report failures

## Skill Chains

### Mandatory

- `[content-review]` MUST pass before sending any drafted emails (`--send` flag). Drafting without `--send` does not require this chain.

### Advisory

- `[crm]` — update CRM last-interaction timestamp after sending follow-up emails
- `[lead-intake]` — for new leads identified during follow-up review

## Authority

- **T1 (TRUSTED)**: May run (draft freely; sending requires `[content-review]` chain to pass)
- **T2 (Active/High)**: May run (draft freely; sending requires `[content-review]` chain to pass)
- **T3 (Medium)**: May run (draft and send with `[content-review]` chain)
- **T4 (Probationary)**: May draft emails only; sending (`--send` flag) BLOCKED
- **Operator**: Override any restriction
