---
name: session-forensics-manifest
description: >
  SUPERSEDED — merged into session-forensics skill v0.3.0. Use
  `session-forensics` with the --manifest flag instead. This skill is
  retained for reference only.
version: 0.1.0
status: superseded
superseded_by: session-forensics
superseded_in_version: 0.3.0
execution-mode: advisory
tags:
  - forensics
  - audit
  - governance
  - manifest
  - session
  - aip
category: fleet-ops
providers:
  required: [python]
---

# Session Forensics Manifest

Generates a comprehensive **forensic manifest** for terminated AI agent sessions.
The manifest serves as a durable audit trail documenting the session's activities,
state mutations, coordination bus transmissions, and governance compliance.

## When to Use

- After any session that performs state mutations, research, or multi-agent coordination
- When a session requires formal audit trail for downstream review
- Before handing off to another agent for forensic analysis
- When AIP scope compliance must be formally documented

## Manifest Structure

The manifest produces a Markdown document with these sections:

### 1. Session Identity & Metadata
- Session ID, agent identity, host machine, working directory
- Start/end timestamps, duration, AIP probation status

### 2. Chronological Timeline
- User prompts and agent milestones in sequence
- Phase transitions and decision points

### 3. Subagent Directory
- Subagent roles, conversation IDs, log URIs, domains covered

### 4. File Operations & State Changes
- CREATE, CREATE_OVERWRITE, DELETE actions
- File paths, descriptions, governance classification, AIP scope permitted

### 5. Coordination Bus Transmissions
- Bus hub endpoint, SITREP/MILESTONE receipt IDs
- Message types, senders, recipients, topics

### 6. Evidence Assertions
- Claims made during session
- Evidence file paths, commit hashes, repo URLs
- Verifiability status

### 7. Audit & Safety Verification
- AIP scope compliance
- Destructive operations check
- Credential hygiene check

## Machine-Readable Sidecar

Generates `forensic_telemetry.json` (schema: `session-forensics-sidecar.json`) with:
- Session metadata (agent, model, host, timestamps, AIP status)
- Subagents spawned (role, conversation_id, transcript_path, domains)
- Coordination bus receipts (receipt_id, message_type, sender, recipient, topic)
- State mutations (file_path, mutation_type, governance_classification, aip_scope_permitted)
- Evidence assertions (claim, evidence_file/evidence_commit/evidence_repo, verifiable)
- Forensic self-check (tool_calls, unhandled_exceptions, failed_subagents, non_zero_exit_codes, retry_storms, credentials_exposed, destructive_commands)

## Execution Procedure

1. **Collect session metadata**: agent identity, model, host, working directory, timestamps
2. **Build timeline**: Extract user prompts, agent milestones, phase transitions from transcript
3. **Index subagents**: For each spawned subagent, record role, conversation_id, transcript_path, domains
4. **Extract file operations**: From transcript/tool calls, identify all CREATE/UPDATE/DELETE actions with paths
5. **Extract bus transmissions**: Query coordination bus for receipts from this session
6. **Collect evidence assertions**: Pair claims with evidence files, commits, or repo URLs
6. **Run self-check**: Count tool calls, check for exceptions, failed subagents, non-zero exits, retry storms, credential exposure, destructive commands
7. **Generate manifest**: Write Markdown + JSON sidecar to session brain directory and research docs mirror

## Schema Reference

**Machine-readable sidecar** conforms to: `https://json-schema.hummbl.io/v1/session-forensics-sidecar.json`

```json
{
  "session_id": "string",
  "runtime": {
    "agent_identity": "gemini|devin|codex|claude|opencode|pi",
    "system_model": "string",
    "client": "string",
    "host_machine": "string",
    "working_directory": "string",
    "start_timestamp_utc": "ISO8601",
    "current_timestamp_utc": "ISO8601",
    "aip_probation_status": "COMPLIANT_RESEARCH_ONLY|..."
  },
  "subagents_spawned": [
    { "role": "string", "type": "research", "conversation_id": "uuid", "transcript_path": "string", "domains_covered": ["string"] }
  ],
  "coordination_bus_receipts": [
    { "receipt_id": "string", "message_type": "SITREP|MILESTONE|STATUS", "sender": "string", "recipient": "string", "topic": "string", "transport": "string" }
  ],
  "state_mutations": [
    { "file_path": "string", "mutation_type": "CREATE|CREATE_OVERWRITE|DELETE", "governance_classification": "RESEARCH_DOCUMENT|AGENT_LOCAL_CONFIG|...", "aip_scope_permitted": true }
  ],
  "evidence_assertions": [
    { "claim": "string", "evidence_file": "string", "verifiable": true }
  ],
  "forensic_self_check": {
    "total_tool_calls": "int",
    "unhandled_exceptions": "int",
    "failed_subagents": "int",
    "non_zero_exit_codes": "int",
    "retry_storms_detected": "int",
    "credentials_exposed": "int",
    "destructive_commands": "int"
  }
}
```

## Output Locations

- **Primary**: `.gemini/antigravity-cli/brain/{session_id}/session_forensic_manifest.md`
- **Mirror**: `hummbl_governance/docs/research/2026-08-16_session_forensics_manifest_{session_id}.md`
- **Sidecar**: `.gemini/antigravity-cli/brain/{session_id}/forensic_telemetry.json`

## AIP Scope Compliance

- All outputs confined to `hummbl_governance/docs/research/` and agent brain directories
- Zero unauthorized edits to core code or operational state
- Manifest itself is a research/governance document

## Related Skills

- `forensic-telemetry-sidecar` — for machine-readable sidecar schema
- `session-forensics` — for digital forensics extraction from terminated sessions
- `opencode-forensic-brief` — for downstream auditor briefing
- `reasoning-trace-hummbl` — for native HUMMBL reasoning trace format

## Evidence Sources

- Session `b93f413b-0a68-480e-b623-7f90cba61eec` (Gemini/Antigravity CLI)
- Forensic artifacts in `.gemini/antigravity-cli/brain/b93f413b-0a68-480e-b623-7f90cba61eec/`
- Coordination bus receipts: `033a94d968ed448089aa9a756b8e2ac7`, `26d0de4c15c642048af4c53c4c3a1997`

## Skill Chains
- For multi-agent coordination via the bridge session registry -> `[cross-runtime-bridge]` (`python ~/bin/cross_runtime_bridge.py sessions`)
