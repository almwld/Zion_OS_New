---
name: log-tail
description: Tail and search logs -- local services, launchd agents, bus, governance.
version: 0.1.0
execution-mode: advisory
argument-hint: "[bus [N] | governance [N] | service NAME | errors | launchd LABEL]"
category: governance-compliance
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Recent errors**: Run `grep -c "ERROR\|FAIL\|Traceback" /tmp/*.err 2>/dev/null | grep -v ":0$" | tail -3 || echo "no local errors"`

# Log Tail Command

Quick access to logs across all services and subsystems.

## Operations

### bus
Last N bus messages (default 20):
```bash
tail -${N:-20} _state/coordination/messages.tsv | column -t -s $'\t'
```

### governance
Last N governance bus entries:
```bash
tail -${N:-10} _state/governance/audit.jsonl 2>/dev/null | python3 -m json.tool --no-ensure-ascii
```

### service
Tail a local or remote service log:
```bash
# Local
tail -50 /tmp/<service>.log 2>/dev/null
tail -50 /tmp/<service>.err 2>/dev/null

# Remote ($REMOTE_HOST)
ssh -o ConnectTimeout=10 $REMOTE_HOST "tail -50 /tmp/<service>.log 2>/dev/null"
```

Common services: `open-brain`, `autoresearch-bridge`, `mlx-analysis-bridge`, `research-processor`, `consolidator`, `briefing`

### errors
Find recent errors across all log files:
```bash
echo "=== Local errors ==="
grep -l "ERROR\|FAIL\|Traceback" /tmp/*.err /tmp/*.log 2>/dev/null | head -10
for f in $(grep -l "ERROR\|FAIL\|Traceback" /tmp/*.err /tmp/*.log 2>/dev/null | head -5); do
  echo "--- $(basename $f) ---"
  grep "ERROR\|FAIL\|Traceback" "$f" | tail -3
done

echo "=== remote-node errors ==="
ssh -o ConnectTimeout=10 $REMOTE_HOST "grep -l 'ERROR\|FAIL\|Traceback' /tmp/*.err /tmp/*.log 2>/dev/null | head -5" 2>/dev/null
```

### launchd
Check a specific launchd agent's status and recent output:
```bash
launchctl list | grep "$LABEL"
# Or on $REMOTE_HOST:
ssh -o ConnectTimeout=10 $REMOTE_HOST "launchctl list | grep '$LABEL'"
```

## Log Locations
| Service | stdout | stderr |
|---------|--------|--------|
| Open Brain | `/tmp/open-brain.log` | `/tmp/open-brain.err` |
| Autoresearch | `/tmp/autoresearch-bridge.log` | `/tmp/autoresearch-bridge.err` |
| MLX Bridge | `/tmp/mlx-analysis-bridge.log` | `/tmp/mlx-analysis-bridge.err` |
| Consolidator | `/tmp/consolidator.log` | `/tmp/consolidator.err` |
| Briefing | `/tmp/briefing.log` | `/tmp/briefing.err` |
