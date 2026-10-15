---
name: retrospective
description: Session or sprint retrospective -- extract learnings, failures, and patterns to compound knowledge.
version: 0.1.0
execution-mode: advisory
argument-hint: "[session | sprint | incident \"DESCRIPTION\"]"
category: fleet-ops
status: candidate
---
# Retrospective

Structured review that extracts learnings and persists them to the cognitive ledger.

## Execution

### 1. Gather evidence
Depending on scope:

**Session retro:**
```bash
git log --oneline --since="8 hours ago"
grep "$(date +%Y-%m-%d)" $PROJECT_ROOT/_state/coordination/messages.tsv | grep -E "MILESTONE|RECEIPT|BLOCKED|ERROR" | tail -20
```

**Sprint retro:**
```bash
git log --oneline --since="2 weeks ago" | head -30
grep "MILESTONE\|BLOCKED" $PROJECT_ROOT/_state/coordination/messages.tsv | tail -30
```

### 2. Classify events
- **Went well**: What worked, what to repeat
- **Went wrong**: What failed, what caused friction
- **Learned**: New understanding gained
- **Lucky**: Things that worked but shouldn't be relied on

### 3. Extract patterns
Look for recurring themes:
- Same type of bug appearing multiple times?
- Same workflow friction in every session?
- A tool or skill that keeps getting invoked manually?
- An agent that consistently needs correction?

### 4. Persist to CLP
For each significant learning:
```bash
source .venv/bin/activate
python -m hummbl_governance.cognition post \
  --vendor "${AGENT_VENDOR:?set AGENT_VENDOR to the provider actually running}" --model "${AGENT_MODEL:?set AGENT_MODEL to the model actually running}" \
  --type lesson --scope process \
  --content "<the learning>" \
  --tags "retrospective,<sprint-name>"
# The skill invocation runtime injects the caller's canonical identity as agent.
```

## Output Format
```
Retrospective | <scope> | <date>
══════════════════════════════════

## Went Well
- <what worked>

## Went Wrong
- <what failed and why>

## Learned
- <new understanding>

## Actions
- [ ] <specific change to make>
- [ ] <skill to create or update>
- [ ] <process to modify>

## Persisted to Ledger
- clp-<id>: <summary>
```
