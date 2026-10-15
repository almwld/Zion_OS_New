---
name: escalation-policy
description: Define and manage escalation chains for alerts and incidents
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action define|view|test] [--severity P1|P2|P3|P4]"
category: governance-compliance
status: candidate
---
# Escalation Policy

Define and manage escalation chains for alerts and incidents: who to contact, when, via which channel. Ensures critical issues reach the right person within defined time windows.

## When to Use
- Setting up alerting for a new service or system
- Reviewing whether current escalation paths are adequate
- Testing that escalation contacts are reachable
- After an incident where escalation was slow or missed

## Execution
1. Parse `$ARGUMENTS` for `--action` (default: `view`) and `--severity` (default: show all)
2. If `--action view`: display current escalation policies from `_state/ops/escalation.json` or equivalent
3. If `--action define`:
   a. Prompt for severity level (P1-P4) definitions
   b. For each level, define: response time SLA, notification channels (Signal, email, Discord), escalation chain (primary -> secondary -> manager), auto-escalation timeout
   c. Write policy to state file
4. If `--action test`:
   a. For each severity level (or specified `--severity`): simulate an alert
   b. Verify contact channels are reachable (dry-run notification)
   c. Report which channels succeeded/failed
5. Severity defaults:
   - P1 (critical): 15 min response, all channels, auto-escalate at 30 min
   - P2 (high): 1 hr response, Signal + email, auto-escalate at 2 hr
   - P3 (medium): 4 hr response, email, no auto-escalation
   - P4 (low): next business day, email digest

## Output Format
```
Escalation Policy | action: {action}

{severity_level}:
  Response SLA: {time}
  Channels: {list}
  Chain: {primary} -> {secondary} -> {fallback}
  Auto-escalate: {timeout or "none"}

{test results if --action test}

Next action: {recommendation}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Policy defined | `[alert-rule]` to wire up alerts |
| During an incident | `[incident]` for incident management |
| Scheduling on-call | `[on-call]` for rotation setup |
