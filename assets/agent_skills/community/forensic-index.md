---
name: forensic-index
description: >-
  Build and query a local SQLite index over captured session-forensic JSON
  artifacts (session_forensics reports and forensic_telemetry sidecars).
  Aggregates per-session metrics (messages, tool calls, errors, token cost,
  self-check flags) across sinks, deduplicates forensic/sidecar pairs into
  one row per session, and reports anomalies: high-error sessions, retry
  storms, credential exposure, destructive commands, non-zero exits. Use
  when asked to "index forensic reports", "find the worst sessions",
  "cross-session error analysis", "which sessions had credential leaks /
  destructive commands", or as the executable aggregation layer under
  cross-session-learnings.
version: 0.1.0
execution-mode: advisory
category: fleet-ops
status: candidate
providers:
  required: [python]
---

# Forensic Index

Aggregate captured forensic JSON into a queryable SQLite index, then answer
cross-session questions without re-parsing hundreds of files.

## When to use

- "Index the forensic reports" / "build the forensic index"
- "Which sessions had the most errors / retry storms / credential leaks?"
- "Cross-session analysis" or input to `cross-session-learnings`
- Fleet health rollup: per-agent session counts, error totals, ACU spend
- Before `forensic-recommendations`: find the sessions worth fixing

## Sinks

`scan` recursively ingests `*.json` under the default sinks (override with
`--sink PATH`, repeatable):

- `~/AppData/Roaming/devin/cli/forensic-archive` (devin session archive)
- `~/bin/forensic-capture/staging` (capture-pipeline output, incl. `delta/` syncs)
- `~/.agents/_state/forensics` (skill-emitted reports)

File classification: a JSON doc with `forensic_self_check` or a
`*-manifest-sidecar.json` name is a sidecar; a doc with `session_id` +
`analysis`/`detection`/`session` is a forensic report; anything else is
skipped. Malformed files are counted and skipped, never fatal.

## Commands

```bash
python scripts/forensic_index.py sinks                      # show sink status
python scripts/forensic_index.py scan [--db PATH]           # incremental index
python scripts/forensic_index.py report [--json]            # fleet rollup
python scripts/forensic_index.py query --agent devin --min-errors 10 [--json]
python scripts/forensic_index.py anomalies [--limit 50]     # worst sessions, exit 1 if any
python scripts/forensic_index.py session <id> [--json]      # one session, merged rows
```

`--db` defaults to `~/bin/forensic-capture/forensic_index.db`. Re-scanning is
incremental and idempotent (upsert by source path + mtime).

## Output format

- `report`: files indexed, unique sessions, sessions-with-findings,
  per-agent rollup, top-by-errors, flagged sessions (self-check hits)
- `anomalies`: ranked `agent:session_id errors=N flags=N tools=N title`
- `query`: matching session rows (agent, session_id, errors, tool_calls,
  flag_hits, timestamps); `--json` for machine-readable
- `session`: merged forensic + sidecar row for one session_id

The index stores metadata and counts only — no message bodies, transcripts,
or prompt text. Forensic JSON may contain sensitive paths/commands; the DB
is a metadata layer, not a transcript copy.

Columns include `prompt_tokens`/`completion_tokens`/`cached_tokens`/
`total_steps` (cost fields are unmetered upstream — token volume is the
cost proxy) and `unique_errors` (distinct error-snippet count — raw
`errors` counts are inflated by repeated prompt-template matches; trust
`unique_errors` for severity).

## Skill chains

- **Before**: `session-forensics` / `forensic-telemetry-sidecar` produce the
  artifacts; `forensic-capture` pipeline populates staging sinks.
- **After**: `cross-session-learnings` for pattern synthesis;
  `forensic-recommendations` for fixes; `bus-forensics` / `git-forensics`
  for corroborating evidence.

## Constraints

- Read-only over source JSON; writes only its own SQLite DB.
- Stdlib-only Python 3.10+; safe to run while capture is running
  (per-file upserts, no global lock).
- `anomalies` exits 1 when findings exist — usable as a CI/cron gate.
