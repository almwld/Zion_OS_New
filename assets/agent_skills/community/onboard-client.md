---
name: onboard-client
description: Client onboarding — environment setup, access provisioning, kickoff agenda, deliverable expectations
version: 1.0.0
execution-mode: side_effecting
argument-hint: "<client-name> [--service assessment|advisory|managed] [--contact email]"
category: sales-marketing
status: candidate
---
# Onboard Client

Structured client onboarding for your organization governance consulting engagements. Creates the client directory, generates kickoff materials, and updates CRM.

## Arguments
- `<client-name>` — Client or organization name (required)
- `--service <type>` — Service tier: assessment, advisory, managed (default: assessment)
- `--contact <email>` — Primary contact email address

## Procedure

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=onboard-client] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Create Client Directory

```bash
CLIENT_DIR="PROJECTS/hummbl-production/clients/<client-name-slug>"
mkdir -p "$CLIENT_DIR"/{docs,deliverables,correspondence,evidence}
```

Create `$CLIENT_DIR/README.md` with:
- Client name, primary contact, engagement start date
- Service tier and scope summary
- Key dates (kickoff, milestones, close)

### 2. Generate SOW Stub

Create `$CLIENT_DIR/docs/SOW-DRAFT.md` from template:

```markdown
# Statement of Work: <Client Name>

## Engagement Details
- **Client:** <name>
- **Service:** <assessment|advisory|managed>
- **Start Date:** <today>
- **Duration:** <TBD>
- **Rate:** See BUSINESS.md

## Scope
1. <scope item 1>
2. <scope item 2>

## Deliverables
| # | Deliverable | Due | Status |
|---|-------------|-----|--------|
| 1 | Governance Assessment Report | Week 2 | NOT STARTED |
| 2 | Gap Analysis & Remediation Plan | Week 3 | NOT STARTED |
| 3 | Framework Crosswalk | Week 4 | NOT STARTED |

## Acceptance Criteria
- All deliverables reviewed by client stakeholder
- Assessment covers agreed-upon framework(s)
- Remediation plan includes effort estimates and priorities

## Payment Schedule
- 50% on engagement start
- 50% on final deliverable acceptance
```

### 3. Generate Kickoff Agenda

Create `$CLIENT_DIR/docs/KICKOFF-AGENDA.md`:

```markdown
# Kickoff Meeting Agenda: <Client Name>

**Date:** <TBD>
**Duration:** 60 minutes
**Attendees:** <client contact>, $USER_NAME (your organization)

## Agenda

### 1. Introductions (5 min)
- Roles and responsibilities
- Communication preferences (email, Slack, meetings)

### 2. Engagement Overview (10 min)
- Scope confirmation from SOW
- Timeline and milestones
- Deliverable format expectations

### 3. Current State Assessment (20 min)
- Existing governance frameworks in use
- Known compliance requirements (NIST, ISO, SOC 2, etc.)
- Current pain points and priorities
- Tools and systems in scope

### 4. Information Gathering Plan (15 min)
- Documents and access needed from client
- Interview schedule for key stakeholders
- Self-assessment questionnaire walkthrough

### 5. Next Steps & Action Items (10 min)
- Immediate action items (both sides)
- Next meeting date
- Emergency contact protocol
```

### 4. Draft Welcome Email

Create `$CLIENT_DIR/correspondence/welcome-email.md`:

```markdown
Subject: Welcome to your organization Governance — Kickoff Details

Hi <contact>,

Thank you for choosing your organization for your AI governance engagement. I'm looking
forward to working together.

**What to expect next:**

1. **Kickoff call** — I'll send a calendar invite for our kickoff meeting.
   Please have 60 minutes available in the next week.

2. **Pre-kickoff questionnaire** — I'll share a brief self-assessment to
   help me understand your current governance posture before we meet.

3. **Access setup** — If you'd like a shared workspace for deliverables,
   I can set up a shared Google Drive folder or use your preferred platform.

**What I'll need from you:**
- Confirmation of stakeholders who should attend the kickoff
- Any existing governance documentation (policies, procedures, risk registers)
- Compliance requirements driving this engagement (e.g., SOC 2, NIST, EU AI Act)

Please reply with any questions. Looking forward to getting started.

Best,
$USER_NAME
your organization | AI Governance & Assurance
$USER_EMAIL
```

### 5. Update CRM

Add client to CRM tracker:

```bash
# Add to Google Sheets CRM via [crm] skill
# Or manually append to local tracker
echo "<today>,<client-name>,<contact>,<service>,ONBOARDING,," >> PROJECTS/hummbl-production/clients/tracker.csv
```

### 6. Checklist Verification

Verify all artifacts were created:

```bash
ls -la "$CLIENT_DIR"/
ls -la "$CLIENT_DIR"/docs/
ls -la "$CLIENT_DIR"/correspondence/
```

## Output Format

```
Onboard Client | <client-name>

Client: <name>
Service: <assessment|advisory|managed>
Contact: <email>

Created:
  [x] Client directory: <path>
  [x] SOW draft: docs/SOW-DRAFT.md
  [x] Kickoff agenda: docs/KICKOFF-AGENDA.md
  [x] Welcome email: correspondence/welcome-email.md
  [x] CRM entry added

Immediate Actions:
  [ ] Review and customize SOW draft
  [ ] Send welcome email to <contact>
  [ ] Schedule kickoff meeting
  [ ] Share pre-kickoff questionnaire

Next action: Review SOW-DRAFT.md, then `[send-email]` to deliver welcome
```

## Safety Rules

- Never send the welcome email automatically -- always draft for review
- Never commit client names or emails to public repos
- Client directories go in `hummbl-production/` (private), never `hummbl-governance/`
- Rates and pricing reference BUSINESS.md but are not copied into client docs

## Skill Chains

### Mandatory

None — onboarding is a standard procedure with no destructive side effects beyond directory and CRM entry creation.

### Advisory

- After client onboarded → `[send-email]` to deliver welcome email
- After client onboarded → `[meeting-prep]` for kickoff meeting
- After SOW finalized → `[sow-generate]` for formal version
- After SOW finalized → `[invoice-generate]` for first invoice
- After kickoff completed → `[assessment-report]` to begin assessment
- After kickoff completed → `[engagement-tracker]` to track ongoing engagement

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Run with operator approval
- **T4 (Probationary)**: BLOCKED — access provisioning requires elevated trust
- **Operator**: Override any restriction
