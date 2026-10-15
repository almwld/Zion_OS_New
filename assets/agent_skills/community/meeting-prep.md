---
name: meeting-prep
description: Prepare agenda, context, and action items for a meeting with stakeholders.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"MEETING TOPIC\" [with PERSON]"
category: fleet-ops
status: candidate
---
# Meeting Prep

Generate a structured meeting prep package with context, agenda, and pre-reads.

## Execution

### 1. Gather context
Depending on meeting type, pull from:

**Technical sync (with co-founder):**
```bash
git log --oneline --since="7 days ago" | head -15
grep "BLOCKED\|MILESTONE" _state/coordination/messages.tsv | tail -10
```

**Investor update:**
- Run `[investor-update]` for metrics
- Run `[runway]` for financial context

**Sprint planning:**
- Run `[sprint-status]` for current state
- Run `[retrospective] sprint` for learnings

**Product review:**
- Run `[briefing-history]` for recent outputs
- Run `[scope-decompose]` for upcoming features

### 2. Draft agenda
```
Meeting: <topic>
Date: <date>
Participants: <who>
Duration: <estimated time>

## Agenda
1. [5 min] <topic> -- <what to discuss, what decision needed>
2. [10 min] <topic> -- <context>
3. [5 min] <topic>

## Pre-Read
- <link or reference participants should review>

## Context
<brief background for anyone joining cold>

## Decisions Needed
- [ ] <decision 1>
- [ ] <decision 2>

## Action Items (from last meeting)
- [ ] <carried over item>
```

### 3. Prepare visual aids
If the meeting needs diagrams:
- Run `[arch-diagram]` for architecture visuals
- Run `[sitrep]` for status dashboard
- Prepare screen shares for live demos

## Output Format
```
Meeting Prep | <topic> | <date>
══════════════════════════════════

## Agenda
<structured agenda with time boxes>

## Context
<background for participants>

## Key Metrics
<relevant numbers>

## Decisions Needed
<what must be decided in this meeting>

## Pre-Read
<materials to review beforehand>
```
