---
name: news-brief
description: Morning news digest — HuggingNews AI wire, Hacker News front page, Hugging Face trending models, arXiv cs.AI/cs.CL, and a configurable RSS layer (OpenAI, Microsoft Research, Simon Willison, Lobsters). Prints a markdown digest and optionally writes _state/briefings/YYYY-MM-DD.md for briefing-history.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--out] [--deep N] [--sources hnews,hn,hf,arxiv,extra] [--bus]"
category: fleet-ops
status: candidate
providers:
  required: [python]
  optional: []
---

# news-brief — Morning News Digest

Aggregates zero-auth public news feeds into one scannable digest. Lighter and
faster than `[daily-research]` (which is WebSearch-driven evidence collection);
this is a pull of structured feeds, ~10 seconds end to end.

## When to Use

- Morning routine — after `[gm]`, before or alongside `[daily-research]`
- "What's the news?" / "news brief" / "catch me up on AI news"
- Scheduled: a Task Scheduler job writes the briefing file overnight so the
  digest is already on disk when the day starts (see Scheduling)

## Sources

| Source | Endpoint | Auth | Covers |
|--------|----------|------|--------|
| HuggingNews | `api.huggingnews.com/api/stories` | none (key widens window) | AI wire — labs, models, products, policy; last ~2 ET days |
| Hacker News | `hn.algolia.com/api/v1/search?tags=front_page` | none | Tech front page |
| HF Hub | `huggingface.co/api/models?sort=likes7d` | none | Trending models |
| arXiv | `export.arxiv.org/api/query` | none | cs.AI / cs.CL latest submissions |
| Extra RSS | OpenAI, Microsoft Research, Simon Willison, Lobsters | none | Lab blogs + high-signal tech writing |

Notes:

- `HUGGINGNEWS_API_KEY` (optional) is picked up automatically and widens the
  feed window + search depth.
- HuggingNews already covers Anthropic/DeepMind/Google AI news — those labs
  expose no working RSS, so they are not in EXTRA_FEEDS.
- To change extra feeds, edit `EXTRA_FEEDS` in `scripts/news_brief.py`.

## Execution

Script: `scripts/news_brief.py` (stdlib-only, Python 3.9+).

```bash
python ~/.agents/skills/news-brief/scripts/news_brief.py            # print digest
python ~/.agents/skills/news-brief/scripts/news_brief.py --out      # + write briefing file
python ~/.agents/skills/news-brief/scripts/news_brief.py --sources hnews,hn  # subset
python ~/.agents/skills/news-brief/scripts/news_brief.py --deep 0   # titles only (fastest)
```

Flags:

- `--out` — write `<NEWS_BRIEF_DIR or ~/.agents/_state/briefings>/YYYY-MM-DD.md`
  (the path `[briefing-history]` reads)
- `--deep N` — fetch full summaries for the top N HuggingNews stories
  (default 5; summaries are copied verbatim per the HuggingNews skill contract)
- `--hnews/--hn/--hf/--arxiv N` — per-source item limits
- `--sources` — comma subset of `hnews,hn,hf,arxiv,extra`
- `--bus` — post a one-line STATUS to the coordination bus (off by default)

Every source is fail-soft: an unreachable feed degrades to an inline
"(source unavailable)" note rather than failing the brief.

## Scheduling (Windows)

The brief is designed to run before the day starts. Fleet convention
(`windows-task-audit`) requires VBS launchers — never a direct
powershell/python action, which flashes a console window.

`scripts/news-brief.vbs`:

```vbs
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run """<python.exe>"" ""<skill>\scripts\news_brief.py"" --out", 0, False
```

Registered task (receipt of what was created 2026-09-22):

```
Task:  \HUMMBL\news-brief
Runs:  daily 06:30 local
Exec:  wscript.exe "...\.agents\skills\news-brief\scripts\news-brief.vbs"
```

To re-create on another host: generate the VBS launcher with absolute paths,
then `schtasks /Create /TN "HUMMBL\news-brief" /SC DAILY /ST 06:30 /TR "wscript.exe \"<vbs>\""`.
Audit with `[windows-task-audit]` after creation.

## Output Format

```
# News Brief | YYYY-MM-DD HH:MM <tz>

## HuggingNews — AI wire          (stories + verbatim summaries for top N)
## Hacker News — front page       (pts, comments, hn link)
## Hugging Face — trending models (pipeline tag, likes, downloads)
## arXiv — cs.AI / cs.CL          (authors, age)
## Blogs & other feeds            (per-feed sections)
```

## Skill Chains

| After this skill... | Consider... |
|---------------------|-------------|
| `[gm]` (morning) | `[news-brief]` then `[daily-research]` for evidence depth |
| Story worth tracking | `[hf-watch]` (HF ecosystem) or `[industry-watch]` (vendors) |
| Regulatory story | `[ai-regulation]`, `[legal-ai-precedent-watch]` |
| Finding worth keeping | `[note]` / `[ledger]` ingest |
| Past briefs | `[briefing-history]` list/show/diff |

## Constraints

- Advisory/read-only on the network; the only write is the briefing file
  under `_state/briefings/` and the optional bus post.
- HuggingNews story summaries are reproduced verbatim — do not paraphrase
  them in the brief (per the HuggingNews skill contract).
- No fabricated items: if a source fails, print the failure line.

## Authority

- **T1–T4**: full run (network reads + `_state/briefings/` writes only)
- **Operator**: schedule changes, new feed additions to EXTRA_FEEDS defaults
