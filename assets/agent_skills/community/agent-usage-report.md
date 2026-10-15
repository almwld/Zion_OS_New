---
name: agent-usage-report
description: Report named-agent usage telemetry, citation counts, first/last use, and backfill coverage for Apex/ARCANA-style agent promotion decisions. Use when asked about agent usage, lens telemetry, who is getting cited, citation counts, or named-agent promotion evidence.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--all] [--agent NAME] [--cluster PREFIX] [--days N]"
category: dev-tools
status: candidate
---
# Agent Usage Report

Render the named-agent usage histogram from:

`$env:USERPROFILE\_internal\telemetry\agent-usage.jsonl`

Default command:

```powershell
python $env:USERPROFILE\bin\agent-usage-report.py
```

Useful variants:

```powershell
python $env:USERPROFILE\bin\agent-usage-report.py --all
python $env:USERPROFILE\bin\agent-usage-report.py --agent apex
python $env:USERPROFILE\bin\agent-usage-report.py --cluster arcana
python $env:USERPROFILE\bin\agent-usage-report.py --days 30
```

If telemetry is missing or empty, run a dry-run backfill first:

```powershell
python $env:USERPROFILE\bin\agent-usage-backfill.py --dry-run
```

Backfill scans Claude session JSONL Agent tool-use records. It does not persist or report prompt bodies. Free-text AAR and bus messages are intentionally not mined as promotion evidence.

Then, if the dry-run output is plausible, write backfilled records:

```powershell
python $env:USERPROFILE\bin\agent-usage-backfill.py
```

Report the histogram sorted by ascending citation count. For promotion or retirement recommendations, cite:

- telemetry path
- report window
- citation count
- first and last use
- whether records are live or backfilled

Do not treat backfilled records as full runtime instrumentation. They are a Phase 0 proxy until Agent-tool auto-logging exists.

## Cloudflare Neuron Usage
For Cloudflare Workers AI Neuron consumption tracking, use the usage-monitor tool:
```bash
python ~/bin/usage_monitor.py status          # today's Neuron usage
python ~/bin/usage_monitor.py trend           # 7-day trend
python ~/bin/usage_monitor.py export --format csv  # export for reporting
```
See `[usage-monitor]` skill for details.
