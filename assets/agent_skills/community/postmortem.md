---
name: postmortem
description: Blameless post-incident review with timeline, root cause, contributing factors, and action items
version: 0.1.0
execution-mode: advisory
argument-hint: "[--incident DESCRIPTION] [--severity P1|P2|P3]"
category: governance-compliance
status: candidate
---
# Postmortem

Conduct a blameless post-incident review following industry best practices. Constructs a timeline from logs and bus messages, identifies root cause and contributing factors, documents impact, and generates concrete action items with owners and deadlines.

## When to Use
- After any production incident or service outage has been resolved
- After a near-miss that could have caused an incident
- After a security event or data integrity issue
- When a pattern of smaller failures suggests a systemic problem

## Execution
1. Parse `$ARGUMENTS` for incident description and severity level
2. Gather evidence: check bus messages, git log, health probe history, and relevant logs for the incident timeframe
3. Construct a timeline of events from first signal to resolution
4. Identify root cause using 5-Whys analysis
5. Document contributing factors (process gaps, monitoring blind spots, design weaknesses)
6. Assess impact: duration, users affected, data loss, revenue impact
7. Generate action items categorized as: PREVENT (stop recurrence), DETECT (catch earlier), MITIGATE (reduce impact)
8. Persist the postmortem to `_state/postmortems/` with timestamp

## Output Format
```
Postmortem | <severity> | <date>
==================================

## Incident Summary
<1-2 sentence description>

## Timeline
| Time (UTC) | Event |
|------------|-------|
| ... | First signal detected |
| ... | ... |
| ... | Resolution confirmed |

## Impact
- Duration: <time>
- Severity: <P1/P2/P3>
- Users affected: <count or scope>
- Data impact: <none/partial/full>

## Root Cause (5 Whys)
1. Why? ...
2. Why? ...
3. Why? ...
4. Why? ...
5. Why? ...

## Contributing Factors
- ...

## Action Items
| Action | Type | Owner | Deadline | Status |
|--------|------|-------|----------|--------|
| ... | PREVENT | ... | ... | OPEN |
| ... | DETECT | ... | ... | OPEN |
| ... | MITIGATE | ... | ... | OPEN |

## Lessons Learned
- ...

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Incident was triggered by `[incident]` | `[incident]` provided the triage, postmortem follows |
| Learnings should be persisted | `[retrospective]` for broader pattern analysis, `[ledger]` to persist |
| Root cause reveals a decision point | `[decision-log]` to record the architectural decision |
