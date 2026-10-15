---
name: session-replay
description: Replay and summarize what happened in a previous session from git log, bus messages, and ledger entries
version: 0.1.0
execution-mode: advisory
argument-hint: "[--session ID] [--since DATE] [--format summary|timeline]"
category: fleet-ops
status: candidate
---
# Session Replay

Reconstructs a previous work session by correlating git commits, coordination bus messages, and cognition ledger entries within a time window. Produces either a concise summary or a chronological timeline showing what was done, by whom, and what changed.

## When to Use
- Returning after a break and need to remember what happened last session
- Auditing what a specific agent did during a session
- Building context before continuing interrupted work
- Generating a session report for handoff or retrospective

## Execution
1. Parse `$ARGUMENTS` for session ID, date range, or format preference. Default to last 24 hours if no range given.
2. Collect git log entries in the time window: `git log --since="$SINCE" --format="%H|%ai|%an|%s"`.
3. Scan coordination bus (`$PROJECT_ROOT/_state/coordination/messages.tsv`) for entries in the time window.
4. Scan cognition ledger (`_state/cognition/ledger.jsonl`) for entries in the time window.
5. Correlate events by timestamp into a unified timeline.
6. If `--format summary`: group by actor and summarize actions, decisions, and outcomes.
7. If `--format timeline` (default): present chronologically with source labels (git/bus/ledger).
8. Flag any anomalies: reverted commits, BLOCKED messages without resolution, unanswered QUESTIONs.

## Output Format
```
Session Replay | {date range}

## Timeline
{HH:MM} [{source}] {actor}: {description}
{HH:MM} [{source}] {actor}: {description}
...

## Summary
- Commits: {N} ({lines added/removed})
- Bus messages: {N} (from {agents})
- Ledger entries: {N}
- Anomalies: {list or "None"}

## Key Decisions
- {decision from bus DECISION messages or ledger}

No further action needed. | Consider [sitrep] for current state.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Session had unresolved blockers | `[sitrep]` to check current state |
| Session revealed recurring patterns | `[retrospective]` to capture learnings |
| Session was by another agent | `[agent-audit]` to verify compliance |
| replay opencode sessions tracked by the bridge | `[cross-runtime-bridge]` (`sessions`) |
