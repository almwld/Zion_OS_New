---
name: evening-touchdown
description: Evening landing sequence -- time-aware twin of morning-kickoff. Day log (UTC-correct for ET), state clean, fleet prep for overnight agents, tomorrow preview. Different from end-session (which is any-time operational closeout).
version: 1.0.0
execution-mode: side_effecting
argument-hint: "[quick | deep | fleet | tomorrow]"
category: fleet-ops
status: candidate
---
## Context Gathering

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=evening-touchdown] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Before executing this skill, gather the following context:
- **Branch**: Run `git branch --show-current 2>/dev/null`
- **Dirty files**: Run `git status --short 2>/dev/null | wc -l | tr -d ' '`
- **Open PRs**: Run `gh pr list --limit 3 --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null || echo "(none)"`
- **Local time**: Run `TZ=America/New_York date "+%Y-%m-%d %H:%M %Z (UTC%z)"`

# [evening-touchdown]

> The pilot's landing checklist. Deliberate, systematic, leaves the aircraft ready for the overnight ground crew.

Evening twin of `[gm]`. Where morning-kickoff asks *"What will I do?"*, evening-touchdown asks *"What did I do, and what should happen while I sleep?"*

**Not a replacement for `[end-session]`** — that's an any-time operational closeout. This is the **end-of-day** ritual: time-aware, fleet-aware, overnight-queue-aware.

**Target time: 7–10 minutes default. 3 minutes in `quick` mode.**

---

## How This Handles Time Zones

The coordination bus stores timestamps in **UTC with Z suffix** (Base4 append-only rule — the bus never changes, only external tools read it). You are in **America/New_York** (EDT = UTC−4 in summer, EST = UTC−5 in winter — DST handled automatically by Python's `zoneinfo`).

**The critical mismatch**: After 8pm EDT (midnight UTC), the UTC date rolls over but your local date hasn't. A naive `grep "2026-04-07"` on bus timestamps would miss everything from 8pm–midnight ET. This skill always computes UTC day boundaries from your local date to catch the full day correctly.

```python
# Always use this pattern for "today" in bus scans:
import datetime, zoneinfo
tz = zoneinfo.ZoneInfo('America/New_York')
now = datetime.datetime.now(tz)
today_start = now.replace(hour=0, minute=0, second=0, microsecond=0).astimezone(datetime.timezone.utc)
tomorrow_start = today_start + datetime.timedelta(days=1)
# today_start through tomorrow_start = all UTC timestamps for "today" in ET
```

---

## Phase 1 — Clock Calibration (~15 seconds)

Establish the correct local/UTC context before any scanning.

```bash
python3 -c "
import datetime, zoneinfo
tz = zoneinfo.ZoneInfo('America/New_York')
now = datetime.datetime.now(tz)
today_start = now.replace(hour=0,minute=0,second=0,microsecond=0).astimezone(datetime.timezone.utc)
tomorrow_start = today_start + datetime.timedelta(days=1)
print(f'Local:          {now.strftime(\"%Y-%m-%d %H:%M %Z\")}')
print(f'UTC now:        {now.astimezone(datetime.timezone.utc).strftime(\"%Y-%m-%dT%H:%MZ\")}')
print(f'Today ET start: {today_start.strftime(\"%Y-%m-%dT%H:%M:%SZ\")} (UTC)')
print(f'Today ET end:   {tomorrow_start.strftime(\"%Y-%m-%dT%H:%M:%SZ\")} (UTC)')
print(f'DST active:     {\"yes (EDT, UTC-4)\" if now.dst().seconds > 0 else \"no (EST, UTC-5)\"}')
"
```

Use `TODAY_UTC_START` and `TODAY_UTC_END` values from this output in all subsequent bus scans.

---

## Phase 2 — Day Log (~90 seconds)

What actually happened today? Read the bus using UTC-correct day boundaries.

```bash
python3 - <<'EOF'
import datetime, zoneinfo, subprocess

tz = zoneinfo.ZoneInfo('America/New_York')
now = datetime.datetime.now(tz)
today_start = now.replace(hour=0, minute=0, second=0, microsecond=0).astimezone(datetime.timezone.utc)
tomorrow_start = today_start + datetime.timedelta(days=1)

start_str = today_start.strftime('%Y-%m-%dT%H:%M:%SZ')
end_str   = tomorrow_start.strftime('%Y-%m-%dT%H:%M:%SZ')

bus_path = str(Path.home() / '.cache' / 'bus' / 'messages.tsv')  # local mirror; use bus-global.py for canonical

milestones = []
statuses   = []
blocked    = []

try:
    with open(bus_path) as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) < 5:
                continue
            ts, frm, to, typ, msg = parts[0], parts[1], parts[2], parts[3], parts[4]
            if ts >= start_str and ts < end_str:
                short = f"[{ts[11:16]}] {frm:<20} {msg[:70]}"
                if typ == 'MILESTONE':
                    milestones.append(short)
                elif typ == 'BLOCKED':
                    blocked.append(short)
                else:
                    statuses.append(short)
except FileNotFoundError:
    print('Bus file not found')
    exit()

print(f"\n=== MILESTONES TODAY ({len(milestones)}) ===")
for m in milestones[-10:]: print(' ', m)

print(f"\n=== STATUS ACTIVITY ({len(statuses)}) ===")
for s in statuses[-15:]: print(' ', s)

if blocked:
    print(f"\n=== BLOCKED (unresolved?) ({len(blocked)}) ===")
    for b in blocked: print(' ', b)

print(f"\nTotal bus entries today: {len(milestones)+len(statuses)+len(blocked)}")
EOF
```

**Interpret:**
- Were the sprint goals advanced? (Check against `_state/cognition/intent.md`)
- Any BLOCKED messages that remain unresolved?
- Anything agents did that you didn't know about?

---

## Phase 3 — Open State Inventory (~90 seconds)

What's sitting open that will create friction tomorrow?

```bash
echo "=== GIT STATE ==="
git status --short | head -20
echo ""
echo "=== BRANCHES NOT MERGED TO MAIN ==="
git branch --no-merged main 2>/dev/null
echo ""
echo "=== OPEN PRs ==="
gh pr list --json number,title,isDraft,headRefName \
  --jq '.[] | "\(if .isDraft then "[DRAFT] " else "" end)#\(.number) \(.title) [\(.headRefName)]"' 2>/dev/null
echo ""
echo "=== ORPHANED SKILL DIRS (untracked) ==="
git status --short -- ~/.agents/skills/ 2>/dev/null | grep "^??" | head -10
echo ""
echo "=== STASHES ==="
git stash list 2>/dev/null | head -5
```

**Decision for each dirty item:**
- Can commit now (clean, tested) → commit it
- WIP that needs more work → stash with descriptive message: `git stash push -m "wip: <description> $(TZ=America/New_York date +%Y-%m-%d)"`
- Orphaned skill dir → register it (index + routing + memory) or note in handoff

---

## Phase 4 — Fleet Readiness (~60 seconds)

Overnight agents run on remote-node (dormant since 2026-07-01 — Workstation is now the primary host). Leave them a clean launch pad.

```bash
# remote-node state (dormant since 2026-07-01 — expected UNREACHABLE)
ssh -o ConnectTimeout=5 mini \
  "cd ~/.agents && echo '--- remote-node git ---' && git status --short | head -10 && echo '--- remote-node services ---' && python3 -m hummbl_governance.services.health 2>/dev/null | tail -4" \
  2>/dev/null || echo "remote-node: unreachable (dormant since 2026-07-01 — expected)"

# Consolidator schedule check — runs at 3AM on remote-node (dormant since 2026-07-01 — expected UNREACHABLE)
ssh -o ConnectTimeout=5 mini \
  "launchctl list | grep consolidator 2>/dev/null && echo 'consolidator: scheduled'" \
  2>/dev/null || echo "consolidator: status unknown"
```

**Remediation if remote-node has dirty state:** (remote-node dormant since 2026-07-01 — this section is N/A)
- ~~If it's trivially committable: `ssh mini "cd ~/.agents && git add -A && git stash push -m 'remote-node-wip-$(date +%Y-%m-%d)'"`~~ (remote-node dormant — skip)
- If it looks important: note it in the handoff for morning

**Fleet readiness matrix:**

| Machine | Check | Status |
|---------|-------|--------|
| Delta (this machine) | `git status --short` | |
| remote-node (dormant) | SSH + git status — expected UNREACHABLE (dormant since 2026-07-01) | |
| Workstation (Windows) | `ssh windows "powershell -Command \"cd $HOME\\.agents; git status --short\""` (if applicable) | |

---

## Phase 5 — Overnight Queue (~60 seconds)

What should agents do while you sleep? This is what neither `[end-session]` nor `[gn]` designs explicitly.

Think through:
- Is there a Codex task that's well-scoped and safe to run overnight?
- Should remote-node's consolidator run on any specific ledger scope? (remote-node dormant since 2026-07-01 — consolidator no longer runs)
- Are there any long-running tests or CI checks to kick off?
- Any research tasks for `[daily-research]` to pre-seed tomorrow?

```bash
# Check if any Codex branches have open work
git branch -a 2>/dev/null | grep "codex" | head -5

# Bus: any BLOCKED from agents waiting for something?
python ~/bin/bus-global.py tail 100 2>/dev/null | grep "BLOCKED" | tail -5
```

**Format for tonight's queue** (include in the bus HANDOFF post):
```
OVERNIGHT QUEUE:
- remote-node consolidator: ~~auto 3AM (standard)~~ — remote-node dormant since 2026-07-01, N/A
- Codex: <task description, or "nothing queued">
- CI: <any workflow to watch, or "nothing pending">
- Notes for morning: <anything unusual>
```

---

## Phase 6 — Tomorrow Preview (~60 seconds)

Look ahead before you close. Morning-you will thank evening-you.

```bash
# Tomorrow's calendar
python3 -c "
from hummbl_governance.integrations.google_calendar_adapter import GoogleCalendarAdapter
import datetime, zoneinfo
tz = zoneinfo.ZoneInfo('America/New_York')
tomorrow = (datetime.datetime.now(tz) + datetime.timedelta(days=1)).strftime('%Y-%m-%d')
try:
    adapter = GoogleCalendarAdapter()
    entries = adapter.get_calendar_entries()
    tomorrow_entries = [e for e in entries if str(e.start_time).startswith(tomorrow)]
    if tomorrow_entries:
        for e in tomorrow_entries:
            print(f'  {e.start_time} {e.title}')
    else:
        print(f'  No calendar entries found for {tomorrow}')
except Exception as e:
    print(f'  Calendar unavailable: {e}')
" 2>&1

# Upcoming deadlines from ledger/memory
python3 -m hummbl_governance.cognition boot 2>/dev/null | \
  grep -i "deadline\|due\|tomorrow\|$(TZ=America/New_York date -v+1d +%Y-%m-%d 2>/dev/null || date -d tomorrow +%Y-%m-%d 2>/dev/null)" | \
  head -8
```

**Key questions:**
1. Any coaching blocks tomorrow that need a clean commit beforehand?
   - Mon/Fri 7:30–9:30am → need to commit tonight or before 7:30
   - Wed 10:30–12:30 → hard stop, don't start something you can't finish by then
2. Any Wave 1 / outreach actions due tomorrow?
3. Any CCA-F study blocks scheduled?

**Write tomorrow's seed intent:**
```bash
TOMORROW=$(TZ=America/New_York date -v+1d +%Y-%m-%d 2>/dev/null || \
           python3 -c "import datetime,zoneinfo; tz=zoneinfo.ZoneInfo('America/New_York'); print((datetime.datetime.now(tz)+datetime.timedelta(days=1)).strftime('%Y-%m-%d'))")

echo "[${TOMORROW}] SEED (written tonight): <tomorrow's ONE THING>" >> \
  /work/active/PSI/_state/intent.md
```

The `SEED` tag distinguishes "written tonight" from "confirmed at GM tomorrow." When `[gm]` runs, it reads the seed and asks: still the right thing? Takes 5 seconds to confirm instead of composing from scratch.

---

## Phase 7 — Bus Handoff (~30 seconds)

The evening-touchdown is not complete until the bus receives a HANDOFF post. This is what overnight agents (~~remote-node consolidator~~ — dormant since 2026-07-01, Codex) read to understand context.

Post HANDOFF to the bus with the evening summary.
```
Type: HANDOFF
To: all
Message: Evening touchdown $(TZ=America/New_York date +%Y-%m-%d). DONE: <bullets>. OPEN: <bullets>. OVERNIGHT: <queue>. TOMORROW: <seed>.
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

**Good handoff has:**
- What moved today (1–3 bullets)
- What's still open (with enough context for an agent to pick up)
- The overnight queue (so consolidator knows what to prioritize)
- Tomorrow's seed (so morning-GM has a starting point)

**Bad handoff:**  `"Wrapped up for the night"` — tells agents nothing.

---

## Output Format

```
Evening Touchdown | <local date> <local time> (<UTC offset>)
═══════════════════════════════════════════════════════════

## Time Context
- Local: <date> <time> EDT/EST
- UTC now: <UTC time>
- "Today" UTC window: <start>Z → <end>Z (captures full ET day)

## Day Log
- Milestones: <count> | <top 3 highlights>
- Bus activity: <N entries>
- Unresolved BLOCKED: <count or none>
- Intent audit: <did THE ONE THING happen? YES / PARTIAL / NO — why>

## Open State
- MBP: <N dirty files — committed / stashed / noted>
- remote-node: <clean | N dirty — action taken | DORMANT since 2026-07-01>
- Open PRs: <list with age>
- Stale branches: <count>
- Orphaned skills: <count or none>

## Fleet Readiness
- remote-node: <READY | NEEDS ATTENTION | DORMANT since 2026-07-01>
- Consolidator (3AM): <scheduled | not found | N/A — remote-node dormant since 2026-07-01>
- Windows: <clean | N dirty | unreachable>

## Overnight Queue
- Codex: <task or "nothing queued">
- CI: <watching / triggered / none>
- Notes: <anything unusual>

## Tomorrow
- First protected block: <time and type>
- Calendar: <meetings or "clear">
- Deadlines in 24–48h: <list>
- Seed intent: <tomorrow's ONE THING draft>

## Handoff Posted
✓ Bus HANDOFF sent at <UTC time>
```

---

## Mode Variants

### `quick` (3 minutes)
Phases 3, 6 (seed only), 7. Skip bus scan, fleet, and overnight queue.
Use when: wrapping up a short work block, not the day's last session.

### `deep` (15 minutes)
All phases plus:
- Full `[aar]` (what worked, what didn't, what surprised)
- Ledger sweep: `[ledger]` any debugging insights > 30 min
- Comprehensive overnight queue with detailed Codex task specs
- Full tomorrow preview with meeting prep for any early calls

### `fleet` (fleet only)
Just Phase 4. Check both machines, prep remote-node (dormant since 2026-07-01 — expected UNREACHABLE), confirm consolidator. Skip all logs, planning, and handoff.
Use when: paranoid that remote-node is in a bad state before sleeping (remote-node dormant since 2026-07-01 — use Workstation instead).

### `tomorrow` (tomorrow preview only)
Just Phase 6. Calendar, deadlines, seed intent.
Use when: mid-session planning session, not an evening close.

---

## Relationship to Other Session Skills

```
[gm]               ←→  [evening-touchdown]
(morning ignition)    (evening landing)

[end-session] = any-time operational closeout (orphan check, git clean, bus post)
              ↑ evening-touchdown CALLS this logic inline in Phase 3

[gn] = personal founder ritual layer (accountability, pipeline log, benediction)
    ↑ runs AFTER evening-touchdown (or standalone when you're tired)
```

Recommended evening sequence when time allows:
1. `[evening-touchdown]` — technical landing (7–10 min)
2. `[gn]` — personal close (3–5 min)

When tired and short on time:
1. `[evening-touchdown] quick` — 3 min
2. Done. The bus has what it needs.

---

## Time Zone Appendix

**Why zoneinfo, not hardcoded offset:**

| Approach | Problem |
|----------|---------|
| `grep "2026-04-07"` on bus | Misses 8pm–midnight ET (already UTC Apr 8) |
| Hardcode UTC-5 | Wrong 6 months of year (EDT is UTC-4) |
| `TZ=America/New_York date +%z` and math | Fragile string parsing |
| `python3 zoneinfo.ZoneInfo('America/New_York')` | Correct, DST-aware, stdlib, zero deps |

The `zoneinfo` module (Python 3.9+, stdlib) reads the system's IANA tz database. `America/New_York` switches between EST (UTC−5) and EDT (UTC−4) at the correct DST transitions — currently EDT from March second Sunday through November first Sunday.

**In bus posts:** Always use UTC with Z suffix regardless of local time. This is the Base4 rule — the append-only log's timestamps are UTC truth. Local time is only for *reading* and *display*, never for *writing* to the bus.

---

## Chain
- State clean issues → `[commit]` or `[conflict-resolve]`
- Fleet unreachable → `[tailscale-status]` then `[tunnel-check]`
- Unresolved BLOCKED in bus → `[incident]` or note for tomorrow
- Overnight Codex task → `[delegate]`
- Tomorrow has an important call → `[meeting-prep]` now
- Full close → follow with `[gn]` for the personal ritual layer
- Monday evenings → follow with `[weekly-review]` before `[gn]`

## Skill Chains

### Mandatory

None — session closer. No pre-chain required; this is the end-of-day landing sequence.

### Advisory

- `[evening-touchdown]` → `[gn]` — follow with the personal accountability ritual
- `[evening-touchdown]` → `[commit]` or `[conflict-resolve]` — if Phase 3 surfaces dirty state
- `[evening-touchdown]` → `[tailscale-status]` then `[tunnel-check]` — if fleet unreachable
- `[evening-touchdown]` → `[delegate]` — if an overnight Codex task is identified
- `[evening-touchdown]` → `[meeting-prep]` — if tomorrow has an important call
- Monday `[evening-touchdown]` → `[weekly-review]` — before `[gn]`

## Authority

- **T1 (TRUSTED)**: Full run — all phases, all modes
- **T2 (Active/High)**: Full run — all phases, all modes
- **T3 (Medium)**: Full run — all phases, all modes
- **T4 (Probationary)**: Full run — all phases, all modes
- **Operator**: Override any restriction
