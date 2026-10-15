---
name: meeting-capture
description: Post-meeting agent — fetches Gemini transcript from Google Drive, extracts decisions/actions/outcomes with MTSMU rigor, updates people memory, posts to bus.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[drive_url_or_filename] [participant_name]"
category: dev-tools
status: candidate
---
# Meeting Capture Agent

Post-meeting processing. Gemini takes notes → transcript lands in Drive → this agent turns it into structured memory.

**MTSMU contract:** Every claim must be sourced from the transcript. Nothing inferred. Mark unknowns as `[not in transcript]`.

## Usage

```bash
[meeting-capture]                          # Auto-fetch most recent transcript from configured Drive folder
[meeting-capture] dan                      # Filter to Dan meeting specifically
[meeting-capture] <drive_url>              # Process a specific file by URL
[meeting-capture] 2026-04-07 dan          # Date + participant
```

## Configured Drive Folder

Default transcript folder: ask user or check `_state/meetings/config.json` for `transcript_folder_id`.

If not configured, prompt: "What's the Google Drive folder where Gemini saves your meeting transcripts?"

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=meeting-capture] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### Step 1 — Fetch transcript

Use gdrive MCP to get the most recent file from the meeting transcripts folder:

```
mcp__gdrive__search — query: "meeting transcript", recent files
mcp__gdrive__getGoogleDocContent or mcp__gdrive__downloadFile
```

If a Drive URL was provided as argument, resolve it directly.

If no transcript found: report and stop. Do NOT fabricate content.

### Step 2 — Parse participants

From the transcript header or speaker labels, identify:
- Who was in the meeting
- Date and duration
- Meeting type (internal / client / partner / coaching)

Match participants to known people memory files:
- "Dan" / "Daniel" / "Dan Matha" → `people_dan_matha.md`
- Unknown participant → create `people_[name].md` stub using the people template

### Step 3 — Extract with MTSMU rigor

Read the full transcript. Extract ONLY what is explicitly stated. Four buckets:

**DECISIONS** — things explicitly agreed to, committed to, or resolved
- Format: `[DECISION] <what was decided> — source: "<exact quote or paraphrase from transcript>"`
- Do NOT include things "discussed" or "considered" — only closed commitments

**ACTION ITEMS** — specific tasks with an owner
- Format: `[ACTION] <owner>: <task> — by: <date if stated, else TBD>`
- If ownership is ambiguous, mark `[SHARED]`

**OPEN QUESTIONS** — things raised but not resolved
- Format: `[OPEN] <question> — raised by: <speaker>`

**KEY CONTEXT** — facts, signals, or relationship updates worth persisting
- Format: `[CONTEXT] <fact> — source: transcript`

### Step 4 — Update people memory

For each identified participant with an existing `people_*.md`:

1. Read the current file
2. Add/update relevant sections:
   - Open items (tick off completed ones, add new ones)
   - Current situation (update with new context)
   - Last updated line
3. Write the updated file

Do NOT overwrite existing open items unless the transcript explicitly shows them resolved.

### Step 5 — Write to _state/meetings/

Append to `_state/meetings/action_items.jsonl`:
```json
{"id": "AI-YYYY-MM-DD-NNN", "owner": "reuben|dan|shared", "action": "...", "source": "YYYY-MM-DD meeting", "status": "OPEN", "due": "YYYY-MM-DD|TBD", "created": "ISO8601"}
```

Append to `_state/meetings/decisions.jsonl`:
```json
{"id": "DEC-YYYY-MM-DD-NNN", "decision": "...", "participants": ["reuben", "dan"], "source": "YYYY-MM-DD meeting", "status": "ACTIVE", "created": "ISO8601"}
```

Create these files if they don't exist.

### Step 6 — Post to bus

Post a MILESTONE to the bus summarizing the meeting capture.
```
Type: MILESTONE
To: all
Message: Meeting capture complete: YYYY-MM-DD [participant]. Decisions: N. Actions: N (R:X / D:X / Shared:X). Open: N. people_*.md updated.
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### Step 7 — Output

```
MEETING CAPTURE | <date> | <participants> | <duration>
═══════════════════════════════════════════════════════

## Decisions (N)
- [DECISION] ...
  Source: "..."

## Action Items (N)
- [ACTION] Reuben: ...  due: TBD
- [ACTION] Dan: ...  due: YYYY-MM-DD
- [SHARED] ...

## Open Questions (N)
- [OPEN] ...

## Key Context
- [CONTEXT] ...

## Memory Updated
- people_dan_matha.md — N changes
- _state/meetings/action_items.jsonl — N entries added
- _state/meetings/decisions.jsonl — N entries added

## Bus
✓ Posted MILESTONE

---
Next: [decision-log] (for major decisions) | [send-email] dan (if follow-up needed)
```

## Constraints

- **MTSMU hard rule:** If it's not in the transcript, it doesn't go in the output. Mark gaps as `[not in transcript]`.
- **No fabrication:** Do not infer decisions from discussion. A thing discussed ≠ a thing decided.
- **No overwrite:** Only update people memory sections that have new information. Preserve existing entries.
- **Idempotent:** Running twice on the same transcript should not create duplicate entries — check IDs before appending.
- **People file creation:** If a participant has no memory file, create a stub using `people_template.md` pattern and note it in output.

## Skill Chains

### Mandatory

None — meeting capture is read-only transcript processing with bus posts for coordination.

### Advisory

- After major decisions captured → `[decision-log]` to formalize in the decision register
- If follow-up needed → `[send-email]` or `[send-signal]` to participant
- After action items extracted → `[sprint-status]` to integrate into sprint planning

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (read-only)
- **Operator**: Override any restriction
