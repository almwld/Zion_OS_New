---
name: memory-registry
description: Manage the active Codex memory registry, rollout summaries, and explicit ad hoc update notes.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[status | search \"TERM\" | check | summaries | note \"CONTENT\"]"
category: cognitive
status: candidate
---
## Context Gathering

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=memory-registry] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Before executing this skill, gather the following context:
- **MEMORY.md lines**: Run `$p='$env:USERPROFILE\.codex\memories\MEMORY.md'; if (Test-Path $p) { (Get-Content -Path $p).Count } else { '0' }`
- **Rollout summaries**: Run `$p='$env:USERPROFILE\.codex\memories\rollout_summaries'; if (Test-Path $p) { (Get-ChildItem -Path $p -File -Filter *.md).Count } else { '0' }`

# Memory Registry Command

Manage the active runtime memory system. Resolve the runtime memory dir via
`~/.agents/scripts/resolve-memory.sh` (→ `$RUNTIME_MEM`) or `resolve-memory.ps1`.
The fleet canonical index is `~/.agents/MEMORY.md` (`$FLEET_MEM`).

Do not use the legacy `~/.claude/projects/-Users-others/memory/` path unless the user
explicitly asks to inspect archived Claude memory.

## Operations

### status
Show memory health: registry line count, summary freshness, rollout count, and recent
ad hoc update notes.

```powershell
$root = '$env:USERPROFILE\.codex\memories'
"MEMORY.md lines: $((Get-Content "$root\MEMORY.md").Count)"
"Root files:"
Get-ChildItem $root -File | Sort-Object LastWriteTime -Descending | Select-Object -First 5 Name,LastWriteTime,Length
"Rollout summaries: $((Get-ChildItem "$root\rollout_summaries" -File -Filter *.md).Count)"
"Recent ad hoc notes:"
Get-ChildItem "$root\extensions\ad_hoc\notes" -File -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending | Select-Object -First 5 Name,LastWriteTime
```

`MEMORY.md` is a large registry, not a small always-loaded topic file. Prefer targeted
searches and open only the 1-2 rollout summaries or skill files directly relevant to
the current task.

### check
Audit MEMORY.md for staleness:
- Verify numeric claims (test counts, skill counts, module counts) against live data
- Check for outdated dates or references to completed work
- Flag any entries that reference retired agents or deprecated features

### search
Search the registry first, then only the pointed rollout summaries or skill folders
that match the task.

```powershell
$root = '$env:USERPROFILE\.codex\memories'
Select-String -Path "$root\MEMORY.md" -Pattern 'SEARCH_TERM'
Get-ChildItem "$root\rollout_summaries" -File -Filter *.md |
  Select-String -Pattern 'SEARCH_TERM'
```

### summaries
List recent rollout summaries:

```powershell
$root = '$env:USERPROFILE\.codex\memories'
Get-ChildItem "$root\rollout_summaries" -File -Filter *.md |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 20 Name,LastWriteTime,Length
```

### note
Only update memory when the user explicitly asks. Do not edit `MEMORY.md`,
`memory_summary.md`, or `raw_memories.md` directly. Instead, write one small update note
under:

`$env:USERPROFILE\.codex\memories\extensions\ad_hoc\notes\`

Name the note `<timestamp>-<short-slug>.md`, and keep it to the requested
add/delete/update instruction.

## Memory Types
- `user`: Role, goals, preferences
- `feedback`: Corrections, guidance
- `project`: Ongoing work, decisions, deadlines
- `reference`: External system pointers

## Key Paths
- Summary: `$env:USERPROFILE\.codex\memories\memory_summary.md`
- Registry: `$env:USERPROFILE\.codex\memories\MEMORY.md`
- Rollout summaries: `$env:USERPROFILE\.codex\memories\rollout_summaries\*.md`
- Skill memories: `$env:USERPROFILE\.codex\memories\skills\`
- Ad hoc update notes: `$env:USERPROFILE\.codex\memories\extensions\ad_hoc\notes\`

## Skill Chains

### Mandatory

None — memory management is local config with no external dependencies.

### Advisory

- `[hummbl-cognition]` — query the cognition ledger for related context after memory updates

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run with operator notification
- **Operator**: Override any restriction
