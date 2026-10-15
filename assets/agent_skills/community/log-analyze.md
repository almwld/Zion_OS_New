---
name: log-analyze
description: Pattern recognition in log files -- error clusters, timing anomalies, frequency analysis
version: 0.1.0
execution-mode: advisory
argument-hint: "<file> [--pattern ERROR|WARN|SLOW] [--since DATE]"
category: dev-tools
status: candidate
---
# Log Analyze

Perform pattern recognition on log files to surface error clusters, timing anomalies, and frequency distributions. Groups related errors, detects bursts, and identifies slowest operations.

## When to Use
- A service is misbehaving and you need to understand log patterns
- You want to find the most frequent error types in a log file
- You need to detect timing anomalies or performance degradation over time
- You want a statistical summary of log severity distribution

## Execution
1. Parse `$ARGUMENTS` for file path, optional `--pattern` filter, and `--since` date filter
2. Read the log file, detecting format (syslog, JSON, plain text with timestamps)
3. Parse timestamps and classify each line by severity (ERROR, WARN, INFO, DEBUG)
4. If `--since` specified, filter to entries after that date
5. Cluster errors by message similarity (strip variable parts like IDs, timestamps)
6. Compute frequency distribution by severity and by hour
7. Detect timing anomalies: bursts (>3x average rate in any window), gaps (>2x average interval)
8. Identify slowest operations if duration data is present
9. Present findings sorted by impact

## Output Format
```
Log Analyze | <filename>

## Summary
Lines: <N>  |  Time span: <start> to <end>  |  Duration: <hours/days>
ERROR: <N> (<pct>%)  |  WARN: <N> (<pct>%)  |  INFO: <N> (<pct>%)

## Top Error Clusters
| # | Count | Pattern | First Seen | Last Seen |
|---|-------|---------|------------|-----------|
| 1 | 47    | Connection timeout to <host> | ... | ... |
| 2 | 23    | Failed to parse response: ... | ... | ... |

## Anomalies
- BURST: <N> errors in <window> at <time> (normal rate: <N>/hr)
- GAP: No entries for <duration> starting at <time>
- SLOW: <operation> took <duration> (p95: <value>)

## Hourly Distribution
<ASCII bar chart of error counts by hour>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Errors point to a service issue | `[incident]` to triage and respond |
| Recurring pattern needs alerting | `[alert-rule]` to set up automated alerts |
| Need more log context | `[log-tail]` to stream live logs |
