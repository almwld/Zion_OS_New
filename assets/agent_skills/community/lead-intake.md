---
name: lead-intake
description: Process new leads from Cal.com, Linktree, or manual entry into CRM and send acknowledgment
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[source] [name] [email] -- or processes from webhook data in $ARGUMENTS"
category: fleet-ops
status: candidate
---
# Lead Intake

Process a new lead from Cal.com bookings, Linktree form submissions, or manual entry. Creates a CRM contact row in Google Sheets and sends a professional acknowledgment email.

## Usage

```
[lead-intake] cal.com "Jane Smith" jane@example.com "Interested in platform architecture review"
[lead-intake] linktree "Alex Chen" alex@chen.io
[lead-intake] manual "Bob Lee" bob@acme.co "Referred by a team member, wants AI ops consulting"
```

## Arguments

- `$ARGUMENTS` is parsed as: `<source> "<name>" <email> ["notes"]`
- Source: `cal.com`, `linktree`, `manual`, or any freeform string
- If `$ARGUMENTS` is empty, ask the user for name, email, source, and optional notes

## Workflow

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=lead-intake] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### Step 1 -- Parse Lead Info

Extract from arguments:
- **name** (required)
- **email** (required)
- **source** (required: cal.com, linktree, manual, etc.)
- **notes** (optional)

### Step 2 -- Ingest Lead Record

#### Mode A: GitOps TSV Mode (Default & Fleet-Wide Standard)
On all fleet hosts (or whenever Google OAuth keys are absent in `~/.gmail-mcp/`), use the GitOps Lead Intake Engine in `household-income-ops`. This provides zero-cloud-dependency intake, automated privacy token minting (`Alias-<Prefix>-<NN>`), and instant coordination bus receipts:

```bash
python3 /work/active/household-income-ops/scripts/lead_intake.py add \
  --offer "Private Coaching Reset" \
  --source "$SOURCE" \
  --alias-prefix "Coach-Warm" \
  --notes "$NOTES"
```

Or for automated Cal.com webhook payloads:
```bash
python3 /work/active/household-income-ops/scripts/lead_intake.py ingest-cal \
  --payload-file /path/to/booking.json
```

#### Mode B: Google Sheets CRM (Optional Cloud Sync)
If `~/.gmail-mcp/gcp-oauth.keys.json` and credentials exist and the operator specifically requests Google Sheets CRM sync, append a row to the Consulting pipeline sheet:
- Name, Email, Source, Stage ("Lead"), Notes, Date Added (today), Last Interaction (today)

```bash
python3 << 'PYEOF'
import json, urllib.request, urllib.parse, datetime

KEYS_PATH = "$HOME/.gmail-mcp/gcp-oauth.keys.json"
CREDS_PATH = "$HOME/.gmail-mcp/credentials.json"

# CONFIGURE: Set your Google Sheets spreadsheet ID and range
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

def append_row(name, email, source, notes):
    token = get_token()
    today = datetime.date.today().isoformat()
    values = [[name, email, source, "Lead", notes or "", today, today]]
    payload = json.dumps({"values": values}).encode()
    url = (
        f"https://sheets.googleapis.com/v4/spreadsheets/{SPREADSHEET_ID}"
        f"/values/{urllib.parse.quote(RANGE)}:append"
        f"?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS"
    )
    req = urllib.request.Request(
        url, data=payload,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read())
        updated = result.get("updates", {}).get("updatedRange", "unknown")
        print(f"CRM_ADDED | range={updated} | name={name} | email={email} | source={source}")

append_row("$NAME", "$EMAIL", "$SOURCE", """$NOTES""")
PYEOF
```

### Step 3 -- Send Acknowledgment Email

Send a warm, professional email from $USER_EMAIL. The email should:
- Thank them for reaching out
- Mention you will follow up personally within 24 hours
- Include a Cal.com booking link for scheduling a call
- Be concise (under 200 words)

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

def send(to, name):
    token = get_token()
    subject = "Thanks for reaching out -- your organization"
    body = f"""Hi {name.split()[0]},

Thanks for reaching out. I received your inquiry and wanted to let you know I'll be reviewing it personally.

I'll follow up within 24 hours with more details on how I can help. In the meantime, if you'd like to schedule a call directly, feel free to pick a time that works for you:

https://cal.com/hummbl

Looking forward to connecting.

Best,
$USER_NAME
Your Company -- consulting signature
$USER_EMAIL"""

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
        print(f"EMAIL_SENT | to={to} | id={result['id']} | thread={result['threadId']}")

send("$EMAIL", "$NAME")
PYEOF
```

### Step 4 -- Post Bus Message

Post STATUS to the bus with the new lead summary.
```
Type: STATUS
To: all
Message: New lead: $NAME from $SOURCE
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### Step 5 -- Output Summary

Report in this format:

```
Lead Intake | $SOURCE

  Name:    $NAME
  Email:   $EMAIL
  Source:  $SOURCE
  Stage:   Lead
  Notes:   $NOTES

  CRM:     Row appended to Consulting pipeline
  Email:   Acknowledgment sent from $USER_EMAIL
  Bus:     STATUS posted

  Next action: Follow up within 24 hours (or run [follow-up] to check)
```

## Prerequisites

- OAuth credentials at `~/.gmail-mcp/gcp-oauth.keys.json`
- Refresh token at `~/.gmail-mcp/credentials.json`
- Google Sheets API enabled on the `hummbl` GCP project
- Gmail API enabled with send scope
- `$SPREADSHEET_ID` must be set to the actual CRM spreadsheet ID before first use

## Setup Note

Before first use, replace `$SPREADSHEET_ID` in the Step 2 script with the actual Google Sheets ID for the Consulting CRM. The sheet should have columns: Name, Email, Source, Stage, Notes, Date Added, Last Interaction.

## Error Handling

- `invalid_grant` -- refresh token expired. Re-auth via: `cd ~/.npm/_npx/952459504b2da320/node_modules/@gongrzhe/server-gmail-autoauth-mcp && node dist/index.js auth`
- `403 insufficient permissions` -- Sheets or Gmail API not enabled, or scopes missing
- If CRM append fails, still send the email and report the CRM error
- If email fails, still log to CRM and report the email error

## Skill Chains

### Mandatory

- `[content-review]` MUST pass for acknowledgment email — external communication requires content validation before sending

### Advisory

- `[follow-up]` — check whether the 24-hour follow-up window has been met
- `[mobile-bus]` — post lead status to coordination bus after CRM entry

## Authority

- **T1 (TRUSTED)**: May run with content-review for email
- **T2 (Active/High)**: May run with content-review for email
- **T3 (Medium)**: Operator approval + content-review
- **T4 (Probationary)**: BLOCKED (external communication)
- **Operator**: Override any restriction
