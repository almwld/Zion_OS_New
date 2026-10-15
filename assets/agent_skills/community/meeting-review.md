---
name: meeting-review
description: Review meeting context, open action items, recent decisions, and last meeting summary.
version: 0.1.0
execution-mode: advisory
argument-hint: Optional meeting date (YYYY-MM-DD) or participant name
category: fleet-ops
status: candidate
---
# Meeting Review

## When to Use
- Before a meeting with co-founder or any co-founder/stakeholder
- Start of a session where meeting follow-up is needed
- When asked "what did we decide?" or "what's still open?"

## Usage

```bash
[meeting-review]              # Full review (all open items)
[meeting-review] 2026-03-24   # Review specific meeting
[meeting-review] dan          # Filter to stakeholder-related items
```

## Data Sources

### 1. Open Action Items
```bash
cat $PROJECT_ROOT/_state/meetings/action_items.jsonl | python3 -c "
import json, sys
for line in sys.stdin:
    item = json.loads(line)
    if item.get('status') in ('OPEN', 'ACTIVE', 'UNKNOWN'):
        print(f\"  [{item['status']:7s}] {item['owner']:8s} | {item['action']} (from {item['source']})\")" 2>/dev/null
```

### 2. Recent Decisions
```bash
tail -20 $PROJECT_ROOT/_state/meetings/decisions.jsonl | python3 -c "
import json, sys
for line in sys.stdin:
    d = json.loads(line)
    if d.get('status') == 'ACTIVE':
        print(f\"  {d['id']:22s} | {d['decision']}\")" 2>/dev/null
```

### 3. Last Meeting Summary
```bash
ls -t ~/Downloads/meeting-transcripts/markdown/*.md 2>/dev/null | head -1
```
Read Gemini's summary section from the most recent transcript.

### 4. Ledger Decisions
```bash
python3 -m hummbl_governance.cognition query --type decision --limit 10 2>/dev/null
```

### 5. Bus Activity (since last meeting)
```bash
tail -20 $PROJECT_ROOT/_state/coordination/messages.tsv 2>/dev/null
```

## Output Format

```
MEETING REVIEW | <date>
=============================

## Open Action Items
### Owner
- [ ] <action> (from <meeting date>)

### Team Lead
- [ ] <action> (from <meeting date>)

## Active Decisions (last 30 days)
- DEC-YYYY-MM-DD-NNN: <decision>

## Since Last Meeting
- <key git commits, bus activity, shipped items>

## Suggested Agenda
1. <Review open items from above>
2. <Any blockers from bus/health>
3. <Next priorities>
```

## Constraints
- READ-ONLY. Do not modify action items or decisions.
- If action_items.jsonl doesn't exist, note it and suggest running the extraction.
- If no transcripts found, skip that section.
- Keep output scannable — this should take 30 seconds to read.
- Highlight OVERDUE items prominently.
