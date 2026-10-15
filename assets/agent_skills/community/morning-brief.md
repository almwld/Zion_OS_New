---
name: morning-brief
description: Unified fleet+news briefing emailed to Proton every 4 hours — action-required probes, fleet state, bus/PR activity digest, and the deduplicated news feed layer. Replaces the news-only daily digest as the operator's standing brief.
version: 0.1.0
execution-mode: side-effecting
argument-hint: "[--out] [--send] [--window N] [--to addr] [--no-news]"
category: fleet-ops
status: candidate
providers:
  required: [python]
  optional: [op, gh]
---

# morning-brief — Unified Fleet Brief

One brief, six times a day (every 4h starting 04:00 local): what's on fire,
what needs the operator, what the fleet did, and what happened in AI news.

## Sections

| Section | Source | Fail-soft |
|---------|--------|-----------|
| Action Required | live probes (gitea healthz, sessions.db size, drift-check log tail, latest handoff doc) | missing data → item omitted |
| Fleet State | drift-check log, Get-ScheduledTaskInfo, disk, gitea | "(unavailable)" cells |
| Activity | `~/.cache/bus/messages.tsv` tail + `gh search prs --merged` | "(unavailable)" note |
| News | `skills/news-brief` feed layer (imported) | per-source "(unavailable)" |

HuggingNews stories are deduplicated by title-token Jaccard (≥0.6 → folded
into a cluster, shown as "(+N related)") — the raw feed repeats the same
developing story 5–8×.

## Execution

```bash
python scripts/morning_brief.py              # print to stdout
python scripts/morning_brief.py --out        # + write _state/briefings/YYYY-MM-DD-HHMM.md
python scripts/morning_brief.py --out --send # + email to Proton
python scripts/morning_brief.py --window 8 --no-news --to me@x.io
```

`--out` also refreshes `YYYY-MM-DD.md` so `[briefing-history] show <date>`
returns the latest brief of the day.

## Mail path

- Rail: MXRoute SMTP `chocobo.mxrouting.net:465` (the approved outbound
  rail — `registry/venues.yaml`: Proton is sole MX for inbound hummbl.io,
  MXRoute is send-only outbound). `reuben@hummbl.io` arrives in the
  Proton-hosted inbox.
- Credential: CredMan `HUMMBL:MXROUTE_SMTP_REUBEN` first → falls back to
  `op item get nokocwol22jujgrj7wjqkb2lly --fields password --reveal`;
  a successful `op` lookup seeds CredMan, so sustained `op` rate limits
  don't break the schedule.
- Send failure → brief still prints/writes; exit code 2.

## Scheduling

`scripts/morning-brief.vbs` hides the console window per fleet convention.

```cmd
schtasks /create /tn "HUMMBL\MorningBrief" /sc HOURLY /mo 4 /st 04:00 /f /tr "wscript.exe \"<skill>\scripts\morning-brief.vbs\""
```

Runs at 04/08/12/16/20/00 local. Supersedes `\HUMMBL\news-brief`'s role as
the day-start read; that task is left registered because its dated file
still feeds `[briefing-history]` and `[daily-research]` chains.

## Skill Chains

| After this skill... | Consider... |
|---------------------|-------------|
| Action item surfaced | the linked runbook / handoff doc |
| Story worth tracking | `[hf-watch]`, `[industry-watch]` |
| Deeper evidence on a story | `[daily-research]` |
| Past briefs | `[briefing-history]` |

## Constraints

- Every probe is bounded (≤30s) and fail-soft; the brief must always render.
- No `op` calls except the single mail-password fallback (avoids feeding
  the shared-account rate limit).
- Never logs the SMTP password; CredMan read stays in process memory.
- Writes only under `_state/briefings/` and the outbound SMTP connection.
