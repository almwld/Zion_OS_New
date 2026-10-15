---
name: status-page
description: Generate a status page from health probes showing service status and incidents
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action generate|update] [--format md|html]"
category: governance-compliance
status: candidate
---
# Status Page

Generate or update a status page from health probes, showing service status and recent incidents. Provides a single view of system health suitable for sharing with stakeholders or team members.

## When to Use
- Need a quick snapshot of all service health for stakeholders
- Updating team on system status after an incident
- Generating a periodic health report
- Creating a shareable system status document

## Execution
1. Parse `$ARGUMENTS` for `--action` (default: `generate`) and `--format` (default: `md`)
2. Collect current health status:
   a. Run health probes via `services/health.py` (8 probes)
   b. Check circuit breaker states for all 7 adapters
   c. Check kill switch state
   d. Check recent bus messages for BLOCKED entries
3. For each service/component, determine status:
   - **Operational**: all probes pass, circuit closed
   - **Degraded**: some probes warn, circuit half-open
   - **Outage**: probes fail, circuit open
   - **Maintenance**: kill switch active
4. Collect recent incidents from `_state/ops/incidents/` if present
5. If `--format md`: render as Markdown with status badges (green/yellow/red circles via Unicode)
6. If `--format html`: render as standalone HTML with inline CSS
7. If `--action update`: overwrite the existing status page at `state/status.{format}`
8. Include last-updated timestamp (UTC)

## Output Format
```
Status Page | {timestamp UTC}

Overall: {ALL_OPERATIONAL|PARTIAL_OUTAGE|MAJOR_OUTAGE}

Services:
- {service}: {status_icon} {status} (since {time})

Recent Incidents:
- {date}: {title} -- {status} -- {duration}

Last updated: {timestamp}

Next action: {recommendation}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Status generated | `[send-email]` to share with stakeholders |
| Outage detected | `[health]` for detailed probe results |
| After incident resolved | `[incident]` to close the incident record |
