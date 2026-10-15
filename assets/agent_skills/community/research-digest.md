---
name: research-digest
description: Summarize recent research findings from Open Brain, autoresearch pipeline, and docs/research/.
version: 0.1.1
execution-mode: advisory
argument-hint: "[recent | topic \"TERM\" | sources | pipeline-status]"
category: fleet-ops
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Platform**: On Windows (PowerShell) and Unix (Bash), the Git recency
  commands below use the same arguments. The ledger and Open Brain probes in
  this version still require a Unix-compatible shell.
- **Committed research docs**: Run
  `git log --since="7 days ago" --name-only --format= --diff-filter=AMR -- ":(glob)docs/research/**/*.md"`
  and intersect its nonblank paths with
  `git ls-files -- ":(glob)docs/research/**/*.md"`. Remove duplicates and retain
  at most five paths from that intersection for initial context.
- **Untracked research docs**: Run
  `git ls-files --others --exclude-standard -- ":(glob)docs/research/**/*.md"`
  and label every result `date-unverified`; an untracked file has no durable
  Git timestamp.
- **Ledger discoveries**: Run `source .venv/bin/activate 2>/dev/null && python -m hummbl_governance.cognition query --type discovery --limit 3 2>/dev/null || echo "(no discoveries)"`

# Research Digest Command

Surface and summarize research findings across the multi-source research pipeline.

## Operations

### recent
Show research artifacts committed in the rolling seven-day Git-history window.
This is independent of clone or checkout time. Intersect the first command's
nonblank output with the second command's output, then remove duplicates. The
intersection excludes deleted paths while retaining Markdown files added,
modified, or renamed during the window.

Run these three commands unchanged in PowerShell or Bash:

```text
git log --since="7 days ago" --name-only --format= --diff-filter=AMR -- ":(glob)docs/research/**/*.md"
git ls-files -- ":(glob)docs/research/**/*.md"
git ls-files --others --exclude-standard -- ":(glob)docs/research/**/*.md"
```

Present the third command's results under `Untracked research docs
(date-unverified)`. Do not describe them as recent without another durable date
source. Then, where a Unix-compatible shell and the local services are
available, gather the remaining pools:

```bash
echo "=== Ledger Discoveries ==="
source .venv/bin/activate
python -m hummbl_governance.cognition query --type discovery --limit 10

echo "=== Open Brain (if accessible) ==="
curl -s http://127.0.0.1:11435/api/search -H "Content-Type: application/json" \
  -d '{"query":"recent findings","limit":5}' 2>/dev/null | python3 -m json.tool || echo "(Open Brain not accessible locally)"
```

### topic
Search all research sources for a specific topic:
1. Grep `docs/research/` for the term
2. Search the CLP ledger for matching entries
3. Query Open Brain if accessible

### sources
List all research sources and their status:
- `docs/research/` -- Markdown research documents (git-tracked)
- `_state/cognition/ledger.jsonl` -- CLP entries tagged as discoveries
- Open Brain server ($REMOTE_HOST:11435) -- Consolidated knowledge
- Autoresearch pipeline outputs (`_state/autoresearch/`)

### pipeline-status
Check the autoresearch pipeline health:
```bash
ssh -o ConnectTimeout=10 $REMOTE_HOST "launchctl list | grep -E 'autoresearch|research-processor|mlx-analysis' && echo '---' && tail -5 /tmp/autoresearch-bridge.log 2>/dev/null"
```

## Research Pipeline Architecture
1. **GitHub Events** -> autoresearch-bridge -> Open Brain ingest
2. **MLX Analysis** -> mlx-analysis-bridge -> Open Brain ingest
3. **Manual Research** -> `docs/research/` (git-tracked)
4. **CLP Entries** -> ledger discoveries, lessons, conventions
5. **Open Brain Consolidator** -> nightly synthesis via qwen3.5:9b on $REMOTE_HOST

## Key Files
- `docs/research/` -- Research documents
- `cognition/autoresearch_bridge.py` -- GitHub-to-Open Brain pipeline
- `cognition/research_processor.py` -- Research queue processor
- `cognition/consolidator.py` -- Nightly memory synthesis
- `cognition/server.py` -- Open Brain HTTP server
