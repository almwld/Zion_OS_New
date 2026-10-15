---
name: runbook-write
description: Generate operational runbook from service architecture and incident history
version: 0.1.0
execution-mode: advisory
argument-hint: "<service-or-topic> [--update]"
category: governance-compliance
status: candidate
---
# [runbook-write]

## When to Use
- Documenting operational procedures for a service or process
- After an incident: capture the resolution as a runbook
- Onboarding: create runbooks for common operations
- Before going offline: document what someone else needs to operate

## Execution

### Inputs
- **service-or-topic** (required): Service name or operational topic
- **--update**: Refresh existing runbook with current state

### Steps
1. Gather context for the service/topic:
   - Read service source code for architecture understanding
   - Check `playbooks/` for existing operational docs
   - Read recent bus messages mentioning the service
   - Check `docs/tasks/` for related task definitions
   - Review git log for recent fixes and incidents
2. Determine runbook type:
   - **Service**: startup, health check, troubleshooting, restart, scaling
   - **Incident**: detection, triage, fix, verification, postmortem template
   - **Process**: deployment, backup, migration, credential rotation
3. Generate all required sections (see below)
4. Use actual commands, not pseudocode -- every step must be copy-pasteable
5. Include verification after each action step
6. Write to `playbooks/<service-or-topic>.md`

### Required Sections (every runbook)
1. **Purpose**: One sentence -- what this runbook covers
2. **Prerequisites**: Tools, access, permissions, environment needed
3. **Steps**: Numbered with exact commands and expected output
4. **Verification**: How to confirm each step succeeded
5. **Rollback**: How to undo if something goes wrong
6. **Contacts**: Who to escalate to and how
7. **History**: Created date, last updated, related incidents

## Output Format

```
Runbook Write | configured messaging service
============================================================
Sources: services/signal_delivery.py, docs/tasks/signal-setup.md

## Generated Runbook Preview

# Messaging Service Operations

**Purpose:** Manage the messaging service daemon for message delivery.

**Prerequisites:**
- configured messaging service v0.13.24, Temurin JDK 21
- Port 8081 available on localhost

**Health Check:**
  curl -s http://127.0.0.1:8081/v1/about | python3 -m json.tool

**Restart:**
  1. pkill -f configured messaging service
  2. Verify: lsof -i :8081 (should be empty)
  3. configured messaging service daemon --http=127.0.0.1:8081 &
  4. Verify: curl -s http://127.0.0.1:8081/v1/about

**Rollback:** Check JDK version (java -version, must be 21)

**Contacts:** the owner (primary), team lead (escalation)

Written to: playbooks/configured messaging service.md (68 lines)
------------------------------------------------------------
Next: [health] (verify current service state)
```

## Skill Chains
- After an incident -> write runbook with `[runbook-write]`
- After `[runbook-write]` -> suggest `[readme-gen] --refresh` to link it
- Pair with `[api-docs]` for complete service documentation

## External References (Supplement)

- `anthropics/knowledge-work-plugins@runbook` — template structure and reusable procedural format.
- `sickn33/antigravity-awesome-skills@incident-runbook-templates` — practical incident workflow sections for enrichment and consistency.
