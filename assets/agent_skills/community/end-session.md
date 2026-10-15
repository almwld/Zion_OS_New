---
name: end-session
description: Disciplined session closeout. Run before signing off.
version: 0.3.0
execution-mode: side_effecting
category: fleet-ops
status: candidate
providers:
  required: [pytest, python]
---
# End Session

Gracefully close the current session with handoff, bus post, and optional AAR.

## Working Directory

Run all `git`, `gh`, `pytest`, and `rg` commands from the fleet repo root (`~/.agents` or the active worktree equivalent). Never assume a package-relative CWD. (The prior canonical repo `hummbl-governance` is archived; `~/.agents` is the live fleet repo.)

## Usage

```bash
[end-session]              # Standard graceful shutdown
[end-session] aar          # Shutdown with inline AAR
```

The cross-platform implementation is `end_session.py`. It posts the durable
HANDOFF status before the `SKILL_INVOKE` marker so a crash during closeout
cannot leave the next session with an invocation but no surviving handoff.
Use `python end_session.py --handoff "..." --vendor <vendor> --model <model>`
from this skill directory; the implementation is stdlib-only and works on
Windows and Unix.

The script is runtime-neutral and assumes nothing about who is running it.
Pass the ledger vendor id and model of the runtime that is actually running
this session (or set `AGENT_VENDOR` / `AGENT_MODEL`); the sender is `--sender`
or your runtime's canonical identity (`BUS_AGENT_ID`). Without a vendor the
CLP ledger entry is skipped rather than written with a guessed provider, and
the result reports `local_durability.ledger_error`.

**Do NOT post the end-session SKILL_INVOKE manually.** Always use
`end_session.py`, which guarantees the HANDOFF STATUS is posted first.
Manual SKILL_INVOKE posts without a preceding HANDOFF are flagged as
INCOMPLETE_CLOSE by bus forensics. (Origin: 2026-09-04 fleet forensics —
7 sessions posted end-session SKILL_INVOKE without a detectable HANDOFF.
5 of 7 actually had HANDOFF content in a STATUS message, but 2 genuinely
skipped the handoff step.)

## Procedure

Execute ALL steps in order. Do NOT skip any step.

### Prerequisite: Operator Confirmation

**Do not initiate end-session until the operator explicitly confirms the
session is complete** (e.g., says "goodnight", "end session", "close out",
"wrap up", or similar). Completing all todo items or goals is NOT sufficient
— the operator may redirect to new work at any point. If end-session was
initiated but the operator then redirects, post a corrected SITREP noting
the premature close and continue working.

Origin: 2026-09-02 — end-session was initiated at 04:33Z (SKILL_INVOKE +
HANDOFF posted) but the operator said "continue, find work" and the session
ran 15 more minutes merging 5 PRs. The handoff was premature.

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=end-session] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1a. Orphaned Git State Cleanup
```bash
git cherry-pick --abort 2>/dev/null; git rebase --abort 2>/dev/null; true
```
Silently clears any cherry-pick or rebase sequencer left mid-flight. Run first — orphaned sequencer state blocks commits in the next session.

### 1a2. Git Worktree Prune and Stale-Rebase Check
```bash
# Prune dead worktree metadata across all repos
for repo in /work/active/*; do
  [ -d "$repo/.git" ] && git -C "$repo" worktree prune 2>/dev/null
done

# Check for stale rebase state in worktrees
for repo in /work/active/*; do
  [ -d "$repo/.git/rebase-merge" ] && echo "STALE REBASE: $repo"
  [ -d "$repo/.git/rebase-apply" ] && echo "STALE REBASE: $repo"
done
```
Prunes dead worktree metadata and detects stale rebase state. If a stale rebase is found and no active process owns it, abort it: `git -C <repo> rebase --abort`. Origin: 2026-09-02 — a 4h-old interactive rebase in `/work/active/oss` could have confused a concurrent agent session.

### 1a3. Destructive Reflog Check (REQUIRED — do not skip)

Check for `git reset --hard` or `git checkout -- .` operations during this
session on shared repos. These discard uncommitted work and are the most
common cause of silent data loss across concurrent agent sessions.

```bash
# Get this session's start timestamp from the bus or session metadata.
# If unavailable, use the last 8 hours as a fallback window.
SESSION_START_TS="${SESSION_START_TS:-$(date -u -d '8 hours ago' +%Y-%m-%dT%H:%M:%S)}"

# Check reflog for destructive operations on shared repos
for repo in "$HOME/.agents" /work/active/*; do
  [ -d "$repo/.git" ] || continue
  destructive=$(git -C "$repo" reflog --since="$SESSION_START_TS" --format="%gs" 2>/dev/null | \
    grep -iE "reset --hard|checkout --" | head -5)
  if [ -n "$destructive" ]; then
    echo "DESTRUCTIVE REFS in $repo:"
    echo "$destructive"
  fi
done
```

If any destructive reflog entries are found:
1. Check `git -C <repo> stash list` — a stash may have captured the work
2. Check `git -C <repo> reflog` for the prior HEAD position — recoverable via `git reset --hard <old-sha>`
3. Document the destructive op in the handoff (step 2) with the repo, timestamp, and whether work was recovered

Origin: 2026-09-05 forensic audit — `shared-humor` session ran `git checkout -- .` + `git reset --hard` on `~/.agents` with uncommitted edits to `skills/ops/SKILL.md`, discarding them. The reflog check would have surfaced this at session end instead of requiring a post-hoc forensic investigation.

### 1b. Untracked Skill Directories Check
```bash
git status --short -- ~/.agents/skills/ | grep "^??" | head -10
```
Untracked skill dirs (`??`) are invisible to the staged-changes filter below. Any `??` entry here is an orphaned skill directory missing `_index`, routing, and `MEMORY.md` entries. Register before closing.

### 1b2. Skill Index Freshness Check
```bash
python ~/.agents/skills/_regen_index.py --check
```
Non-zero exit = skill dirs added/removed without an `_index` regen. Run `python ~/.agents/skills/_regen_index.py` to regenerate, or flag in the handoff if registration is unresolved. Origin: 2026-08-03 — `_index` sat stale 8 days (46 unindexed skills) because no gate checked freshness; lean copy of this skill is write-frozen (sandbox guard) and lacks this step pending lean promotion.

### 1c. Uncommitted Work Check
```bash
git status --short | grep -E "^[MADRCU]" | head -10
```
If there are staged changes, WARN the user before proceeding. Do not auto-commit.

### 1c2. Untracked File Age Check
```bash
git ls-files --others --exclude-standard | while IFS= read -r f; do
  age_days=$(( ($(date +%s) - $(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f")) / 86400 ))
  [ "$age_days" -gt 1 ] && echo "$age_days days old: $f"
done | head -5
```
Surface untracked files >1 day old. These are likely orphans — either useful artifacts that need a permanent home (commit, move to `_internal/`, or delete) or stale residue. Mention in handoff for next session triage. Origin: 2026-04-26 — codex hummbl.io handoff sat 3 days untracked before being moved to `_internal/handoffs/`.

### 1d. Stale Issue Triage (awareness-only)
```bash
gh issue list --state open --limit 20 --json number,title,createdAt,comments \
  --jq '.[] | select((.comments | length) == 0) | "#\(.number) \(.createdAt[:10]) \(.title)"'
```
Surface any open issue with 0 comments. If any has `createdAt` >14 days old, mention it once in the handoff so operator can triage in the next session. Do NOT close or comment on issues here — this step is awareness, not action. Triage runs in a focused session where files referenced in the issue can be verified (origin: 2026-04-26 #381 was a wrong-repo misfile that sat 2 weeks unactioned).

### 1e. Orphaned WIP Lane Check (REQUIRED — do not skip)
```bash
python $HOME/.agents/scripts/check-orphaned-wips.py --sender <your-canonical-identity>
```
Non-zero exit = you have at least one open lane (`WIP_START` with no matching
`WIP_END`). This is the #1 cause of dropped work across sessions — a lane
gets opened, work happens (or doesn't), and the session just ends without
ever posting the close. See `bus-lexicon.md` § Self-check before ending a
turn or session.

For each orphan reported, before proceeding to step 2, do ONE of:
- **Done** → post `WIP_END` now (outcome + verification), OR
- **Incomplete** → make sure the HANDOFF in step 2 explicitly names this
  lane, what's done, what's open, and next owner — a generic handoff summary
  is not sufficient, the lane name must appear, OR
- **Genuinely stuck / not actionable this session** → say so explicitly and
  note it will remain open; do not silently let it join the orphan list.

Do not proceed to the final message with an unresolved orphan that isn't at
least named in the handoff.

### 1f. Local Durability Write (REQUIRED — do not skip)

Write the durable handoff record locally BEFORE posting anything to the
bus. This guarantees the handoff survives even if the bus is unreachable.

`end_session.py` calls `session-close --no-bus` automatically before the
HANDOFF bus post. The local artifact at
`~/.agents/state/handoffs/<ts>-<agent>-<sid>.md` and the canonical CLP
ledger entry are the payload; the bus HANDOFF in step 2 is the doorbell,
now carrying pointers (`artifact=<path> ledger=<clp-id>`) to the local
record.

Check the `local_durability` block in the result. `ledger_verified: false` means
the entry could not be read back from the pinned ledger, and `ledger_error`
means it was not written; either way the bus HANDOFF omits the `ledger=` pointer.
Resolve or name that in the handoff before closing.

If `end_session.py` is unavailable (manual closeout), run directly:
```bash
python ~/.agents/skills/session-close/session_close.py --no-bus \
  --agent <canonical-identity> --vendor <vendor> --model <model> \
  --handoff "<handoff text>" --session <session_id>
```

Origin: 2026-09-12 tailnet outage stranded ~20 bus posts on agent-node — the
canonical ledger is local and append-only, the fleet's real continuity
layer was already there. Local-first ordering matches the session-close
forensic rule: durable writes before any bus marker, so a crash mid-close
leaves maximum evidence.

### 2. Bus Handoff Post
Post a HANDOFF-style STATUS to the coordination bus summarizing:
- What was accomplished this session (bullet points)
- What is still open / in progress — **including any lane named in step 1e**
- Any blockers or alerts for other terminals

The HANDOFF message now includes pointers to the local artifact and ledger
entry written in step 1f (`artifact=<path> ledger=<clp-id>`). The bus post
is a doorbell — the payload is local, written in step 1f. If step 1f
failed, the HANDOFF still posts the full handoff text (without pointers);
the failure is captured in the end-session result under `local_durability`.

`end_session.py` posts through the host's canonical bus writer (`bus-protocol.md`) with `from` = your canonical agent identity.

### 3. Operational Constraints Check
Before posting, check memory for any active constraints (e.g., "no push until billing resets") and include them in the handoff if relevant.

### 4. Memory Update (if warranted)
If the session produced stable patterns, conventions, or constraints worth remembering across sessions, update `MEMORY.md`. Do NOT save session-specific ephemera.

After writing any memory file, verify it landed. Write to **your own runtime's** memory dir, never another runtime's. `~/.agents/scripts/resolve-memory.sh` can supply it as `$RUNTIME_MEM`, but only trust that value if it belongs to your runtime: when it is unset, or names a different runtime's directory, use your runtime's own memory location instead:
```bash
eval "$("$HOME/.agents/scripts/resolve-memory.sh")"
ls -la "$RUNTIME_MEM/<filename>"
```
Memory files are gitignored — disk is the only storage. A missing file means the write failed silently.

### 5. Final Message
Keep it short. One line acknowledging the session is closed.

## Constraints

- READ-ONLY on codebase (no last-minute edits)
- Do not push to remote (check memory for push constraints)
- Do not auto-commit unstaged work
- If user said "good night" or similar, match their tone -- don't be overly verbose
- Bus post is REQUIRED. Memory update is OPTIONAL.

## Skill Chains
- To check for incomplete delegations to other runtimes before closeout -> `[cross-runtime-bridge]` (`python ~/bin/cross_runtime_bridge.py sessions`)

### Mandatory

- None — end-session is the session closer. It IS the final step.

### Advisory

- **Before end-session**: `[commit]` (if there's work to commit), `[session-metrics]` (capture metrics)
- **Bookend partner**: `[start-session]` (run at next session open)
- **Local durability**: `[session-close]` — `end_session.py` calls `session_close.py --no-bus` automatically (step 1f) to write the local ledger entry + handoff artifact before the bus HANDOFF post. The bus post in step 2 carries pointers to the local record.
- **Optional**: `[aar]` (After Action Report) — pass `aar` argument

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (read-only session closer)
- **T3 (Medium)**: May run without restriction (read-only session closer)
- **T4 (Probationary)**: May run (read-only — no destructive actions)
- **Operator**: Override any restriction
