---
name: deliverable-check
description: Verify SOW deliverables are complete before invoicing — checklist against contract
version: 1.0.0
execution-mode: advisory
argument-hint: <sow-path>
category: finance-legal
status: candidate
---
# Deliverable Check

Verify SOW/contract deliverables are complete before invoicing. Parses a SOW markdown file, checks each deliverable against actual artifacts, and produces an invoice-readiness verdict.

## Inputs

- `$ARGUMENTS` = path to SOW or contract markdown file
- If no path given, prompt user or check `PROJECTS/$REPO_NAME/contracts/` for recent SOWs

## Workflow

### Step 1: Parse SOW for Deliverables

Read the SOW file with the `Read` tool. Extract every deliverable by scanning for:
- Numbered deliverable lists (e.g., "Deliverable 1:", "D1:", "1.")
- Tables with "Deliverable" column headers
- Sections titled "Deliverables", "Milestones", "Scope of Work", "Work Products"
- Acceptance criteria (usually indented under each deliverable or in a separate column)

Build a structured list:
```
ID | Deliverable | Acceptance Criteria | Due Date | Artifact Type
```

### Step 2: Verify Each Deliverable

For each deliverable, determine artifact type and check existence:

**File artifacts**: Use `Glob` to search for the expected file path or pattern.
**Git tags/releases**: Run `git tag -l '*<pattern>*'` to verify release tags exist.
**URLs/deployments**: Note for manual verification (cannot HTTP check from here).
**Test results**: Run `python -m pytest <path> -v --tb=no -q` if tests are the acceptance criterion.
**Documentation**: Use `Glob` and `Read` to verify doc files exist and contain expected sections.
**CRM entries**: Check your CRM (e.g., Google Sheets) (ID: $GOOGLE_SHEET_ID) if deliverable is a CRM update.

For acceptance criteria:
- If criteria says "passes all tests" -- run the tests
- If criteria says "reviewed and approved" -- check git log for review/merge commits
- If criteria says "delivered to client" -- check email via `mcp__gmail__gmail_search_messages` for send confirmation
- If criteria is quantitative (e.g., "95% coverage") -- run the measurement command

### Step 3: Score and Verdict

Classify each deliverable:
- **COMPLETE**: Artifact exists and acceptance criteria verified
- **PARTIAL**: Artifact exists but criteria not fully met (note what's missing)
- **MISSING**: Artifact not found
- **UNVERIFIABLE**: Cannot programmatically verify (flag for manual check)

## Output Format

```
Deliverable Check | <SOW filename> | <date>
==================================================

Client: <extracted from SOW>
Engagement: <extracted from SOW>
SOW Date: <extracted from SOW>

## Deliverable Status

| # | Deliverable | Status | Evidence | Notes |
|---|-------------|--------|----------|-------|
| 1 | <name> | COMPLETE | <file path or command output> | |
| 2 | <name> | PARTIAL | <what exists> | <what's missing> |
| 3 | <name> | MISSING | -- | <expected artifact> |

## Summary

- Total deliverables: N
- Complete: X / N
- Partial: Y / N
- Missing: Z / N
- Unverifiable: W / N

## Invoice Readiness

**VERDICT: [READY / NOT READY / CONDITIONAL]**

- READY: All deliverables COMPLETE
- CONDITIONAL: All COMPLETE or UNVERIFIABLE (manual check needed on W items)
- NOT READY: Any PARTIAL or MISSING items remain

## Blocking Items (if NOT READY)

1. <Deliverable #N>: <what needs to happen>
2. ...

## Next Actions

- [ ] <action per incomplete deliverable>
- [ ] Run `[invoice-generate]` once all items are COMPLETE
```

## Edge Cases

- If SOW has no structured deliverable list, scan for any section that implies work products and present best-effort extraction. Flag: "SOW lacks structured deliverables -- consider amending."
- If SOW references external systems (Jira, Linear, Asana), note ticket IDs for manual cross-reference.
- If a deliverable references a milestone date that has not yet passed, mark as "NOT YET DUE" rather than MISSING.

## Chains

- After READY verdict: suggest `[invoice-generate]`
- After NOT READY: suggest `[time-track] summary` to check hours before completing remaining work
- If SOW is missing: suggest `[sow-generate]` to create one
