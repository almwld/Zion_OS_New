---
name: forensic-telemetry-sidecar
description: >
  Emits and validates the machine-readable forensic telemetry sidecar (forensic_telemetry.json)
  per the session-forensics-sidecar.json schema. Provides schema validation, sidecar generation
  from session metadata, and automated forensic self-checks (tool calls, exceptions, subagents,
  exit codes, retry storms, credential exposure, destructive commands).
version: 0.3.0
execution-mode: advisory
status: experimental
status-note: >
  emit --report derives real sidecars from session_forensics.py report JSON
  (self-check counters derived from tool_calls/errors_found). emit
  --session-dir remains a template emitter for Gemini/Antigravity session
  dirs; AIP/bus/subagent arrays are empty because reports do not carry them.
tags:
  - forensics
  - schema
  - telemetry
  - sidecar
  - validation
  - json
category: fleet-ops
providers:
  required: [python]
  pip: [jsonschema]
---

# Forensic Telemetry Sidecar

Emits, validates, and consumes the **machine-readable forensic telemetry sidecar**
(`forensic_telemetry.json`) per the `session-forensics-sidecar.json` schema.
This sidecar is the canonical machine-readable companion to the human-readable
`session_forensic_manifest.md`.

## When to Use

- After session termination, to emit the canonical forensic sidecar
- Before forensic analysis, to validate sidecar conformance
- During automated audit pipelines, to run self-checks
- When cross-referencing session evidence with bus receipts and file mutations

## Schema: `session-forensics-sidecar.json` (v1)

```json
{
  "$schema": "https://json-schema.hummbl.io/v1/session-forensics-sidecar.json",
  "session_id": "string (UUID or agent-specific format)",
  "runtime": {
    "agent_identity": "gemini|devin|codex|claude|opencode|pi",
    "system_model": "string",
    "client": "string",
    "host_machine": "string",
    "working_directory": "string",
    "start_timestamp_utc": "ISO8601 UTC",
    "current_timestamp_utc": "ISO8601 UTC",
    "aip_probation_status": "COMPLIANT_RESEARCH_ONLY|COMPLIANT_FULL|PROBATIONARY|..."
  },
  "subagents_spawned": [
    {
      "role": "string",
      "type": "research|general|explore",
      "conversation_id": "string (UUID)",
      "transcript_path": "string (absolute path)",
      "domains_covered": ["string"]
    }
  ],
  "coordination_bus_receipts": [
    {
      "receipt_id": "string",
      "message_type": "SITREP|MILESTONE|STATUS|...",
      "sender": "string (agent identity)",
      "recipient": "string",
      "topic": "string",
      "transport": "HTTP|websocket|local"
    }
  ],
  "state_mutations": [
    {
      "file_path": "string (absolute)",
      "mutation_type": "CREATE|CREATE_OVERWRITE|DELETE",
      "governance_classification": "RESEARCH_DOCUMENT|AGENT_LOCAL_CONFIG|CORE_CODE|OPERATIONAL_STATE|...",
      "aip_scope_permitted": true
    }
  ],
  "evidence_assertions": [
    {
      "claim": "string",
      "evidence_file": "string",
      "evidence_commit": "string (git SHA)",
      "evidence_repo": "string (URL)",
      "verifiable": true
    }
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

## Self-Check Rules (Automated)

| Check | Pass Condition | Severity |
|-------|----------------|----------|
| `unhandled_exceptions == 0` | No uncaught exceptions in session | **CRITICAL** |
| `failed_subagents == 0` | All subagents completed successfully | **HIGH** |
| `non_zero_exit_codes == 0` | All shell commands exited 0 | **HIGH** |
| `retry_storms_detected == 0` | No tool call retry storms (>5 retries same tool) | **MEDIUM** |
| `credentials_exposed == 0` | No secrets in transcripts, commands, or outputs | **CRITICAL** |
| `destructive_commands == 0` | No `rm -rf`, `force-push`, `DROP`, `DELETE` on prod | **HIGH** |
| `all aip_scope_permitted == true` | Every state mutation has permitted AIP scope | **HIGH** |

## Execution Procedure

### Emit Sidecar (from session metadata)
1. Collect session identity, runtime metadata, timestamps
2. Index all spawned subagents with conversation IDs and transcript paths
3. Query coordination bus for session receipts
4. Extract state mutations from session transcript/tool calls
5. Pair evidence assertions with file/commit/repo references
6. Run forensic self-checks against transcript/tool calls
7. Emit `forensic_telemetry.json` to session brain directory

### Validate Sidecar
```bash
# Validate against schema
python -c "
import json, jsonschema
with open('forensic_telemetry.json') as f: data = json.load(f)
with open('session-forensics-sidecar.json') as f: schema = json.load(f)
jsonschema.validate(data, schema)
print('VALID')
"
```

### Run Self-Checks
```python
# Built-in self-check function
def run_self_checks(sidecar):
    checks = {
        "unhandled_exceptions": sidecar["forensic_self_check"]["unhandled_exceptions"] == 0,
        "failed_subagents": sidecar["forensic_self_check"]["failed_subagents"] == 0,
        "non_zero_exit_codes": sidecar["forensic_self_check"]["non_zero_exit_codes"] == 0,
        "retry_storms_detected": sidecar["forensic_self_check"]["retry_storms_detected"] == 0,
        "credentials_exposed": sidecar["forensic_self_check"]["credentials_exposed"] == 0,
        "destructive_commands": sidecar["forensic_self_check"]["destructive_commands"] == 0,
    }
    all_pass = all(checks.values())
    return all_pass, checks
```

## CLI Usage

```bash
# Derive a sidecar from a session_forensics.py report (pipeline path)
python forensic_telemetry.py emit --report <report.json> --output <sid>.forensic_telemetry.json [--machine <host>]

# Legacy template emitter (Gemini/Antigravity session dirs)
python forensic_telemetry.py emit --session-dir <dir> --output <file>
python forensic_telemetry.py extract --session-dir <dir> --output <file>

# Validate + self-check
python forensic_telemetry.py validate --file <sidecar.json>
python forensic_telemetry.py self-check --file <sidecar.json>
```

`emit --report` derives `forensic_self_check` counters from the report's
`tool_calls` and `analysis.errors_found`: non-zero exits (`Exit code: N`),
destructive commands (`rm -rf`, `Remove-Item -Recurse -Force`, force-push,
`DROP`/`TRUNCATE`, unqualified `DELETE FROM`, `format`/`dd`/`shutdown`),
credential patterns (key/token formats; **unique strings counted** — one key
printed 20x is one exposure; values are never copied into the sidecar),
retry storms (same call signature ≥5x with failure evidence — signature is a
sha1 of the full input, so distinct edits to one file do not collide;
iterative edits and polling without failures do not count), unhandled
exceptions (errors_found snippets matching traceback/fatal patterns), and
failed subagent calls. `state_mutations` is populated from file-write tool
calls (edit/write/create_file/apply_patch).

Legacy report shapes are handled: when `tool_name`/`input` are null (pre-0.4.2
extractions), the call is recovered from `initial.kind` + `initial.rawInput`
(devin ACP shape) before counters run.

Known triage-flag caveats: outputs that *display* scanner/redaction source
code match its own fixture patterns (counts flag for review, not verdicts);
`rg`/grep "no matches" exit-1 counts as a non-zero exit; legacy `kind:edit`
inputs store only `{file_path}` so a repeated identical recorded call +
failure is consistent with but not proof of a retry storm.

The capture scanner (`~/bin/forensic-capture/session_scanner.py`) runs this
automatically after each extraction — sidecars land next to reports as
`<session_id>.forensic_telemetry.json`.

## Output Location

- **Primary**: `.gemini/antigravity-cli/brain/{session_id}/forensic_telemetry.json`
- **Pipeline**: co-located with the forensic report (`<session_id>.forensic_telemetry.json`)
- **Schema**: `https://json-schema.hummbl.io/v1/session-forensics-sidecar.json`

## Integration with Session Lifecycle

| Phase | Action |
|-------|--------|
| Session start | Initialize empty sidecar structure |
| Subagent spawn | Append to `subagents_spawned` |
| Bus post | Append to `coordination_bus_receipts` |
| File mutation | Append to `state_mutations` |
| Evidence claim | Append to `evidence_assertions` |
| Session end | Run self-checks, emit final `forensic_telemetry.json` |

## AIP Scope Compliance

- Sidecar emission is an `AGENT_LOCAL_CONFIG` mutation (permitted)
- All file paths in sidecar must be within AIP-permitted scopes
- Sidecar must not contain credential values (only references)

## Related Skills

- `session-forensics-manifest` — produces human-readable manifest from sidecar
- `session-forensics` — extracts sidecar from terminated sessions
- `opencode-forensic-brief` — generates auditor briefing from sidecar

## Evidence Sources

- Schema: `https://json-schema.hummbl.io/v1/session-forensics-sidecar.json`
- Reference session: `b93f413b-0a68-480e-b623-7f90cba61eec` (Gemini/Antigravity CLI)
- Reference sidecar: `.gemini/antigravity-cli/brain/b93f413b-0a68-480e-b623-7f90cba61eec/forensic_telemetry.json`

## Skill Chains
- For schema lists opencode as a valid agent_identity -> `[cross-runtime-bridge]` (`python ~/bin/cross_runtime_bridge.py sessions`)
