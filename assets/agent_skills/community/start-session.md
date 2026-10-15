---
name: start-session
description: Disciplined session start. Run at the beginning of any session. Bookend partner to /end-session.
version: 0.6.2
execution-mode: side_effecting
argument-hint: "[optional: COGSTATE CAPACITY 'TRACKS-LIVE']"
category: fleet-ops
status: stable
schema_version: session_start.v1.1.0
providers:
  required: [bash, pytest, python]
  optional: [pwsh(workstation-variant)]
---
# Start Session
Open the current session with state recovery, orphan-resumption checks, last-handoff read, and SESSION_START bus post.

Lighter than `[gm]` (no pipeline/intent/calendar phases). Use for any session start; use `[gm]` instead for full morning launch.

## Working Directory

Run all `git`, `gh`, and shell commands from the fleet repo root (`~/.agents` — the canonical mesh worktree — or the active task worktree). Never assume a package-relative CWD. (The prior canonical repo `hummbl-governance` is archived; `~/.agents` is the live fleet repo on agent-node and Workstation.)

Do NOT use `$HOME/PROJECTS/agents`: on agent-node it is a `core.bare=true` mirror of `~/.agents`, not a worktree — files written there are untracked orphans that can never be committed from that path. Verify with `git rev-parse --is-inside-work-tree` before treating any PROJECTS dir as a worktree. `start_session.py` skips bare mirrors during host-aware repo fallback.

## Usage

```bash
[start-session]                                    # Standard — agent does work
[start-session] AVAILABLE 2h "HUMMBL+JVs"          # + optional cogstate/capacity/tracks
[start-session] --dry-run                          # Dry-run — no bus posts, no side effects

# Runtime flags (start_session.py):
#   --repo <path>       explicit repo path (default: auto-detect)
#   --agent <identity>  canonical bus identity to post as (overrides BUS_AGENT_ID / runtime detection)
#   --weight full|compact|none
#   --dry-run           run all checks without posting to the bus (for testing)
#   --json              emit result as JSON instead of summary text
```

## Procedure

Execute ALL steps in order. Do NOT skip any step. Each step surfaces a concrete finding or confirms clean.

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: host=<machine> [skill=start-session] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
The sender is the caller's canonical identity, resolved by `scripts/bus_identity.py`
(`--agent` flag → `BUS_AGENT_ID` / legacy `DEVIN_AGENT_ID` → runtime markers such as
`CLAUDECODE` / `DEVIN_SESSION_ID` → parent-process name on Linux). There is no default
identity: if nothing resolves, the post is refused, the summary prints
`Bus post FAILED`, and the runtime exits 1. `host=` is resolved from the live machine
(`BUS_ORIGIN_MACHINE` / `MACHINE_ID` / hostname) — the bridge rejects agent posts without it.

### 1a. Inherited Orphaned Git State Check
```bash
git status 2>/dev/null | grep -E "rebase|cherry-pick|bisect|merge" | head -5
find .git -name "*.lock" -mmin +5 2>/dev/null | head -5
```
Surface any orphaned sequencer state OR stale lock files from prior session. If found, resolve BEFORE any new work.

### 1b. Untracked Skill Directories Still Unregistered
```bash
git -C ~/.agents status --short -- skills/ | grep "^??" | head -10
```
Same check as `[end-session]` step 1b. Anything here means last session created a skill and didn't register it. Surface for triage. (`git -C ~/.agents/..` resolved to `$HOME`, not a repo, so the old form always failed silently under `2>/dev/null` — found 2026-09-16. On agent-node `skills-full/` is a gitignored physical store; only `skills/` is tracked.)

### 1c. Uncommitted Work Inherited
```bash
git status --short | head -10
```
Surface what was in flight at last close. Ask operator: resume this, stash, or revert? Do not auto-commit.

> **Do NOT filter with `grep -E "^[MADRCU]"`.** `git status --short` output is `XY <file>`
> (2-char status code: X=index/staged, Y=worktree). `^[MADRCU]` matches only column 1
> (staged changes) and silently misses ` M` (unstaged worktree modification), ` D`
> (unstaged deletion), etc. — producing a false "clean" result. Show raw output capped
> at 10 lines and let the agent+operator triage. (Origin: 2026-08-18 AAR — false "clean"
> SESSION_START bus post when 2 unstaged tracked files existed.)

> **Positive verification before posting "clean" to bus.** Before posting
> "Inherited: clean" or "no uncommitted" to the durable bus, run a positive
> line-count check: `(git status --porcelain | wc -l) -eq 0` (PowerShell:
> `(git status --porcelain).Count -eq 0`). Empty grep output is NOT
> verification — it can mean the command failed, the regex missed the format,
> or the path was wrong. State-claims on the durable bus require positive
> verification, not inference from empty output. (Origin: 2026-08-18 AAR —
> generalizes the 2026-08-13 file-existence pin to state-claims.)

### 1c2. Untracked File Age Drift
```bash
git ls-files --others --exclude-standard | while IFS= read -r f; do
  age_days=$(( ($(date +%s) - $(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f")) / 86400 ))
  [ "$age_days" -gt 1 ] && echo "$age_days days old: $f"
done | head -5
```
Surface untracked files >1 day old. Same orphans `[end-session]` flagged at last close are now older. Either still useful (commit/move) or stale (delete). Triage NOW, not at next close.

### 1d. Stale Open Issues (carry list)
```bash
gh issue list --state open --limit 20 --json number,title,createdAt,comments \
  --jq '.[] | select((.comments | length) == 0) | "#\(.number) \(.createdAt[:10]) \(.title)"'
```
Same query as `[end-session]` step 1d. Carry the awareness list into this session. Operator can `[issue-triage]` if any are now actionable.

### 1d2. CRAB Branch Verification (repo work gate)
```bash
echo "CRAB: branch=$(git branch --show-current 2>/dev/null) stash=$(git stash list 2>/dev/null | wc -l) status=$(git status --short 2>/dev/null | wc -l) ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo '?')"
```
**Before any git operations or file modifications**, verify the current branch
matches the intended target. This is the CRAB (Context Before Action) branch gate.

**Warning conditions** (surface to operator before proceeding):
- Current branch is NOT `main` and operator has not explicitly requested a
  feature branch — this is how the `docs/gap-7-branch-protection` vs `main`
  error occurred (committed to a feature branch instead of main).
- Stash count > 0 — inherited stash may conflict with planned work.
- Status count > 0 and branch is not the intended target — uncommitted work
  on the wrong branch.

**If branch is wrong**: ask operator to confirm the target branch before any
`git add`, `git commit`, or file modifications. Do NOT auto-switch branches
with uncommitted work present.

Origin: AAR 2026-09-02 — session committed to `docs/gap-7-branch-protection`
instead of `main` because no explicit branch check was performed before staging.

### 1e. Fleet-Wide Orphaned WIP Lanes (awareness-only)
```bash
python $HOME/.agents/scripts/check-orphaned-wips.py
```
Fleet-wide, not filtered to self — surfaces lanes any agent left open, most
relevant when picking up work another session started. Do not close another
agent's lane without either their explicit handoff or operator direction.
This is awareness, not action — same posture as step 1d.

### 1f. Active Agent Work Detection (concurrent vs inherited)
```bash
# Local agent processes (excluding self)
ps aux | grep -iE "devin|codex|claude|opencode|gemini" | grep -v grep | grep -v "chrom\|browser"
# Recent bus activity (last 15 min)
python $HOME/bin/bus-global.py tail 100 | head -20
# Repo-level activity gate (v0.5.0): git reflog, last commit, branch ahead/behind
git reflog show HEAD --format="%gd|%ct" -5
git log -1 --format=%ct
git rev-list --left-right --count HEAD...@{upstream}
```
Distinguish concurrent agent work from inherited state left by a closed
session. Origin: 2026-09-01 — start-session labeled all git state as
"Inherited from last close" even when 4+ devin sessions were actively
running on the same machine, causing confusion about whether uncommitted
files were orphaned or in-progress.

Classification:
- **concurrent**: active local agent processes OR 2+ agents recently
  posted to the bus. Working-tree changes are likely in-progress, not
  inherited orphans. Do NOT auto-stash or auto-commit.
- **ambiguous**: no local processes, but 1 agent recently active on bus.
  Changes could be from a remote agent or a recently-closed session.
- **inherited**: no active processes, no recent bus activity. Changes are
  genuinely left over from a closed session — treat as orphans.

**Repo-level activity gate** (v0.5.0, 2026-09-02): When git reflog or
last commit is <30 min old, the classification is refined:
- "inherited" + recent git activity → "ambiguous" (git mutations suggest
  work happened recently even if no process/bus activity is visible)
- "ambiguous" + recent git activity → "concurrent" (git confirms the
  bus signal)
- "concurrent" is never downgraded by repo signals (process/bus are
  stronger signals than git metadata)

This reduces false positives where mtime-only classification (step 1g)
labels inherited files as "recent" because a crashed session wrote them
25 minutes ago. Git reflog records actual git operations (commit,
checkout, reset, rebase), which require an active agent to perform.

This also refines INCOMPLETE_CLOSE detection: if the end-session
SKILL_INVOKE was very recent (<5 min) and concurrent work is detected,
downgrade to POSSIBLY_ACTIVE_CLOSE — the session may still be actively
closing, not crashed mid-close.

### 1g. File Recency Classification (mtime-based)

Each uncommitted and untracked file is classified by modification time:
- **recent** (modified <30 min ago): possibly active work — another agent
  may be writing to this file right now
- **stale** (modified >30 min ago): likely inherited from a closed session

This complements the tree-level classification from step 1f. Even when the
tree is "concurrent", some files may be genuinely stale orphans mixed in
with active work. And when the tree is "inherited", some files may have
been touched very recently by a process that just exited.

The summary splits file listings into "Possibly active" and "Stale
(inherited)" subsections so the operator can see at a glance which files
are likely being worked on right now vs which are leftover orphans.

Untracked files that are too recent for AGED_UNTRACKED_CANDIDATES (<1 day
old) are also surfaced in a separate "Untracked (not aged)" section with
the same recency split.

### 2. Read Last HANDOFF
First, read the last `[end-session]` HANDOFF from the bus:
```bash
python $HOME/bin/bus-global.py tail 200 2>&1 | grep -E "HANDOFF|end-session|END-SESSION|SESSION_START" | tail -3
```
Surface: what was accomplished, what's open, any blockers flagged for this session.

Refresh the SKILL metadata health once per session:
```bash
# Windows (Workstation) — PowerShell script with Task Scheduler telemetry
pwsh -NoProfile -ExecutionPolicy Bypass -File $HOME/bin/skill-health.ps1
# Linux (Delta) — Python port (auto-detected by start_session.py capability discovery)
python $HOME/bin/skill-health.py --persist
```

> **2-strike bus search heuristic.** When searching the bus for a specific
> artifact (tool, file, workaround), if 2 grep passes with different
> patterns return no relevant hits, pivot to filesystem listing before a
> 3rd grep. The bus records agent activity, not filesystem state — a file
> created without a bus post is invisible to bus search regardless of how
> many patterns you try. (Origin: 2026-09-02 AAR — 4 bus grep passes
> wasted before `ls ~/bin/skill-health*` found the Python port in 1
> command.)

### 2a. Resolve Daily Cogstate

Parse optional arguments before posting `SESSION_START`. If the current invocation
provides a valid Cogstate, it wins. Otherwise resolve from the live bus:

```bash
python $HOME/bin/bus-global.py cogstate --json
```

On Windows PowerShell:

```powershell
python $HOME/bin/bus-global.py cogstate --json
```

This reads from the live hummbl-vps bridge (with mirror fallback) and resolves
the operator's current cogstate from today's HRSI_CHECKIN, SESSION_START, or
HYPERFOCUS transition posts. Any agent on any machine can run this at any time —
not just start-session.

Pass `--explicit <STATE>` when the current invocation declares Cogstate. The resolver:
- accepts only `AVAILABLE`, `HYPERFOCUS`, `DEPLETED`, `RECOVERY`, `TRANSITION`, `RSD_RISK`, or `SHUTDOWN`;
- inherits the latest valid declaration or transition from the current New York calendar day;
- ignores `not declared`, malformed values, and unscoped prose mentions;
- resolves to the latest same-day cogstate post's own timestamp as `declared_at` (it does NOT parse or preserve an original declaration timestamp across echoes — each SESSION_START echo becomes a fresh candidate);
- expires inherited state at local midnight.

> **Architecture note**: `bus-global.py cogstate` is the fleet-wide cogstate query.
> It reads from the live bridge, not stale local files. The prior approach (reading
> a local TSV) broke when the bus moved to remote-first (hummbl-vps bridge) — local
> mirrors go stale between syncs and miss same-day posts. (Bug origin: 2026-08-15,
> resolver returned `NOT_DECLARED` despite a same-day HRSI_CHECKIN because it read a
> stale local TSV.)

Capacity and tracks remain current-invocation inputs; do not inherit them automatically.

### 2b. Post SESSION_START

Post SESSION_START to the bus using the resolved state and provenance:
```
Type: STATUS
To: all
Message: host=<machine> [lane=ops/<agent>/session-start-<timestamp>] [cogstate=<STATE|NOT_DECLARED>] [cogstate_source=<operator|inherited|none>] [cogstate_declared_at=<timestamp|none>] [session_id=<stable session id>] SESSION_START. Inherited: <orphans|clean>. Resuming: <what>. Cogstate: <STATE + provenance, or 'not declared'>.
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

`SESSION_START` is functionally the bookend to `[end-session]`'s HANDOFF post.

The runtime checks the bridge response. On success the summary prints
`Bus posted: SESSION_START at <ts> (request_id=… accepted_at=…)`; on rejection it prints
`Bus post FAILED: SESSION_START at <ts> — <bridge error>` and exits 1. Never report a
session as started from the FAILED line — fix the cause or post by hand, then read the
canonical log back (`bus-global.py tail 5 --plain`).

> **WIP_START for consequential work.** If this session will perform
> consequential shared-state work (PR creation, branch mutations, mass file
> changes, bus protocol changes), post a `WIP_START` with a lane claim
> BEFORE starting the work — not just a `STATUS` after it's done. This
> lets other agents detect the lane claim via `check-orphaned-wips.py`
> and prevents duplicate work. Format:
> ```
> Type: STATUS
> To: all
> Message: host=<machine> [lane=ops/<agent>/<work-description>] WIP_START: <what will be done>
> ```
> Post `WIP_END` when the work is complete. (Origin: AAR 2026-09-02 —
> multi-agent session registry work posted STATUS after PR creation but
> no prior WIP_START, so the lane was never tracked by check-orphaned-wips.)

> **Multi-File Planning Checkpoint Self-Check (Doc-Creation Protocol).** If this
> session plans to draft or generate a sequence of 3+ files (e.g. multi-part plans,
> megaplans, or research document suites), apply the doc-creation checkpoint
> self-check: set a file counter and post a bus `STATUS` every 2–3 files.
> Concrete example: drafting 5 megaplan files requires posting a bus `STATUS`
> after file 2 and file 4. This is a behavioral discipline ensuring multi-file
> work remains visible and observable across the fleet without long silent gaps.


### 2c. Model API Funding

Know which model APIs have money before routing paid work. Session start shows
the cached funding report; refresh it with provider keys loaded:

```powershell
# Workstation (keys live in Windows Credential Manager)
. $HOME\bin\secret-loader.ps1
python skills/start-session/scripts/api_funding.py --refresh
```
```bash
python skills/start-session/scripts/api_funding.py            # read cache only
```

The report groups providers as **Funded** (with USD balance), **Works, balance
not exposed by API**, **Not funded**, **Broken key**, and **Key not loaded on
this host**, and flags balances under $2 and reports older than 24h. It is
cached at `~/.agents/_state/api-funding.json`; `start_session.py` reads it
without network or keys.

Rules:
- Probes are read-only GETs (model list + balance endpoint). Never print a key,
  a raw response body, or an account id.
- Anthropic is not probed (API-key use needs an admitted proposal). Gemini is
  not probed (Gemini is used through the agy CLI only).
- Do not route paid work to a provider listed as Not funded or Broken key.
  Surface top-ups or key rotation to the operator.

### 3. Load Active Operational Constraints
Read memory for any active constraints that gate this session. Use the runtime
memory resolver so each runtime reads its own memory + the canonical fleet index
(not a hardcoded `.claude` path — see `pointer-manifest.yaml`):
```bash
eval "$("$HOME/.agents/scripts/resolve-memory.sh")"
grep -lE "no push|frozen|hold|do not|paused|blocked" ${RUNTIME_MEM:+$RUNTIME_MEM/*.md} "$FLEET_MEM" 2>/dev/null | head -5
```
PowerShell: `$m = & "$HOME\.agents\scripts\resolve-memory.ps1"; $FleetMem = ($m|?{$_-match'^FLEET_MEM='})-replace'^FLEET_MEM=',''; $RuntimeMem = ($m|?{$_-match'^RUNTIME_MEM='})-replace'^RUNTIME_MEM=',''`
Surface any constraint that would affect today's work (e.g., "no push until billing resets", "Christine pilot frozen until Monday", "codex rate-limited until X").

### 4. Surface Relevant Memory Pins
Pins changed in last 24h OR matching current branch context:
```bash
eval "$("$HOME/.agents/scripts/resolve-memory.sh")"
[ -n "$RUNTIME_MEM" ] && find "$RUNTIME_MEM/" -name "*.md" -mtime -1 2>/dev/null | head -10
BRANCH=$(git branch --show-current 2>/dev/null)
[ -n "$BRANCH" ] && grep -lE "$(echo "$BRANCH" | sed 's/[^a-zA-Z0-9]/ /g' | awk '{print $NF}')" ${RUNTIME_MEM:+$RUNTIME_MEM/*.md} "$FLEET_MEM" 2>/dev/null | head -5
```
Pre-load context the agent will need. Skim them silently if relevant; surface paths only if uncertain.

### 5. Cogstate Calibration
Apply the resolved Cogstate, whether explicit in this invocation or inherited from today's declaration:
- **AVAILABLE** → full execution, all skills
- **HYPERFOCUS** → aggressive parallelism welcome
- **DEPLETED** → no major commits / no irreversible decisions / read-only preferred
- **RECOVERY** → standdown / HULE-only
- **TRANSITION** → ~15min capacity / closeout-only

CAPACITY guides scope sizing (don't propose 3hr build for ~30min capacity).
TRACKS-LIVE bounds today's work — surface scope-creep if request lands outside.

If resolution returns no valid state, report `not declared` and skip calibration. Never let a
later `not declared` session overwrite a valid same-day declaration.

Posts `SESSION_START` to the bus, then renders a bounded summary.

> **Resolve `host=` from the live machine, NOT the prior HANDOFF.** The prior
> session's `host=` tag may have been posted from a different machine (sessions
> move between hosts). Resolve the current machine identity before posting:
> ```bash
> # Unix
> echo "${MACHINE_ID:-$(hostname)}"
> ```
> ```powershell
> # Windows PowerShell
> $env:MACHINE_ID; hostname
> ```
> Map the raw hostname to a canonical host tag (`workstation`, `delta`, `huxley`,
> `remote-node`, `remote-node`, `unknown`) — these are the only values `bus-global.py
> _validate_host_tag` accepts. `bus-global.py` derives the same value from
> `BUS_ORIGIN_MACHINE` env or `socket.gethostname()` and auto-appends
> `machine=<origin>`; if your `host=` disagrees with that auto-appended
> `machine=`, the post emits a WARN and the durable log carries conflicting
> provenance. (Origin: 2026-08-18 — SESSION_START copied `host=agent-node` from the
> prior HANDOFF onto a machine whose `ORIGIN_MACHINE=workstation`; the WARN was
> incorrectly dismissed as expected.)

### 6. Final Summary
Render output in this shape:
```
[start-session] | <date> <time>
══════════════════════════════════════════

Active agent work: <CONCURRENT|AMBIGUOUS|none (inherited)> — <reason>
  <local processes + recent bus activity if concurrent>

Working tree state (<concurrent|inherited|ambiguous>):
- <orphans/uncommitted/stash status>
- <untracked-aged>

Last HANDOFF: <ts> — <one-line>
Open carry: <PRs, issues, items>
Active constraints: <list or "none">

Cogstate: <resolved state + explicit/inherited provenance, or "not declared">
First action: <concrete next step based on inherited state + chat context>

---
Bus posted: SESSION_START at <ts> (request_id=<bridge id> accepted_at=<ts>)
   -- or, on rejection --
Bus post FAILED: SESSION_START at <ts> — <bridge error>
```

## Output Schema

The SESSION_START bus post emitted at step 2b is a versioned contract:
`docs/schemas/bus/session_start.v1.md` in the agents repo
(`schema_version: session_start.v1.1.0`). Field definitions, allowed values,
consumer list, and versioning rules live there — do not modify the message
shape or semantics in this file without bumping the schema. Consumers include the
`bus-global.py cogstate` resolver, the same-session suppression check,
`end-session` (bookend), `sitrep`, and `goal-selection`.

Best-effort duplicate suppression requires the same canonical sender, explicit
canonical host and stable `[session_id=...]` within 300 seconds. Sender and host
comparisons ignore case; session IDs are case-exact. The registry-provided session
ID is separate from the timestamp-based SKILL_INVOKE `[session=...]` identifier.
Missing, unknown, duplicate or conflicting identity, legacy invocation-only
metadata, and unsupported envelopes do not suppress a new start. A matching
`machine=` tag can corroborate host but cannot supply a missing host. This remains
non-atomic and does not replace worktree coordination or establish session liveness.

## Constraints

- READ-ONLY on codebase (no edits before operator directs action)
- Bus post is REQUIRED
- Do not auto-resolve inherited orphans without operator OK
- Do not load memory file contents in bulk — surface paths, skim silently
- If operator said "GM" or "good morning", prefer `[gm]` (superset with pipeline + intent)
- Keep output under 25 lines unless inherited state requires more

## Relationship to other skills

- **`[end-session]`** — bookend partner. SESSION_START closes the loop HANDOFF opened.
- **`[gm]`** — morning superset. Includes [start-session] work + pipeline + intent A/B/C + HRSI + calendar.
- **`[sitrep]`** — adjacent. [sitrep] is task-scoped state; [start-session] is session-scoped open.
- **`[apex] orient`** — agent-side counterpart for task-level recon; [start-session] is session-level open.

## When to skip

- Continuation of same active session (no real gap)
- Trivial single-question lookup
- Operator typed `[gm]` instead (gm covers this work)

## When to use

- Any session start after >1hr gap
- Post-interrupt resume (rate-limit, crash, reboot)
- After `[end-session]` was posted in prior session
- Sprint kickoff (with optional cogstate arg)

## Skill Chains
- For check for active opencode delegations during session start -> `[cross-runtime-bridge]` (`python ~/bin/cross_runtime_bridge.py sessions`)

### Mandatory

- None — start-session is the session opener. It IS the precondition for other skills.

### Advisory

- **After start-session**: `[gm]` (if morning), `[sitrep]` (if resuming incident), `[goal-selection]`
- **Bookend partner**: `[end-session]` (run at close)

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (read-only session opener)
- **T3 (Medium)**: May run without restriction (read-only session opener)
- **T4 (Probationary)**: May run (read-only — no destructive actions)
- **Operator**: Override any restriction

## Changelog

### v0.6.2 (2026-09-20)
- Scope the restart guard to matching canonical sender, explicit host and stable
  session ID instead of globally suppressing every same-sender start for five
  minutes. Distinct hosts/sessions are admitted; incomplete or ambiguous identity
  fails open. Preserve the 300-second window and bounded 5-second future tolerance.
- Require an exact STATUS type and structural SESSION_START event, excluding
  diagnostic substrings and duplicated identity fields. Pass the existing registry
  identity without changing registry behavior, sender identity or worktree guards.
- Bump the contract to session_start.v1.1.0 for these semantics. Old rows and the
  v0.2.1 history remain intact; no bus or cache migration is required.
- Fix `quote_for_bus` to relabel quoted `session=`/`session_id=` tags as
  `source_session=`/`source_session_id=`. Without this, the `Resuming:` snippet
  carried the predecessor HANDOFF's `[session=...]` into the new row and the
  identity scan rejected every bookended start — suppression was a silent no-op
  (found by grok-build review 2026-09-20).
- Session-start burst classification (`detect_session_start_burst`,
  `SessionStartBurst`/`SessionStartEvent`): recent `[skill=start-session]`
  SKILL_INVOKEs inside a 300s window are classified per event as `completed`
  (SESSION_START bookend found), `yielded_collision` (SESSION_COLLISION
  posted), or `possibly_starting` (no bookend yet — may still be opening or
  was killed before posting). Origin: 2026-09-20 operator directive —
  multiple session starts in a short burst are normal concurrent fleet
  activity and must not be flagged as an anomaly; a second start-session
  SKILL_INVOKE on agent-node with no visible SESSION_START was initially
  misclassified as a died-mid-run anomaly. Semantics mirror
  POSSIBLY_ACTIVE_CLOSE on the close side. The current session's own invoke
  is excluded (its SESSION_START isn't posted yet at detection time), and
  SESSION_COLLISION bodies are matched before SESSION_START because they
  quote the latter. Suppressed on stale-mirror bus reads like
  INCOMPLETE_CLOSE. The 60s same-branch+host collision yield is unchanged.
  Renders as a bounded "Start-session burst" diagnostic in the summary.
  Tests in `tests/test_session_start_burst.py`.

### v0.6.1 (2026-09-17)
- Bus post results are now authoritative for the summary. The SESSION_START
  post's return value was discarded and SKILL_INVOKE failures were never
  rendered, so the summary always printed `Bus posted: SESSION_START at <ts>`.
  On 2026-09-17 (Workstation) the bridge rejected both posts (missing `host=` tag
  under a stale v0.3.3 runtime copy) while the summary claimed success. Now:
  success lines carry the bridge `request_id`/`accepted_at`; a rejection prints
  `Bus post FAILED: …` with the bridge error and `main()` exits 1; the result
  dict exposes `bus_post_failed`, `session_start_post_ok/_error/_receipt`,
  `invoke_post_ok/_error`. 18 tests in `tests/test_bus_post_receipt.py`.
- Added `--agent <canonical>` (validated against `CANONICAL_BUS_IDENTITIES`,
  overrides `BUS_AGENT_ID`); unresolved identity is now visible as a FAILED
  line instead of a silent non-post.
- Carried Workstation-local patches (2026-09-16) into the canonical version: host-aware
  repo fallback tries `agents` after `apex-nexus` and skips `core.bare=true`
  mirrors (`_is_bare_repo`); Working Directory bare-mirror warning; step 1b
  command fixed (`git -C ~/.agents/..` resolved to `$HOME`); `## Output Schema`
  section; runtime-flag block in Usage; `schema_version` frontmatter.
- `SKILL_VERSION` constant was still `0.4.0` while the doc said 0.6.0; both are 0.6.1.
- Quoted predecessor text is sanitised before embedding (`quote_for_bus`): the
  `Resuming:` snippet copied the last HANDOFF verbatim, including its `host=`
  tag, and the bridge rejected the SESSION_START as "Conflicting provenance
  tags" whenever the predecessor closed on another machine (Workstation quoting a
  Delta close, 2026-09-17). Quoted `host=`/`machine=` become `source_host=`/
  `source_machine=`; whitespace is collapsed so tabs cannot split the TSV row.
- The GitHub auth gate result is now printed (`GitHub auth: OK|FAILED — …`);
  before, a wrong active `gh` account made the runtime exit 1 with no line
  explaining why. `EXPECTED_GH_USER` is now a comma-separated allowlist defaulting
  to `hummbl-io,hummbl-dev` — the shared fleet push account is `hummbl-dev`, so
  every Workstation session was failing that gate.
- `status: stable` (2026-09-15 audit recommendation, carried from the 2026-09-16
  local edit): 570+ tests, live fleet usage, bookend pair shipped.

### v0.6.0 (2026-09-15)
- Added step 2c, Model API Funding. New `scripts/api_funding.py` probes each
  provider key (read-only), classifies funded / not funded / broken key /
  balance not exposed, and caches the result at `~/.agents/_state/api-funding.json`.
  `start_session.py` renders the cached report in the summary without network
  or keys; a missing or corrupt cache never breaks session start.
  (Origin: 2026-09-15 operator directive — every agent should know how much
  usage we have on every API. First probe found Moonshot and OpenRouter out of
  credit and an invalid xAI key.)

### v0.5.0 (2026-09-02)
- Added repo-level activity gate to step 1f: `detect_repo_activity()`
  collects git reflog recency, last commit age, and branch ahead/behind
  signals. These complement the process/bus detection with git-metadata
  signals that are harder to produce false positives.
- `classify_working_tree_state()` now accepts an optional
  `RepoActivitySignals` parameter. When git reflog or last commit is
  <30 min old, the classification is refined: "inherited" → "ambiguous",
  "ambiguous" → "concurrent". "concurrent" is never downgraded.
- New dataclass `RepoActivitySignals` with `has_recent_git_activity`
  and `has_unpushed_commits` properties.
- New function `detect_repo_activity(repo_path)` — fail-open: if git
  commands fail, signals are skipped (not errors).
- Origin: 2026-09-02 skills-factory assessment (repo-activity-gate).
  Routed through Phase -1/0/1 pipeline. Outcome: EXTEND_EXISTING.
  The mtime-only classification in v0.4.0 produced false positives
  (files classified "recent" were inherited from crashed sessions
  because mtime doesn't distinguish "agent is writing" from "agent
  wrote then died"). Git reflog records actual git mutations, which
  require an active agent to perform.
- Fixed malformed sed expression in step 4 branch-pin search:
  `sed 's/[^a-zA-Z0-9]/ [g]'` → `sed 's/[^a-zA-Z0-9]/ /g'`. The `[g]`
  was a literal character class, not the global flag. (Origin: 2026-09-02
  AAR — pre-existing typo caused "unterminated 's' command" on agent-node.)
- Added 2-strike bus search heuristic after step 2: if 2 grep passes
  fail, pivot to filesystem listing. (Origin: 2026-09-02 AAR.)
- TODO [LOW]: Add CI lint check for bash snippets in SKILL.md files —
  run each `sed`/`awk`/`grep` pipeline against sample input to catch
  syntax errors before they surface at runtime.

### v0.4.0 (2026-09-01)
- Added Active Agent Work Detection (step 1f): distinguishes concurrent
  agent work from inherited state left by a closed session. Scans local
  process table for running devin/codex/claude-code/opencode/gemini
  processes (excluding self via parent-PID chain) and recent bus activity
  (15-min window) to classify working-tree state as "concurrent",
  "ambiguous", or "inherited". Origin: 2026-09-01 — start-session labeled
  all git state as "Inherited from last close" even when 4+ devin sessions
  were actively running on the same machine, causing confusion about
  whether uncommitted files were orphaned or in-progress.
- Added File Recency Classification (step 1g): splits individual
  uncommitted/untracked files by mtime into "recent" (<30 min, possibly
  active) vs "stale" (>30 min, inherited). Complements the tree-level
  classification — even in a "concurrent" tree, some files may be stale
  orphans. Also surfaces recent untracked files that fall through the
  AGED_UNTRACKED_CANDIDATES filter (<1 day old) with recency split.
- INCOMPLETE_CLOSE refinement: when concurrent work is detected and the
  end-session SKILL_INVOKE was <5 min ago, downgrades to
  POSSIBLY_ACTIVE_CLOSE — the session may still be actively closing.
- Summary header changed from "Inherited from last close:" to
  "Working tree state (concurrent|inherited|ambiguous):" with an
  "Active agent work:" line above it showing the classification.
- File listings in summary now split into "Possibly active" and
  "Stale (inherited)" subsections when file_recency is available.
- SESSION_START bus post now includes `[active_agents=Nlocal+Mbus]` and
  `[work_classification=concurrent|ambiguous]` fields.
- First action logic updated: when concurrent work is detected with
  working-tree changes, advises verifying with active agents before
  acting (prevents auto-stash/auto-commit of in-progress work).

### v0.3.1 (2026-08-18)
- Step 6 provenance resolution block: resolve `host=` from the live machine
  (`MACHINE_ID` env / `hostname`), not the prior HANDOFF. Names the canonical
  host set accepted by `bus-global.py _validate_host_tag`. Catches the failure
  mode where a session moves between hosts and the agent copies the prior
  `host=` tag forward, producing conflicting provenance in the durable log.
  (Origin: 2026-08-18 — SESSION_START copied `host=agent-node` onto a machine whose
  `ORIGIN_MACHINE=workstation`; the bus WARN was incorrectly dismissed as expected.)

### v0.3.0 (2026-08-03)
- Added trust-bounded daily Cogstate inheritance, including STATUS-form HRSI declarations.
- Preserved direct operator/Steward provenance across inherited SESSION_START echoes.
- Rejected untrusted operator claims and future declaration timestamps.
- Restored the documented PowerShell launcher and aligned dry-run documentation with runtime.

### v0.2.2 (2026-07-19)
- Bus staleness detection (gap-based fallback): `detect_bus_staleness()` flags `STALE_BUS` when no bus activity from any agent for >72h (configurable via `STALE_BUS_GAP_THRESHOLD_HOURS`). Skips entries within the current session window (300s) to avoid counting this session's own posts. Catches the failure mode where no `end-session` SKILL_INVOKE exists (so INCOMPLETE_CLOSE can't fire) but the bus went silent while work continued via direct git commits. Surfaces "Bus staleness: STALE_BUS" diagnostic line + "Last real bus activity" timestamp in summary.
- Handoff artifact verification: `verify_handoff_artifact()` extracts the `.md` path from the last HANDOFF message and checks `os.path.exists` against home dir and repo root. Surfaces "Handoff artifact: EXISTS" or "Handoff artifact: MISSING" in summary. Catches path drift (bus references path X, artifact written to path Y) and artifacts that were never written. Cross-platform: normalizes Windows backslash paths to forward slashes.
- First-action logic extended: STALE_BUS and missing handoff artifact now produce actionable first-action guidance.
- 18 new tests (total 131): 8 for staleness detection (threshold boundaries, session-window skipping, empty bus, no timestamps), 9 for artifact verification (path extraction with forward/backslash, existence check relative to home/repo, missing artifact, no path in message, absolute path), 1 for PredecessorSession extended field defaults.

### v0.2.1 (2026-07-15)
- Home-directory repo guard: skips `ls-files` scan when repo root == `$HOME`/`$USERPROFILE`. Platform-aware home selection (USERPROFILE on Windows, Path.home() on Unix). Uses `os.path.samefile()` for filesystem-identity comparison (catches case, symlinks, junctions) with `normcase(realpath())` fallback for nonexistent paths. A repo under home but not equal to home returns False.
- SESSION_START best-effort suppression: checks bus tail for a recent SESSION_START from the same actor within 5-minute window before posting. **NOT atomic deduplication** — concurrent agents can both check and both post. Reduces accidental sequential duplication from crash-retry loops only. Limitations documented in docstring: non-atomicity, tail truncation, actor aliasing, clock skew.
- Bounded clock-skew tolerance: 5-second tolerance for future timestamps. Timestamps 1-5s in the future are matched; beyond tolerance produces a bounded anomaly diagnostic line in the summary (no bus event).
- Bus-read result integrity: `bus_tail()` returns `BusTailResult(lines, succeeded, error)` — distinguishes read failure from empty success. Suppression check status states: `not_run` (dry-run), `read_failed` (fail-open), `checked_no_match`, `checked_match`. Fail-open: when bus read fails, SESSION_START posts normally with "suppression check SKIPPED" in summary.
- Centralized timestamp parsing: `parse_bus_timestamp()` accepts Z suffix and explicit ISO 8601 offsets (`+00:00`, `-04:00`), normalizes to UTC, rejects naive timestamps (out of bus contract), rejects malformed without crashing.
- SKILL_INVOKE invariant: always fires regardless of suppression state, bus-read failure, or normal operation. Verified by runtime integration tests (dry_run=False, mocked externals).
- `run_git` timeout now configurable (default 30s); `ls-files` call uses 120s budget.
- 113 tests (up from 74 — added coverage for home-dir guard, suppression, timestamp parsing, clock-skew tolerance, SKILL_INVOKE invariant, bus-read failure, offset timestamps)

### v0.2.0 (2026-07-14)
- Cross-platform Python implementation (`start_session.py`) replacing bash-first procedure
- Thin shell entrypoints (`run.sh`, `run.ps1`) delegating to Python
- SKILL_INVOKE first-event invariant with LATE_SKILL_INVOKE violation marker
- INCOMPLETE_CLOSE detection (predecessor session correlation)
- Repo resolution: current repo vs governance repo distinction
- Structured-first constraint discovery (issues → bus → memory fallback)
- AGED_UNTRACKED_CANDIDATES classification (not "orphans" without evidence)
- Capability discovery for skill-health dependency (no hardcoded path)
- Machine-safe bus parsing via `--plain` flag on `bus-global.py tail`
- 154 tests covering Windows, Bash, late invoke, incomplete close, repo mismatch, active-constraint detection, handoff artifact verification, issue state drift

### v0.1.0
- Initial bash-first implementation

## Configuration

| Env var | Default | Purpose |
|---------|---------|---------|
| `BUS_AGENT_ID` | (none) | Canonical bus identity to post as (`claude-code`, `codex`, `devin`, `agy`, `gemini`, `opencode`, `hermes`, `kai`, `pi`, `grok-build`). `--agent` overrides it; legacy `DEVIN_AGENT_ID` is honoured. No default — unresolved identity refuses to post. |
| `BUS_ORIGIN_MACHINE` / `MACHINE_ID` | hostname | Canonical `host=` value for the SKILL_INVOKE and SESSION_START posts (`workstation`, `delta`, `huxley`, `remote-node`, `remote-node`, `remote-node`, `hummbl-vps`, `unknown`). |
| `START_SESSION_FILE_RECENCY_MINUTES` | `30` | Files modified within this many minutes of "now" are classified as "recent" (possibly active work). Files older are "stale" (inherited). Set to `5` for fast-iteration workflows, `60` for long-running agents. |
