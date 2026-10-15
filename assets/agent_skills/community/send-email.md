---
name: send-email
description: Send email through the Codex Gmail connector by default; legacy direct Gmail API helper remains optional for locally managed OAuth.
version: 0.3.0
execution-mode: side_effecting
argument-hint: "<to> <subject> [body or 'stdin'] [--kai] [--bcc] [--bus] [--ledger] [--thread-id ID]"
category: fleet-ops
status: candidate
providers:
  required: [python]
---
# Send Email

> **⚠️ MXRoute limitation (workstation, 2026-07-31):** This skill is Gmail-backed
> and does **not** work for `@hummbl.io` addresses (hosted on MXRoute).
> Both backends are currently down on agent-node (no Codex Gmail MCP server,
> no `~/.gmail-mcp/` OAuth credentials). For hummbl.io mail, use
> `$env:USERPROFILE\bin\send-mxroute-smtp.py` (SMTP) and
> `$env:USERPROFILE\bin\imap-check.py` (IMAP read). See `AGENTS.md` →
> "MXRoute Email (hummbl.io) Tooling" for server config and 1Password
> item IDs. This skill remains valid for Gmail-addressed mail when the
> backends are restored.

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=send-email] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Send email through the Codex Gmail connector by default. The legacy direct Gmail API helper remains available only for environments that intentionally maintain `~/.gmail-mcp` OAuth credentials.

## Backend Policy

- **Canonical on agent-node**: Codex Gmail connector.
- **Legacy optional fallback**: `send-email-kai.py` direct Gmail API helper using local OAuth files.
- Do not recreate Google Cloud OAuth clients unless the operator explicitly chooses the direct-helper fallback.
- If the connector is available, prefer it for Kai email send/read/archive/label workflows.

## Usage

### Standard Usage
```
[send-email] team-lead@danmatha.com "Subject line" "Body text here"
[send-email] $USER_EMAIL "Test" "Quick test email"
```

### Kai Integration
```
[send-email] partner@techcorp.com "Partnership discussion" "Response text" --kai --bcc --bus --ledger
[send-email] client@acme.com "Server status" "Update" --kai --bcc --bus --ledger --thread-id 19d081820a9433b0
```

### Kai Flags
- `--kai`: Add Kai signature to email
- `--bcc`: BCC human for audit trail
- `--bus`: Log to coordination bus
- `--ledger`: Log to cognitive ledger
- `--thread-id ID`: Reply to specific thread

## Shortcuts

- `dan` → dan@danmatha.com
- `owner` or `self` → $USER_EMAIL
- `org` or `research` → $RESEARCH_EMAIL

## Implementation

### Kai-Enhanced Legacy Helper
The dedicated Kai-enhanced script is a direct Gmail API fallback. Use it only when local OAuth is intentionally maintained:

```bash
python ~/.agents/skills/send-email/send-email-kai.py <to> <subject> <body> [--kai] [--bcc] [--bus] [--ledger] [--thread-id ID]
```

**Kai Integration Features**:
- `--kai`: Adds Kai signature with timestamp and confidence score
- `--bcc`: BCCs human operator for audit trail
- `--bus`: Logs to coordination bus as STATUS message
- `--ledger`: Logs to cognitive ledger for learning
- `--thread-id`: Replies to specific Gmail thread

**Example Kai Workflow**:
```bash
# Send with full Kai integration
python ~/.agents/skills/send-email/send-email-kai.py \
  partner@techcorp.com \
  "Partnership discussion" \
  "Thank you for reaching out. I'd like to discuss this further." \
  --kai --bcc --bus --ledger

# Reply to thread with Kai integration
python ~/.agents/skills/send-email/send-email-kai.py \
  client@acme.com \
  "Server status update" \
  "The issue has been resolved and services are back online." \
  --kai --bcc --bus --ledger --thread-id 19d081820a9433b0
```

## Kai Integration Details

### Signature Format
Kai signature includes:
- Timestamp of send
- Confidence score (default 95%)
- Clear attribution to Kai

Example:
```
---
Sent by Kai (AI Chief of Staff)
📅 2026-06-10 17:30
🎯 Confidence: 95%
```

### Audit Trail
When `--bcc` is enabled:
- Human operator receives BCC copy
- Full email content preserved
- Thread context maintained
- Send confirmation logged

### Bus Integration
When `--bus` is enabled:
- Posts STATUS message to coordination bus
- Includes recipient, subject, Gmail ID, thread ID
- Fleet-wide visibility of email sends
- Audit trail for compliance

### Ledger Integration
When `--ledger` is enabled:
- Logs to cognitive ledger for learning
- Captures send metadata
- Enables effectiveness tracking
- Supports pattern recognition

### Thread Context
When `--thread-id` is provided:
- Replies to existing Gmail thread
- Maintains conversation context
- Preserves thread history
- Improves response relevance

## Testing Kai Integration

Test the Kai-enhanced script:

```bash
# Test with Kai signature only
python ~/.agents/skills/send-email/send-email-kai.py \
  owner "Kai test" "Testing Kai signature" --kai

# Test with full Kai integration
python ~/.agents/skills/send-email/send-email-kai.py \
  owner "Kai test" "Testing full Kai integration" \
  --kai --bcc --bus --ledger
```

## Arguments

- `$ARGUMENTS` is parsed as: `<to> "<subject>" "<body>" [flags]`
- If no body provided, Claude generates appropriate content based on context
- If `$ARGUMENTS` is empty, ask the user for recipient, subject, and body

## Reply to Thread

To reply to an existing thread (e.g., the team lead brief thread), add `--thread-id` flag:
```bash
python ~/.agents/skills/send-email/send-email-kai.py \
  recipient "Subject" "Body" \
  --thread-id 19d081820a9433b0
```

## Known Thread IDs

- team lead founder briefs: `19d081820a9433b0`
- the owner self-test: `19d081ab1305dd0a`
- your organization Research comms: `19d081d191a27500`

## Prerequisites

For canonical connector-backed sending:
- Gmail connector enabled in Codex
- Authenticated account connected

For the legacy direct Gmail API helper only:
- OAuth credentials at `~/.gmail-mcp/gcp-oauth.keys.json`
- Refresh token at `~/.gmail-mcp/credentials.json`
- GCP OAuth consent screen published (permanent refresh tokens)
- Gmail API enabled on the `org` GCP project

## Error Handling

- `invalid_grant` → refresh token expired. The preflight in `get_token()` aborts with `exit 2` and prints the platform-correct re-auth command:
  - **Workstation / Windows**: `cd $env:USERPROFILE\AppData\Local\npm-cache\_npx\952459504b2da320\node_modules\@gongrzhe\server-gmail-autoauth-mcp && node dist/index.js auth`
  - **MBP / Linux**: `cd ~/.npm/_npx/952459504b2da320/node_modules/@gongrzhe/server-gmail-autoauth-mcp && node dist/index.js auth`
- `deleted_client` / `Error 401: deleted_client` -> the OAuth client referenced by `~/.gmail-mcp/gcp-oauth.keys.json` was deleted in Google Cloud. Re-auth cannot fix this by itself. Default response: use the Codex Gmail connector. Only replace `gcp-oauth.keys.json` with a new OAuth Desktop client if the operator explicitly wants the legacy direct helper restored.
- `403 insufficient permissions` → Gmail API not enabled or scopes missing

## Skill Chains

### Mandatory (MUST pass before send)

- **`[content-review]`** MUST pass for all outbound email content. No exception.
  This prevents sending unreviewed, inaccurate, or non-compliant content externally.

### Advisory

- **Before send**: `[kai-email-management]` (draft response with approval)
- **After send**: `[bus]` (STATUS message), `[ledger]` (decision entry)
- **For sequences**: `[email-sequence]` (generate sequence), then send-email for each email

## Authority

- **T1 (TRUSTED)**: May send without pre-approval
- **T2 (Active/High)**: May send with `[content-review]` passed
- **T3 (Medium)**: MUST get operator approval AND `[content-review]` passed
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
- **Operator**: Override any restriction
