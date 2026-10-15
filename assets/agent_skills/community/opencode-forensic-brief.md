---
name: opencode-forensic-brief
description: >
  Generates a concise forensic briefing for OpenCode (or any downstream auditor)
  from a completed session's forensic artifacts. Produces a navigation map, key inquiry
  vectors with verified assertions, high-leverage verification commands, and state hand-off summary.
version: 0.1.0
execution-mode: advisory
tags:
  - forensics
  - audit
  - opencode
  - briefing
  - handoff
category: fleet-ops
status: candidate
providers:
  required: [python]
---

# OpenCode Forensic Briefing

Generates a concise **forensic briefing** for OpenCode (or any downstream auditor)
from a completed session's forensic artifacts. Provides immediate orientation,
key verification vectors, and runnable verification commands.

## When to Use

- Handing off a completed session to OpenCode for digital forensics
- Providing a quick orientation for any auditor reviewing session integrity
- Generating a state hand-off summary for multi-agent continuity

## Briefing Structure

### 1. Quick Navigation Map
Direct entry paths for forensic auditor:
- Artifact directory root
- Machine-readable sidecar (`forensic_telemetry.json`)
- Native reasoning trace (`session_reasoning_trace.json`)
- Human-readable manifest (`session_forensic_manifest.md`)
- Compact transcript (`transcript.jsonl`)
- Full transcript (`transcript_full.jsonl`)

### 2. Key Inquiry Vectors & Verified Assertions

| Vector | Finding / Status | Evidence Pointer |
|--------|------------------|------------------|
| **AIP Scope Compliance** | 100% Compliant / Non-compliant | `forensic_telemetry.json` → `state_mutations[].aip_scope_permitted` |
| **Claim vs Action Integrity** | Zero Gaps / Gaps Found | Research doc vs. SITREP vs. artifacts |
| **Subagent Concurrency** | N Subagents Dispatched & Completed / Failures | Subagent UUIDs + transcript paths |
| **ADR/Governance Detection** | Detected / Missed | Manifest evidence assertions |
| **Tool Execution Hygiene** | Zero Silent Failures / Silent Failures Found | `transcript_full.jsonl` + self-check |

### 3. High-Leverage Verification Commands

Runnable commands for immediate verification:

```bash
# 1. Validate JSON schema of forensic sidecar
python -c "
import json
data = json.load(open(r'PATH/forensic_telemetry.json'))
print('Subagents:', len(data['subagents_spawned']), '| Bus Receipts:', len(data['coordination_bus_receipts']))
"

# 2. Ingest ReasoningTrace using hummbl data structures
python -c "
import json
trace = json.load(open(r'PATH/session_reasoning_trace.json'))
print('Topology:', trace['topology'], '| Total Steps:', len(trace['steps']), '| Outcome:', trace['outcome'])
"

# 3. Check coordination bus log integrity on live hub
bus-global.py tail 10

# 4. Verify schema conformance
python -c "
import json, jsonschema
with open('forensic_telemetry.json') as f: data = json.load(f)
with open('session-forensics-sidecar.json') as f: schema = json.load(f)
jsonschema.validate(data, schema)
print('SCHEMA VALID')
"

# 5. Run forensic self-check
python -c "
import json
data = json.load(open(r'PATH/forensic_telemetry.json'))
checks = data['forensic_self_check']
all_pass = all(v == 0 for k, v in checks.items() if k != 'total_tool_calls')
print('Self-check:', 'PASS' if all_pass else 'FAIL', checks)
"
```

### 4. State Hand-off Summary

One-paragraph summary covering:
- Phase achieved and outcome
- Key architectures/formalisms established
- Durable configurations locked in
- Governance discoveries made
- Audit trail completeness

## Execution Procedure

1. **Load forensic artifacts**: Read `forensic_telemetry.json`, `session_reasoning_trace.json`, `session_forensic_manifest.md`
2. **Extract key vectors**: AIP compliance, claim/action integrity, subagent status, governance detection, tool hygiene
3. **Generate verification commands**: Produce runnable commands for immediate auditor use
4. **Synthesize hand-off**: One-paragraph state summary
5. **Emit briefing**: Write `OPENCODE_FORENSIC_BRIEF.md` to session brain directory

## Output Location

- **Primary**: `.gemini/antigravity-cli/brain/{session_id}/OPENCODE_FORENSIC_BRIEF.md`

## AIP Scope Compliance

- Briefing generation is `AGENT_LOCAL_CONFIG` (permitted)
- No credential exposure
- Confined to session brain directory

## Related Skills

- `session-forensics-manifest` — produces manifest consumed by briefing
- `forensic-telemetry-sidecar` — provides machine-readable sidecar consumed by briefing
- `reasoning-trace-hummbl` — provides reasoning trace consumed by briefing
- `session-forensics` — extracts artifacts for OpenCode consumption

## Evidence Sources

- Reference briefing: `OPENCODE_FORENSIC_BRIEF.md` from session `b93f413b-0a68-480e-b623-7f90cba61eec`
- Source artifacts: `forensic_telemetry.json`, `session_reasoning_trace.json`, `session_forensic_manifest.md`

## Skill Chains
- For hand off OpenCode session artifacts to downstream auditors -> `[cross-runtime-bridge]` (`python ~/bin/cross_runtime_bridge.py sessions`)
