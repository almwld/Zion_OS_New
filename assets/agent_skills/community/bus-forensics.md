---
name: bus-forensics
description: >-
  Forensically analyze the coordination bus — reconstruct event timelines,
  trace response chains and consensus gates, detect anomalies (duplicates,
  protocol violations, silence gaps, incomplete closes), map coordination
  flow, and produce a structured forensic report. Supports time-window,
  sender, type, and pattern filtering, plus thread tracing by lane,
  proposal_id, hypothesis, PR number, or session ID. Use this skill when the
  user asks to audit, analyze, investigate, or forensically examine bus
  activity — "what happened on the bus?", "analyze bus traffic", "bus
  forensics", "trace this proposal on the bus", "find anomalies in the bus",
  "who's talking to whom on the bus?", or "bus deep scan / full analysis".
version: 0.1.0
execution-mode: advisory
category: fleet-ops
status: candidate
providers:
  required: [python]
  optional: [eval-spec(md-scored)]
---

# Bus Forensics

Forensically analyze the coordination bus. Reconstruct what happened across
agents, trace response chains and consensus gates, detect anomalies, and
produce a structured forensic report.

## When to use

- "Audit/analyze/investigate the bus" or "bus forensics"
- "What happened on the bus in the last N hours?"
- "Trace this proposal/lane/PR on the bus"
- "Find anomalies in bus traffic"
- "Who's talking to whom on the bus?"
- "Bus deep scan" / "full analysis"
- Post-incident bus audit (what did agents communicate during an event?)
- Coordination failure investigation (why didn't agent X respond to agent Y?)
- Consensus gate forensic (what happened with proposal Z?)
- Session lifecycle audit (were sessions properly closed?)
- Health daemon pattern analysis (are daemons firing at expected intervals?)

## How it works

This skill uses a hybrid approach:

1. **`scripts/bus_forensics.py`** — a stdlib-only Python script that fetches
   bus entries (via `bus-global.py` bridge or local mirror), parses the TSV
   format with JSON-wrapped message handling, and runs 12 automated analysis
   modules: overview, sender activity, type distribution, timeline, response
   chains, anomaly detection, consensus gates, session lifecycle, coordination
   flow, intel type extraction, host provenance, and health daemon patterns.

2. **This SKILL.md** — guides you through interpreting the extracted data and
   producing a human-readable forensic report.

## Step 1: Run the extraction script

```bash
# Default: last 200 entries, full analysis
python <skill-dir>/scripts/bus_forensics.py

# Time window: last 24 hours
python <skill-dir>/scripts/bus_forensics.py --window 24h

# Specific count
python <skill-dir>/scripts/bus_forensics.py --count 500

# Time range
python <skill-dir>/scripts/bus_forensics.py --from 2026-08-10T20:00Z --to 2026-08-11T01:00Z

# Filter by sender
python <skill-dir>/scripts/bus_forensics.py --agent devin

# Filter by message type
python <skill-dir>/scripts/bus_forensics.py --type PROPOSAL

# Search for a pattern
python <skill-dir>/scripts/bus_forensics.py --search "OQ1"

# Trace a correlation tag (lane, proposal_id, PR number, session ID)
python <skill-dir>/scripts/bus_forensics.py --trace "lane=ops/devin"
python <skill-dir>/scripts/bus_forensics.py --trace "psi-propose-8ac33f87e60a"
python <skill-dir>/scripts/bus_forensics.py --trace "PR #26"

# Consensus gate focus
python <skill-dir>/scripts/bus_forensics.py --consensus

# Session lifecycle focus
python <skill-dir>/scripts/bus_forensics.py --lifecycle

# Full JSON output for detailed analysis
python <skill-dir>/scripts/bus_forensics.py --json

# Save full JSON to a file for large analyses
python <skill-dir>/scripts/bus_forensics.py --out forensic-data.json --full

# List active agents in the window
python <skill-dir>/scripts/bus_forensics.py --list-agents

# Read from local mirror only (skip bridge, faster but may be stale)
python <skill-dir>/scripts/bus_forensics.py --mirror

# Combine filters
python <skill-dir>/scripts/bus_forensics.py --window 6h --agent devin --type PROPOSAL --json
```

The script auto-detects the bus data source:
- **Primary**: `bus-global.py tail N` (HTTP bridge to canonical hub)
- **Fallback**: local mirror TSV at `~/.cache/bus/messages.tsv`
- **Force mirror**: `--mirror` flag skips bridge, reads mirror directly

## Step 2: Read the script output

The script produces a structured data package with these analysis modules:

- **`overview`** — time range, entry count, unique senders/recipients/types
- **`sender_activity`** — per-sender counts, type breakdown, first/last post, hosts
- **`type_distribution`** — message type counts, percentages, time spans
- **`timeline`** — key events (MILESTONE, PROPOSAL, DECISION, BLOCKED, HANDOFF, SKILL_INVOKE)
- **`response_chains`** — PROPOSAL→REVIEW/ACK/BLOCKED, REVIEW request→response,
  HANDOFF→SESSION_START, end-session→HANDOFF (INCOMPLETE_CLOSE detection)
- **`anomalies`** — duplicate entries, protocol violations, silence gaps,
  contested gates, BLOCKED messages, stale bus detection
- **`consensus_gates`** — proposals, reviews, verdicts, quorum status per proposal_id
- **`session_lifecycle`** — SKILL_INVOKE→SESSION_START→HANDOFF→end-session chains
- **`coordination_flow`** — who talks to whom, silent recipients, network edges
- **`intel_types`** — intel_type= tag extraction and counting
- **`host_provenance`** — host= and machine= tag distribution
- **`health_daemons`** — periodic poll pattern detection and interval estimation

For large analyses, use `--full` to avoid content truncation.

## Step 3: Produce the forensic report

After reading the extracted data, produce a structured report. The report
should help the reader understand what happened across the fleet, whether
coordination worked, where it broke down, and whether anything looks suspicious.

### Report template

```markdown
# Bus Forensics Report: <time range or filter description>

## Overview
- **Time range**: <earliest> to <latest> (<duration>)
- **Entries**: <count>
- **Senders**: <list with counts>
- **Types**: <distribution>
- **Data source**: <bridge/mirror>

## Timeline
<Chronological summary of key events — proposals, milestones, decisions,
blocked items, handoffs, skill invokes. Group by phase or theme if the
window has natural phases.>

## Sender Analysis
<Who posted, how much, what types. Who is dominant? Who is silent?
Are there agents that only receive but never send?>

## Response Chains
<Trace proposals to their responses. Which proposals got reviewed?
Which are still unanswered? Were HANDOFFs properly followed by SESSION_STARTs?
Any INCOMPLETE_CLOSE detections?>

## Consensus Gates
<For each proposal_id: what was proposed, who reviewed, what were the
verdicts, is quorum met, is it contested or blocked?>

## Anomalies
<Each anomaly found, with context:
- Duplicate entries (same timestamp + sender + message)
- Protocol violations (missing host= tag, etc.)
- Silence gaps (>1h with no bus activity)
- Contested consensus gates
- BLOCKED messages
- Stale bus (>72h gap)>

## Coordination Flow
<Who talks to whom. Network density. Are there agents that receive messages
but never respond? Are there broadcast-only agents that post to "all" but
never engage with specific recipients?>

## Health Daemon Patterns
<Periodic poll patterns: PROCESS_WATCHDOG, BRIDGE_HEALTH, TAILSCALE_HEALTH,
fleet-watch-daemon, ARCANA-PSI cycles. Are they firing at expected intervals?
Any gaps or bursts?>

## Session Lifecycle
<For each session: was it properly opened (SKILL_INVOKE + SESSION_START)
and closed (end-session + HANDOFF)? Any incomplete closes? Any sessions
that started but never closed?>

## Behavioral Observations
<Patterns the human should know about:
- Did agents follow bus protocol (host= tags, SKILL_INVOKE before stateful actions)?
- Were there coordination failures (unanswered reviews, missing handoffs)?
- Did any agent dominate traffic disproportionately?
- Were there signs of malfunction (duplicate posts, garbled messages, retry storms)?
- Were health daemons stable or were there gaps?
- Were there security concerns (credentials in messages, unexpected commands)?>

## Conclusion
<One-paragraph summary: what happened during this window, whether
coordination was healthy, and any recommendations for the operator
(investigate specific anomalies, adjust daemon intervals, follow up on
unanswered items, etc.)>
```

## Interpretation guidance

### Reading between the lines

The raw data tells you *what* happened. Your job is to also assess *why* and
*whether it was right*. Look for:

- **Claim vs. response gaps**: An agent posts a PROPOSAL or REVIEW request
  but no response ever appears — the request was ignored, missed, or the
  recipient agent was offline.
- **Retry storms**: The same message posted multiple times in quick succession
  — a daemon is malfunctioning or a bridge is double-firing.
- **Silent agents**: An agent appears as a recipient but never sends — it may
  be offline, unconfigured, or intentionally read-only.
- **Traffic imbalance**: One agent produces >80% of traffic — the bus is
  not being used for coordination, just for one agent's logging.
- **Protocol drift**: Messages missing `host=` tags, SKILL_INVOKE not posted
  before stateful actions, non-UTC timestamps.
- **Stale bus**: >72h gap with no entries — the bus went silent while work
  may have continued via direct git commits or other channels.
- **Contested consensus**: A proposal has both PASS and FAIL verdicts —
  operator review is required per ADR-GOV-008.

### Security considerations

When reviewing bus messages, pay attention to:
- Credentials or tokens in message bodies (bus is append-only and durable)
- Commands that exfiltrate data (scp, curl to external endpoints in messages)
- File paths that reveal sensitive directory structures
- Agent identity spoofing (sender field doesn't match in-band host= tag)

Report security concerns prominently in the report, but do not reproduce
credential values — reference them by location ("a token was visible in a
message at timestamp X") rather than including the actual value.

### Cross-agent context

If a bus entry references a specific agent session (e.g., a HANDOFF mentions
a session ID), the `session-forensics` skill can be run with that session ID
to pull the session's internal data for comparison. This enables cross-
referencing what an agent *said on the bus* vs. what it *did in its session*.

### Thread tracing

Use `--trace` to follow a specific tag or pattern through the bus:
- `--trace "lane=ops/devin/fleet-git-hygiene"` — follow a work lane
- `--trace "psi-propose-8ac33f87e60a"` — follow a consensus proposal
- `--trace "PR #26"` — follow a pull request
- `--trace "ADR-GOV-008"` — follow a governance decision
- `--trace "hypothesis=df664994c380"` — follow a research hypothesis

The trace filter is case-insensitive substring matching on both the inner
message and the raw TSV line, so it catches both plain-text and JSON-wrapped
messages.

## Limitations

- **Bridge dependency**: The script relies on `bus-global.py` for bridge
  access. If the bridge is down and the mirror is stale, analysis will use
  stale data. Check the `fetch_info` field in output to verify the source.
- **Mirror staleness**: The local mirror may lag the canonical hub by hours
  or days. The bridge is always preferred for live data.
- **JSON-wrapped messages**: Some messages are wrapped in
  `{"c":"...","host":"...","n":"...","s":"..."}` by the bridge. The script
  unwraps these, but the bridge host may differ from the true origin host
  (which is inside the `c` field).
- **Truncation**: Without `--full`, messages are truncated to 300 characters
  in JSON output. Use `--full` for complete data.
- **Large windows**: Fetching >1000 entries via the bridge may be slow.
  Use `--mirror` for faster reads of large datasets (at the cost of freshness).
- **Consensus gate matching**: Proposal-to-review matching relies on
  `proposal_id` fields in JSON payloads. Plain-text proposals without
  structured IDs may not be tracked.
- **Session lifecycle**: Session ID extraction depends on `[session=...]` tags
  in SKILL_INVOKE messages. Older posts without this tag will show as
  "unknown" session.

## Skill Chains

### Mandatory

- None — bus-forensics is a read-only analysis tool.

### Advisory

- **After bus-forensics**: `[session-forensics]` (to drill into a specific
  session referenced in the bus), `[sitrep]` (for current-state summary),
- **Before bus-forensics**: `[bus]` (to post a SKILL_INVOKE or check status),
  `[start-session]` (for session-scoped context)

## Authority

- **T1 (TRUSTED)**: Run without restriction
- **T2 (Active/High)**: Run without restriction (read-only forensic tool)
- **T3 (Medium)**: Run without restriction (read-only forensic tool)
- **T4 (Probationary)**: Run (read-only — no destructive actions)
- **Operator**: Override any restriction

## Constraints

- READ-ONLY — never writes to the bus, never modifies any file
- No side effects beyond subprocess call to `bus-global.py tail`
- All analysis is local to the script process
