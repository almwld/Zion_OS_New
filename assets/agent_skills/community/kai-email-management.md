---
name: kai-email-management
description: AI Chief of Staff email management for Kai - autonomous email triage, draft response generation, and safe autonomous sending for routine communications. Progressive rollout from read-only to autonomous operations with human approval gates.
version: 1.0.0
execution-mode: advisory
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---

# kai-email-management

AI Chief of Staff email management for Kai - autonomous email triage, draft response generation, and safe autonomous sending for routine communications. Progressive rollout from read-only to autonomous operations with human approval gates.

## Backend Policy

- **Canonical on agent-node**: Codex Gmail connector.
- **Legacy optional fallback**: direct Gmail API helper under `skills/send-email/send-email-kai.py`, only when the operator explicitly maintains local `~/.gmail-mcp` OAuth credentials.
- Do not repair or recreate Google Cloud OAuth clients by default for Kai mail. If the connector works, use it.
- If the connector is unavailable, post `BLOCKED` or ask the operator before switching to local OAuth or another backend.

## When to Use
- Kai's scheduled 4-hour email triage and management cycles
- When human requests "Kai, handle my email" or similar
- For drafting responses to business communications
- When email patterns indicate need for Chief of Staff attention
- To maintain inbox hygiene and response SLAs

## Execution

### Phase 1: Read-Only Email Triage (Safe Starting Point)

1. **Fetch recent emails** using the Codex Gmail connector:
   - Search for unread messages from last 4 hours
   - Get message content and thread history
   - Extract sender, subject, body, attachments

2. **Classify by urgency** using P0-P3 system:
   - **P0**: Immediate human attention (financial/time-sensitive, client emergencies, security alerts)
   - **P1**: Same-day response expected (business inquiries, partner requests, team escalations)
   - **P2**: Response within 24-48 hours (routine communications, informational updates)
   - **P3**: Low priority/batch processing (newsletters, marketing, notifications)

3. **Assess sender trust level**:
   - **TRUSTED**: Known contacts with past positive interactions
   - **PROBATIONARY**: New contacts, unverified senders
   - **BLOCKED**: Known spam, malicious patterns

4. **Generate structured digest**:
   - Summary statistics (total, by category, by urgency)
   - P0/P1 items with full context and recommended actions
   - P2/P3 items summarized
   - Pattern insights (e.g., "3 similar partnership inquiries this week")

5. **Post to coordination bus**:
   - Message type: STATUS or SITREP
   - Include full triage results
   - Flag P0/P1 items for immediate human attention

6. **Log to cognitive ledger**:
   - Entry type: `discovery` for pattern insights
   - Entry type: `convention` for relationship mapping updates
   - Track triage accuracy and patterns over time

### Phase 2: Draft Response with Human Approval

1. **Trigger conditions**:
   - Human explicitly requests draft response
   - P0/P1 emails identified in triage
   - High-value opportunities detected
   - Complex situations requiring nuance

2. **Context gathering**:
   - Fetch full thread history via Gmail MCP
   - Check sender relationship from cognitive ledger
   - Review similar past responses
   - Identify key points to address
   - Determine appropriate tone

3. **Generate response options** (2-3 variants):
   - **Direct**: Concise, action-oriented
   - **Diplomatic**: Polished, relationship-focused
   - **Detailed**: Comprehensive, thorough
   - Include reasoning for each approach
   - Flag any assumptions made
   - Suggest follow-up actions

4. **Safety checks**:
   - Verify no confidential information leaked
   - Check tone appropriateness for relationship
   - Validate factual claims
   - Ensure no commitments beyond authority

5. **Present for human approval**:
   - Show original email context
   - Present draft options with reasoning
   - Highlight any risks/assumptions
   - Offer approval options: send/edit/revise/human handles/ignore

6. **Post to coordination bus**:
   - Message type: PROPOSAL for drafts awaiting approval
   - Include full context and options
   - Log final decision to cognitive ledger

### Phase 3: Autonomous Send for Low-Risk Categories

1. **Autonomous send criteria** (ROUTINE category only):
   - Sender is TRUSTED (past positive interactions)
   - Content is informational/confirmatory only
   - No financial/legal commitments
   - No sensitive information disclosure
   - Template-based or highly standardized

2. **Pre-flight safety checks**:
   - Content validation (no PII beyond necessary, no accidental commitments)
   - Context validation (sender relationship, authority boundaries, timing)
   - Final safeguards (Kai signature, BCC human, immediate bus logging)

3. **Use template library**:
   - Meeting confirmations
   - Acknowledgments ("Received, will review")
   - Schedule updates
   - Status updates on tracked items
   - Resource sharing (pre-approved)

4. **Execute autonomous send**:
   - Send via Codex Gmail connector
   - Add "Sent by Kai (AI Chief of Staff)" signature
   - BCC human for audit trail
   - Post STATUS to coordination bus
   - Log to cognitive ledger

5. **Rollback capability**:
   - If issues detected: send apology, notify human, post BLOCKED, log incident
   - Analyze root cause and update autonomous criteria
   - Add to blocked patterns

## Integration Points

### Coordination Bus Messages

**Triage Complete (STATUS/SITREP)**:
```
Email triage complete (last 4h):
- Total: 25 emails
- P0: 2 (client emergency, security alert)
- P1: 5 (business inquiries, partner requests)
- P2: 12 (routine communications)
- P3: 6 (newsletters, notifications)
Pattern: 3 similar partnership inquiries this week
```

**Draft Ready for Review (PROPOSAL)**:
```
Draft response ready for [sender] re: [subject]
Approach: Diplomatic with timeline commitment
Risk level: LOW
Requires human approval before send
```

**Autonomous Send Completed (STATUS)**:
```
Autonomous email sent to [trusted sender]
Type: Meeting confirmation
Template: standard_internal
BCC: human for audit trail
```

**Email Incident Detected (BLOCKED)**:
```
EMAIL SAFETY ISSUE: Potential misclassification
Email: [subject] from [sender]
Issue: Flagged as routine but contains commitment
Action: Halted, awaiting human review
```

### Cognitive Ledger Entries

**Relationship Mapping (convention)**:
```
Sender: [name] at [company]
Relationship level: TRUSTED
Communication style: [formal/casual/direct]
Typical response time: [hours]
Preferred topics: [topics]
Past interactions: [summary]
Effective approaches: [what works]
```

**Response Pattern Learning (lesson)**:
```
Scenario: [type of inquiry]
Approach that worked: [description]
Tone: [professional/friendly/direct]
Key elements: [what to include]
Avoid: [what to avoid]
Success metric: [positive outcome]
```

**Safety Incident Analysis (correction)**:
```
Incident: [description]
Root cause: [why it happened]
Protocol change: [what was updated]
Validation: [how to prevent recurrence]
Rollback tested: [yes/no]
```

## Safety Boundaries

### Never Autonomously Send
- Financial commitments (contracts, agreements, payment terms)
- Legal authority (legal agreements, NDAs, compliance statements)
- Sensitive information (confidential business info, security details)
- Relationship-critical (first-time VIP communications, crisis communications, HR matters)

### Always Require Human Approval
- P0 (emergency) emails
- New sender interactions (first 3 exchanges)
- Requests outside normal patterns
- Financial/legal implications
- Communications with board/investors
- Media/press inquiries

### Escalation Triggers
- **Immediate (BLOCKED)**: Security threats, legal/financial commitments, sensitive info exposure
- **Same-day (SITREP)**: High P1 volume (>5), new sender clusters, pattern anomalies
- **Weekly (STATUS)**: Volume/efficiency review, autonomous send accuracy, relationship updates

## Gmail Connector Tools Used

**Phase 1 (Triage)**:
- `gmail_search` - Find unread messages
- `gmail_get_message` - Fetch content
- `gmail_list_threads` - Thread context
- `gmail_get_thread` - Full conversation history

**Phase 2 (Drafting)**:
- `gmail_get_thread` - Full context for response
- `gmail_create_draft` - Create draft for human review
- `gmail_send` - Send approved response

**Phase 3 (Autonomous)**:
- `gmail_send` - Send autonomous responses
- `gmail_create_label` - Organize sent items
- `gmail_modify_thread` - Add labels/organize

## Output Format

### Triage Digest
```
Kai Email Triage | [timestamp]

## Summary
- Total emails: N
- P0: N (list)
- P1: N (list)
- P2: N (summary)
- P3: N (summary)

## Immediate Attention Required
[P0/P1 items with full context and recommended actions]

## Patterns & Insights
[Notable patterns, clusters, opportunities]

## Recommended Actions
[Prioritized action items for human]
```

### Draft Response
```
Email Response Draft | [sender] | [subject]

## Original Email
[Context snippet]

## Response Options
1. [Option 1 - approach description]
   [Draft text]
   Reasoning: [why this approach]
   Risks: [any concerns]

2. [Option 2 - approach description]
   [Draft text]
   Reasoning: [why this approach]
   Risks: [any concerns]

## Kai's Recommendation
[Recommended option with rationale]

## Safety Checks
[PASS] No confidential information
[PASS] Tone appropriate for relationship
[PASS] No commitments beyond authority
[PASS] Factual claims validated
```

### Autonomous Send Log
```
Autonomous Email Sent | [timestamp]

To: [recipient]
Subject: [subject]
Type: [meeting confirmation/acknowledgment/status update]
Template: [template used]
Risk assessment: PASSED all safety checks
BCC: [human]
Bus logged: STATUS
Ledger logged: lesson
```

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| Email triage complete | `[bus]` to post STATUS to coordination fleet |
| Draft response ready | `[bus]` to post PROPOSAL for human review |
| Pattern detected | `[ledger]` to log relationship mapping |
| Safety incident | `[bus]` to post BLOCKED and notify human |
| Learning opportunity | `[ledger]` to log response patterns |
| Cross-agent context needed | `[bus]` to coordinate with Codex/Gemini/Apex |

## Implementation Notes

- **Progressive rollout**: Start with Phase 1 only, human-test thoroughly before Phase 2, then Phase 3
- **Human approval interface**: Design based on user preference (CLI, web, or integration with existing tools)
- **Template library**: Build from actual email patterns, refine based on human feedback
- **Relationship mapping**: Initialize from existing email history, refine over time
- **Safety metrics**: Track intervention rates, rollback rates, accuracy metrics
- **Kill switch**: Implement immediate halt capability for safety incidents
