---
name: bki-session-export
description: Package BKI session insights (new questions, corrections, theory updates) as a structured amendment ready for manual upload to the claude.ai BKI project.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[session-topic]"
category: cognitive
status: candidate
---
# BKI Session Export

Package BKI-relevant insights from the current agent session into a structured amendment document for manual upload to the claude.ai BKI project.

## Usage

```
[bki-session-export]                          # Export from current session (general)
[bki-session-export] "ARCANA integration"     # Export tagged with a specific topic
[bki-session-export] "Broccolilly origin"     # Export scoped to a named question or decision
```

No argument: scans the full current session. With argument: uses the topic as the export title and focuses extraction on related content.

## Why This Exists

The claude.ai BKI project and your agent session are separate contexts. Insights developed in agent sessions (new evidence, corrections, locked decisions, theory refinements) do not propagate to the claude.ai project automatically. This skill is the manual bridge.

This is the workaround for wishlist item #1 (claude.ai Project API). When that API ships, this skill becomes the automated sync layer. Until then: generate, review, upload manually.

## What Gets Exported

Scan the current conversation for any of the following BKI-relevant content:

| Category | What to look for |
|----------|-----------------|
| **BKI_00 amendments** | Corrections to the project brief: wrong dates, outdated file lists, stale "last synthesized" dates, incorrect integration status |
| **BKI_03 new open questions** | Questions raised during this session that do not yet appear in the decisions/questions register |
| **BKI_03 new locked decisions** | Decisions reached during this session with rationale that should be added to the decisions table |
| **BKI_01 theory corrections** | Corrections to stated propositions, equations, framework names, empirical claims, or source attributions |
| **BKI_04 artifact status changes** | Published/shipped/blocked/revised status changes for any artifact in the publishable artifacts file |
| **BKI_04 new artifacts** | Drafts, outlines, or new publishable artifacts produced during this session |
| **Memory corrections** | Corrections to known facts that appear in MEMORY.md or the BKI docs (LUX•SYNC references, agent count policy, Broccolilly origin, CON units attribution, NEXUS AI cleanup status, etc.) |

### Known Corrections to Always Check

These are known issues; if any came up in the session, include them:

- **LUX•SYNC**: If mentioned, flag that this name may be stale or context-specific — confirm current canonical name before propagating
- **Agent count**: Decision is never to enumerate publicly; if session discussed a count, redact from any external artifact
- **Broccolilly Equation origin**: The equation is the author's original work; if any session content misattributes it, correct in export
- **CON units / consciousness currency**: Must remain physically separate from empirical BKI claims — flag any co-location

## Output

Write the export file to:

```
$HOME/PROJECTS/arcana/bki_docs_for_claude_ai/exports/bki_session_export_YYYYMMDD.md
```

Use today's date. If a file for today already exists, append `_2`, `_3`, etc.

## Export File Structure

```markdown
# BKI Session Export — YYYYMMDD
**Session topic**: [argument or "general session"]
**Generated**: YYYY-MM-DD HH:MM (local)
**Source**: agent session (this machine)
**Status**: AWAITING MANUAL UPLOAD

---

## What Changed This Session

[1-3 bullet summary of what this export adds or corrects. This is what the human
reads to decide whether to upload immediately or queue it.]

---

## BKI_00 Amendments
[Corrections to the project brief. For each: what the current text says, what it
should say, and which file/section to find it in.]

_No amendments_ if nothing applicable.

---

## BKI_03 Amendments

### New Open Questions
[Each new question not already in BKI_03. Format: question text, what it unlocks,
which session turn surfaced it.]

### New Locked Decisions
[Each decision reached. Format matching the existing BKI_03 decisions table:
Decision | Rationale | Date]

_No amendments_ if nothing applicable.

---

## BKI_01 Theory Corrections
[Corrections to theoretical content. For each: the incorrect statement (quoted),
the correction, and the confidence level (VERIFIED / INFERRED / AUTHOR-TO-CONFIRM).]

_No amendments_ if nothing applicable.

---

## BKI_04 Artifact Updates

### Status Changes
[Any artifact that shipped, got blocked, or changed state. Format: artifact name,
old status, new status, evidence.]

### New Artifacts
[Any new publishable artifacts produced: title, type, word count or length estimate,
current status, blocker if any.]

_No amendments_ if nothing applicable.

---

## Upload Checklist

Files to re-upload to the claude.ai BKI project, in order:

- [ ] `BKI_00_PROJECT_BRIEF.md` — if BKI_00 amendments section is non-empty
- [ ] `BKI_01_THEORY_MASTER.md` — if BKI_01 corrections section is non-empty
- [ ] `BKI_03_OPEN_QUESTIONS_AND_DECISIONS.md` — if BKI_03 amendments section is non-empty
- [ ] `BKI_04_PUBLISHABLE_ARTIFACTS.md` — if BKI_04 section is non-empty
- [ ] New artifact files — list any new files produced

**Suggested upload order**: BKI_00 first (orientates the project), then BKI_01, BKI_03, BKI_04, new artifacts.

**Note**: The claude.ai project requires manual file replacement. Delete the old version of each file before uploading the revised version, or the project will hold duplicate content.

---
_Generated by [bki-session-export] v0.1.0_
```

## Execution Instructions

When this skill runs:

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=bki-session-export] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. **Scan the conversation** for any content matching the categories in "What Gets Exported" above. Do not fabricate — only extract what was explicitly discussed or decided.

2. **Check against known BKI state**: The current BKI files are at `$HOME/PROJECTS/arcana/bki_docs_for_claude_ai/`. Read them only if needed to determine whether something is already captured or would be a new addition.

3. **Write the export file** to the exports directory. Use the template above exactly — including the `_No amendments_` placeholder for empty sections. Never omit a section; an empty section tells the human that category was checked.

4. **Report back** with:
   - The file path written
   - A 2-3 line summary of what the export contains
   - Which BKI files need to be updated (the upload checklist)

5. **Do not modify the BKI source files directly**. This skill produces the export document only. The human applies changes to the BKI files and uploads them to claude.ai manually.

## Evidence Standard

Every item in the export must cite:
- Which turn or exchange in the session it came from (paraphrase is fine; quote if precision matters)
- Confidence level: VERIFIED (confirmed by source), INFERRED (reasonable from context), or AUTHOR-TO-CONFIRM (requires human validation before propagating)

Do not include anything rated AUTHOR-TO-CONFIRM in the BKI_03 "locked decisions" section. Route those to "new open questions" instead.

## Related

- BKI source files: `$HOME/PROJECTS/arcana/bki_docs_for_claude_ai/`
- Exports directory: `$HOME/PROJECTS/arcana/bki_docs_for_claude_ai/exports/`
- Theoretical foundations rule: `~/.agents/rules/theoretical-foundations.md`
- Memory: `$RUNTIME_MEM/MEMORY.md` (resolve via `~/.agents/scripts/resolve-memory.sh`) + `~/.agents/MEMORY.md` fleet canonical (BKI Framework section)
- Session export to claude.ai (context only): `[context-export]`

## Skill Chains

### Mandatory

None — file generation for manual upload; no external systems are modified by this skill.

### Advisory

- After export generated → `[context-export]` for additional session context
- Before uploading → human review of the export file

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (file generation only)
- **Operator**: Override any restriction
