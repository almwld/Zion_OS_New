---
name: weekly-plan
description: Forward-looking week allocation. Sets THE ONE THING per day, maps sprint goals to days, writes seed intents. Twin of weekly-review (backward) -- this is forward.
version: 1.0.0
execution-mode: side_effecting
argument-hint: "[week of YYYY-MM-DD | this | next]"
category: fleet-ops
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Sprint goals**: Run `cat /work/active/PSI/_state/intent.md 2>/dev/null | tail -10`
- **Open PRs**: Run `gh pr list --limit 3 --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null || echo "(none)"`
- **Branch**: Run `git branch --show-current 2>/dev/null`

# [weekly-plan]

> You can't hit a week you haven't aimed at. This is the aim.

The forward-looking twin of `[weekly-review]`. Where review asks "what happened?", plan asks "what will happen — and have I made the commitments to make it so?"

**Run on Monday morning, after `[gm]` and before opening any file.**

## When to Use
- Monday morning (primary)
- After a disrupted week when you need to reset
- When sprint goals and available days are misaligned

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=weekly-plan] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Load constraints (what's fixed this week)

```bash
# Local calendar for the week
python3 -c "
from hummbl_governance.integrations.google_calendar_adapter import GoogleCalendarAdapter
import datetime, zoneinfo
tz = zoneinfo.ZoneInfo('America/New_York')
today = datetime.datetime.now(tz)
# Get Mon-Sun of current week
monday = today - datetime.timedelta(days=today.weekday())
try:
    adapter = GoogleCalendarAdapter()
    entries = adapter.get_calendar_entries()
    for e in entries:
        e_date = str(e.start_time)[:10]
        week_start = monday.strftime('%Y-%m-%d')
        week_end = (monday + datetime.timedelta(days=6)).strftime('%Y-%m-%d')
        if week_start <= e_date <= week_end:
            print(f'  {e_date} {str(e.start_time)[11:16]} {e.title}')
except Exception as ex:
    print(f'Calendar unavailable: {ex}')
" 2>&1

# Sprint goals
cat /work/active/PSI/_state/intent.md 2>/dev/null | grep -E "GOAL|SPRINT|ONE THING|TODO" | head -10

# Coaching blocks (always protected)
echo "FIXED BLOCKS:"
echo "  Mon/Fri 7:30-9:30am: coaching (commit before, not during)"
echo "  Wed 10:30-12:30: hard stop"
echo "  Thu: reserved"
```

### 2. Assess available deep-work hours

Protected blocks removed, remaining = plannable time:

| Day | Coaching/Fixed | Available for deep work |
|-----|---------------|------------------------|
| Mon | 7:30–9:30am | Afternoon / evening |
| Tue | — | Full day |
| Wed | 10:30–12:30 HARD STOP | Morning only |
| Thu | Reserved | Light / off |
| Fri | 7:30–9:30am | Afternoon / evening |

### 3. Allocate sprint goals to days

Map this week's sprint goals to specific days. Each day gets:
- **THE ONE THING** — the single outcome that makes today a win
- **First action** — the exact first step to take
- **Time estimate** — S (< 2h) / M (2–4h) / L (4h+)

### 4. Write seed intents for each day

```bash
WEEK_START=$(TZ=America/New_York date +%Y-%m-%d)
for OFFSET in 0 1 2 3 4; do
    DAY=$(python3 -c "
import datetime, zoneinfo
tz = zoneinfo.ZoneInfo('America/New_York')
today = datetime.datetime.now(tz)
monday = today - datetime.timedelta(days=today.weekday())
print((monday + datetime.timedelta(days=$OFFSET)).strftime('%Y-%m-%d'))
")
    echo "[$DAY] SEED (weekly-plan): <THE ONE THING for this day>" >> \
      /work/active/PSI/_state/intent.md
done
```

Replace `<THE ONE THING for this day>` with the actual allocations from step 3.

### 5. Pipeline commitment

At the start of each week, commit to:
- **Pipeline touches this week**: minimum 5 (one per day)
- **Wave 1 status**: sent / following up / stuck on ___
- **One new ATL contact to add**: name and how to reach

## Output Format

```
Weekly Plan | week of <Mon date>
════════════════════════════════

## Constraints This Week
- Mon: coaching 7:30–9:30 | Tue: clear | Wed: hard stop 10:30 | Thu: reserved | Fri: coaching 7:30–9:30

## Sprint Goals → Days
| Day | THE ONE THING | Effort | First Action |
|-----|--------------|--------|-------------|
| Mon | | | |
| Tue | | | |
| Wed | | | |
| Thu | light/off | | |
| Fri | | | |

## Pipeline Commitment
- Touches this week: 5 minimum
- Wave 1 current status: <status>
- New ATL contact target: <name>

## Seeds Written
✓ 5 seed intents written to intent.md — [gm] will read them each morning
```

## Skill Chains

### Mandatory

None — planning; generates plan and writes seed intents to intent.md.

### Advisory

- → `[weekly-review]` (review Monday AM, plan immediately after)
- → `[gm]` (Monday morning sequence: `[gm]` → `[weekly-plan]` → start work)
- → `[rice-prioritize]` (if goals exceed available days)
- → `[pipeline-review]` (if pipeline is stuck)

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (planning is advisory — operator confirms)
- **Operator**: Override any restriction
