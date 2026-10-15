---
name: idp-inspect
description: Query IDP governance JSONL and delegation state.
version: 0.1.0
execution-mode: advisory
argument-hint: "[recent | agent AGENT | delegation-chain]"
category: governance-compliance
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Governance files**: Run `ls -t $PROJECT_ROOT/_state/governance/governance-*.jsonl 2>/dev/null | head -3 || echo "no governance files"`

# IDP Inspect Command

Inspect the Identity Delegation Protocol (IDP) governance log and delegation state.

## Usage

```bash
[idp-inspect]          # Full IDP status report
```

## Execution

### 1. Check IDP feature flag
```bash
echo $ENABLE_IDP
```
If not set, inform the user to run with `ENABLE_IDP=true`.

### 2. List governance files
```bash
ls -lt $PROJECT_ROOT/_state/governance/governance-*.jsonl
```

### 3. Read latest governance log
```bash
tail -50 $(ls -t $PROJECT_ROOT/_state/governance/governance-*.jsonl | head -1)
```

### 4. Count tuple types
```bash
cat $(ls -t $PROJECT_ROOT/_state/governance/governance-*.jsonl | head -1) | python3 -c "
import sys, json
counts = {}
for line in sys.stdin:
    try:
        d = json.loads(line)
        t = d.get('tuple_type', 'UNKNOWN')
        counts[t] = counts.get(t, 0) + 1
    except: pass
for k, v in sorted(counts.items(), key=lambda x: -x[1]):
    print(f'{k}: {v}')
"
```

### 5. Check delegation chain depth
```bash
cat $(ls -t $PROJECT_ROOT/_state/governance/governance-*.jsonl | head -1) | python3 -c "
import sys, json
depths = []
for line in sys.stdin:
    try:
        d = json.loads(line)
        if 'chain_depth' in d:
            depths.append(d['chain_depth'])
    except: pass
if depths:
    print(f'Max depth: {max(depths)}, Avg: {sum(depths)/len(depths):.1f}')
else:
    print('No chain depth data')
"
```

## Output Format

```
IDP Inspect | <YYYY-MM-DD HH:MMZ>
══════════════════════════════════

Feature flag: ENABLE_IDP=true/false
Governance files: N files

## Latest Log: <filename>
Entries: NNN
Time range: <first> → <last>

## Tuple Type Distribution
| Type | Count | % |
|------|-------|---|
| DCTX | 45 | 35% |
| CONTRACT | 30 | 23% |
| EVIDENCE | 25 | 19% |
| ATTEST | 20 | 15% |
| DCT | 10 | 8% |

## Chain Depth Stats
Max depth: N
Average depth: N.N

## Recent Entries (Last 10)
<formatted recent governance entries>
```

## Constraints

- READ-ONLY. Do not modify governance logs.
- Requires `ENABLE_IDP=true` for full functionality.
- Do not fabricate governance data -- always read actual JSONL files.
- Governance logs are append-only -- never suggest editing them.
