---
name: routing-evolve
description: Cross-reference skill-routing.md against telemetry — find dead triggers, missing triggers, orphan skills
version: 0.1.0
execution-mode: advisory
argument-hint: "[full | dead-only | missing-only | orphans]"
category: hummbl-research
status: candidate
---
# Routing Evolution Engine

Cross-reference skill-routing.md trigger patterns against telemetry data. Find dead triggers, missing triggers, cannibalized skills, and orphan skills that are completely invisible.

## When to Use
- After creating new skills (verify they're routable)
- Weekly skill library health check (pair with `[skill-evolve]`)
- When skills seem hard to discover
- Before pruning or expanding routing patterns

## Data Sources

### 1. Routing File
`~/.agents/skill-routing.md` — trigger patterns.

### 2. Telemetry
`~/.agents/_state/telemetry/skill-usage.tsv` — actual invocations.

### 3. Skill Directories
`~/.agents/skills/*/SKILL.md` — all installed skills.

## Execution

### Run the analysis

```bash
cd $HOME && python -c "
import os, re, csv, glob
from collections import defaultdict, Counter
from datetime import datetime

# === 1. Parse routing file ===
routing_path = os.path.expanduser('~/.agents/skill-routing.md')
routed_skills = defaultdict(int)  # skill -> number of trigger patterns

with open(routing_path) as f:
    for line in f:
        # Match patterns like: → \`[skill-name]\` or → \`[skill-name] arg\`
        matches = re.findall(r'→\s*\x60/([a-z0-9_-]+)', line)
        for m in matches:
            routed_skills[m] += 1

print(f'Routing: {len(routed_skills)} unique skills with {sum(routed_skills.values())} total trigger patterns')

# === 2. Parse telemetry ===
tele_path = os.path.expanduser('~/.agents/_state/telemetry/skill-usage.tsv')
invoked_skills = Counter()
first_seen = {}
last_seen = {}

if os.path.isfile(tele_path):
    with open(tele_path) as f:
        reader = csv.reader(f, delimiter='\t')
        header = next(reader, None)
        for row in reader:
            if len(row) >= 2:
                ts, skill = row[0], row[1].strip()
                invoked_skills[skill] += 1
                if skill not in first_seen:
                    first_seen[skill] = ts
                last_seen[skill] = ts

print(f'Telemetry: {len(invoked_skills)} unique skills invoked, {sum(invoked_skills.values())} total invocations')

# === 3. Parse skill directories ===
skills_dir = os.path.expanduser('~/.agents/skills/')
all_skills = set()
for d in glob.glob(os.path.join(skills_dir, '*/SKILL.md')):
    skill_name = os.path.basename(os.path.dirname(d))
    if not skill_name.startswith('_'):
        all_skills.add(skill_name)

print(f'Installed: {len(all_skills)} skill directories')
print()

# === 4. Analysis ===
routed_set = set(routed_skills.keys())
invoked_set = set(invoked_skills.keys())

# Dead triggers: routed but never invoked
dead_triggers = sorted(routed_set - invoked_set)

# Missing triggers: invoked 2+ times but not routed
missing_triggers = [(s, invoked_skills[s]) for s in invoked_set - routed_set if invoked_skills[s] >= 2]
missing_triggers.sort(key=lambda x: -x[1])

# Orphan skills: installed but neither routed nor invoked
orphan_skills = sorted(all_skills - routed_set - invoked_set)

# Under-routed: only 1 trigger pattern
under_routed = [(s, routed_skills[s]) for s in routed_skills if routed_skills[s] == 1]

# Over-routed: 5+ trigger patterns  
over_routed = [(s, routed_skills[s]) for s in routed_skills if routed_skills[s] >= 5]
over_routed.sort(key=lambda x: -x[1])

# Coverage stats
both = routed_set & invoked_set
coverage_routed = len(routed_set) / len(all_skills) * 100 if all_skills else 0
coverage_invoked = len(invoked_set) / len(all_skills) * 100 if all_skills else 0
coverage_both = len(both) / len(all_skills) * 100 if all_skills else 0

# === 5. Output ===
print('=' * 72)
print(f'Routing Evolution Engine | {len(routed_set)} routed | {len(invoked_set)} invoked | {len(all_skills)} installed')
print('=' * 72)
print()

print('COVERAGE')
print(f'  Skills with routing: {len(routed_set)} / {len(all_skills)} ({coverage_routed:.0f}%)')
print(f'  Skills with invocations: {len(invoked_set)} / {len(all_skills)} ({coverage_invoked:.0f}%)')
print(f'  Skills with both: {len(both)} / {len(all_skills)} ({coverage_both:.0f}%)')
total_sessions = len(set(row[3] for row in csv.reader(open(tele_path), delimiter='\t') if len(row) >= 4)) - 1 if os.path.isfile(tele_path) else 0
print(f'  Telemetry window: {total_sessions} sessions')
print()

if dead_triggers:
    print(f'DEAD TRIGGERS ({len(dead_triggers)} skills routed but never invoked)')
    for s in dead_triggers[:30]:
        patterns = routed_skills[s]
        print(f'  /{s} — {patterns} pattern(s)')
    if len(dead_triggers) > 30:
        print(f'  ... and {len(dead_triggers)-30} more')
    print()

if missing_triggers:
    print(f'MISSING TRIGGERS ({len(missing_triggers)} skills invoked but not routed)')
    for s, count in missing_triggers:
        print(f'  /{s} — {count} invocations (needs routing pattern)')
    print()

if orphan_skills:
    print(f'ORPHAN SKILLS ({len(orphan_skills)} — neither routed nor invoked)')
    # Show first 20
    for s in orphan_skills[:20]:
        print(f'  /{s}')
    if len(orphan_skills) > 20:
        print(f'  ... and {len(orphan_skills)-20} more')
    print()

print('ROUTING DENSITY')
if over_routed:
    print(f'  Over-routed (5+ patterns):')
    for s, n in over_routed[:10]:
        print(f'    /{s} ({n} patterns)')
print(f'  Under-routed (1 pattern): {len(under_routed)} skills')
if under_routed:
    for s, n in under_routed[:10]:
        print(f'    /{s}')
    if len(under_routed) > 10:
        print(f'    ... and {len(under_routed)-10} more')
print()

print('RECOMMENDATIONS')
if dead_triggers:
    print(f'  MONITOR: {len(dead_triggers)} dead triggers (keep — telemetry is only {total_sessions} sessions)')
if missing_triggers:
    print(f'  ADD: {len(missing_triggers)} missing trigger patterns')
if orphan_skills:
    print(f'  ROUTE OR RETIRE: {len(orphan_skills)} orphan skills with zero visibility')
if over_routed:
    print(f'  REVIEW: {len(over_routed)} over-routed skills may have redundant patterns')
print(f'  CONFIDENCE: {\"HIGH\" if total_sessions >= 30 else \"MEDIUM\" if total_sessions >= 15 else \"LOW\"} ({total_sessions} sessions)')
"
```

## Constraints

- READ-ONLY. Do not modify routing or telemetry files.
- Do not fabricate counts. Parse actual data.
- With <30 sessions, dead triggers are LOW confidence — the skill may simply not have been needed yet.
- Orphan skills are not necessarily broken — they may be inventory for future use.
