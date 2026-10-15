---
name: chain-evolve
description: Validate skill-chains.md against actual usage sequences — find emergent chains, dead chains, high-value paths
version: 0.1.0
execution-mode: advisory
argument-hint: "[full | emergent | dead | graph]"
category: hummbl-research
status: candidate
---
# Chain Evolution Engine

Validate the skill chain graph (`skill-chains.md`) against actual usage telemetry. Find chains that are declared but never followed (dead), usage sequences that happen but aren't declared (emergent), and high-value paths that should be promoted.

## When to Use
- Weekly skill library health check (pair with `[skill-evolve]`)
- After creating new skills to verify chain connectivity
- When wondering if skill suggestions are actually helping
- Before pruning or expanding the chain table

## Data Sources

### 1. Chain Definitions
`~/.agents/rules/skill-chains.md` — declared "after X, suggest Y" relationships.

### 2. Skill Telemetry
`~/.agents/_state/telemetry/skill-usage.tsv` — actual invocation sequence.

Columns: `timestamp_utc`, `skill`, `args`, `session_id`

## Execution

### Run the analysis

```bash
cd $HOME && python3 -c "
import os, re, csv
from collections import defaultdict, Counter
from datetime import datetime

# === 1. Parse chain definitions ===
chains_path = os.path.expanduser('~/.agents/rules/skill-chains.md')
declared_chains = []  # (from_skill, to_skill)
with open(chains_path) as f:
    for line in f:
        # Match table rows like: | \`[pre-mortem]\` | \`[worst-case]\`, \`[threat-model]\` |
        m = re.match(r'\|\s*\x60/([^\x60]+)\x60\s*\|\s*(.+?)\s*\|', line)
        if m:
            from_skill = m.group(1).strip()
            targets = re.findall(r'\x60/([^\x60]+)\x60', m.group(2))
            for t in targets:
                declared_chains.append((from_skill, t.strip()))

print(f'Declared chains: {len(declared_chains)} edges from {len(set(c[0] for c in declared_chains))} source skills')
print()

# === 2. Parse telemetry for actual sequences ===
tele_path = os.path.expanduser('~/.agents/_state/telemetry/skill-usage.tsv')
sessions = defaultdict(list)  # session_id -> [(timestamp, skill)]

if os.path.isfile(tele_path):
    with open(tele_path) as f:
        reader = csv.reader(f, delimiter='\t')
        header = next(reader, None)
        for row in reader:
            if len(row) >= 4:
                ts, skill, args, sid = row[0], row[1], row[2], row[3]
                sessions[sid].append((ts, skill.strip()))

    # Sort each session by timestamp
    for sid in sessions:
        sessions[sid].sort()

    # Extract sequential pairs within sessions (A followed by B = edge A->B)
    actual_pairs = Counter()
    for sid, invocations in sessions.items():
        for i in range(len(invocations) - 1):
            a = invocations[i][1]
            b = invocations[i+1][1]
            if a != b:  # skip self-loops
                actual_pairs[(a, b)] += 1

    total_invocations = sum(len(v) for v in sessions.values())
    total_sessions = len(sessions)
else:
    actual_pairs = Counter()
    total_invocations = 0
    total_sessions = 0

print(f'Telemetry: {total_invocations} invocations across {total_sessions} sessions')
print(f'Actual sequential pairs: {len(actual_pairs)} unique edges')
print()

# === 3. Classify chains ===
declared_set = set(declared_chains)
actual_set = set(actual_pairs.keys())

# Dead chains: declared but never observed
dead_chains = [(a, b) for a, b in declared_set if (a, b) not in actual_set]

# Emergent chains: observed 2+ times but not declared
emergent_chains = [(a, b, actual_pairs[(a,b)]) for a, b in actual_set 
                   if (a, b) not in declared_set and actual_pairs[(a,b)] >= 2]
emergent_chains.sort(key=lambda x: -x[2])

# Validated chains: declared AND observed
validated = [(a, b, actual_pairs[(a,b)]) for a, b in declared_set if (a, b) in actual_set]
validated.sort(key=lambda x: -x[2])

# === 4. Graph stats ===
source_skills = set(c[0] for c in declared_chains)
target_skills = set(c[1] for c in declared_chains)
leaf_targets = target_skills - source_skills  # skills that are suggested but never suggest others
orphan_sources = source_skills - target_skills  # skills that suggest but are never suggested

# === 5. Output ===
print('=' * 68)
print(f'Chain Evolution Engine | {len(declared_chains)} declared | {len(actual_pairs)} observed | {total_sessions} sessions')
print('=' * 68)
print()

print('CHAIN HEALTH')
print(f'  Declared edges: {len(declared_chains)}')
print(f'  Validated (declared + observed): {len(validated)}')
print(f'  Dead (declared, never observed): {len(dead_chains)}')
print(f'  Emergent (observed 2+, not declared): {len(emergent_chains)}')
print()

if validated:
    print('VALIDATED CHAINS (working as intended)')
    for a, b, count in validated[:10]:
        print(f'  /{a} → /{b}  ({count}x)')
    print()

if emergent_chains:
    print('EMERGENT CHAINS (add to skill-chains.md)')
    for a, b, count in emergent_chains[:15]:
        print(f'  /{a} → /{b}  ({count}x)')
    print()

if dead_chains:
    print(f'DEAD CHAINS ({len(dead_chains)} — declared but never followed)')
    # Group by source
    dead_by_source = defaultdict(list)
    for a, b in dead_chains:
        dead_by_source[a].append(b)
    for src in sorted(dead_by_source, key=lambda s: -len(dead_by_source[s]))[:20]:
        targets = ', '.join(f'/{t}' for t in dead_by_source[src][:5])
        more = f' +{len(dead_by_source[src])-5} more' if len(dead_by_source[src]) > 5 else ''
        print(f'  /{src} → {targets}{more}')
    print()

print('GRAPH TOPOLOGY')
print(f'  Source skills (suggest others): {len(source_skills)}')
print(f'  Target skills (get suggested): {len(target_skills)}')
print(f'  Leaf targets (suggested but never suggest): {len(leaf_targets)}')
if leaf_targets:
    print(f'    {', '.join(sorted(list(leaf_targets))[:10])}')
print(f'  Orphan sources (suggest but never suggested): {len(orphan_sources)}')
if orphan_sources:
    print(f'    {', '.join(sorted(list(orphan_sources))[:10])}')
print()

print('RECOMMENDATIONS')
if emergent_chains:
    print(f'  ADD: {len(emergent_chains)} emergent chains to skill-chains.md')
if dead_chains and total_sessions >= 20:
    print(f'  PRUNE: {len(dead_chains)} dead chains (only after 30+ days of telemetry)')
elif dead_chains:
    print(f'  MONITOR: {len(dead_chains)} dead chains (only {total_sessions} sessions — too early to prune)')
if not validated:
    print(f'  NOTE: 0 validated chains — telemetry may be too sparse ({total_sessions} sessions)')
print(f'  TELEMETRY CONFIDENCE: {\"HIGH\" if total_sessions >= 30 else \"MEDIUM\" if total_sessions >= 15 else \"LOW\"} ({total_sessions} sessions)')
"
```

## Output Format

```
Chain Evolution Engine | N declared | M observed | S sessions
====================================================================

CHAIN HEALTH
  Declared edges: N
  Validated (declared + observed): V
  Dead (declared, never observed): D
  Emergent (observed 2+, not declared): E

VALIDATED CHAINS (working as intended)
  [skill-a] → [skill-b]  (Nx)

EMERGENT CHAINS (add to skill-chains.md)
  [skill-c] → [skill-d]  (Nx)

DEAD CHAINS (declared but never followed)
  [skill-e] → [skill-f], [skill-g]

GRAPH TOPOLOGY
  Source skills: N
  Target skills: M
  Leaf targets: L
  Orphan sources: O

RECOMMENDATIONS
  ADD: ...
  PRUNE: ...
  MONITOR: ...
```

## Constraints

- READ-ONLY. Do not modify skill-chains.md or telemetry.
- Do not fabricate counts. Parse actual data.
- With <30 sessions of telemetry, mark all findings as LOW confidence.
- Dead chains are not necessarily wrong — they may represent rare but valid paths.
