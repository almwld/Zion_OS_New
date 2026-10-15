---
name: rules-evolve
description: Score .claude/rules/ files for relevance, overlap, and context budget cost — archive/compress/merge recommendations
version: 0.1.0
execution-mode: advisory
argument-hint: "[full | budget-only | overlap-only]"
category: hummbl-research
status: candidate
---
# Rules Evolution Engine

Score all `.claude/rules/*.md` files for relevance, overlap, context budget cost, and whether the conditions that created them still exist.

## When to Use
- Monthly context budget audit
- After adding new rules files
- When context window feels cramped (autocompact triggering early)
- Before onboarding a new agent (check if its guardrails overlap with existing rules)

## Data Sources

### 1. Rules Files
`~/.agents/rules/*.md` — all files auto-injected into every session.

### 2. Bus Messages (relevance check)
`~/.cache/bus/messages.tsv` — last 200 messages.

### 3. CLAUDE.md (overlap check)
`~/CLAUDE.md` — project instructions that are also auto-injected.

## Execution

### Run the analysis

```bash
cd $HOME && python3 -c "
import os, glob, re
from collections import defaultdict
from datetime import datetime

rules_dir = os.path.expanduser('~/.agents/rules/')
rules_files = sorted(glob.glob(os.path.join(rules_dir, '*.md')))

# === 1. Measure each file ===
results = []
all_keywords = {}  # file -> set of key phrases

for path in rules_files:
    name = os.path.basename(path)
    with open(path) as f:
        content = f.read()
    
    lines = content.count('\n') + 1
    chars = len(content)
    est_tokens = max(lines * 4, int(chars * 0.25))
    mtime = datetime.fromtimestamp(os.path.getmtime(path))
    
    # Extract key terms (words 5+ chars, appearing 2+ times)
    words = re.findall(r'[a-z]{5,}', content.lower())
    word_freq = defaultdict(int)
    for w in words:
        word_freq[w] += 1
    keywords = {w for w, c in word_freq.items() if c >= 2}
    all_keywords[name] = keywords
    
    # Check for agent status references
    status = 'UNKNOWN'
    if re.search(r'Status:?\s*RETIRED', content, re.IGNORECASE):
        status = 'RETIRED'
    elif re.search(r'SUSPENDED|suspended', content):
        status = 'SUSPENDED'  
    elif re.search(r'ACTIVE|active', content):
        status = 'ACTIVE'
    
    # Check for specific agent names
    agents_mentioned = set()
    for agent in ['gemini', 'codex', 'kimi', 'sov', 'claude']:
        if agent in content.lower():
            agents_mentioned.add(agent)
    
    results.append({
        'name': name,
        'lines': lines,
        'chars': chars,
        'est_tokens': est_tokens,
        'mtime': mtime,
        'status': status,
        'agents': agents_mentioned,
        'keywords': keywords,
    })

# === 2. Overlap detection ===
overlaps = []
names = [r['name'] for r in results]
for i in range(len(names)):
    for j in range(i+1, len(names)):
        a, b = names[i], names[j]
        shared = all_keywords[a] & all_keywords[b]
        union = all_keywords[a] | all_keywords[b]
        if union:
            jaccard = len(shared) / len(union)
            if jaccard > 0.25 and len(shared) > 5:
                overlaps.append((a, b, jaccard, len(shared)))

overlaps.sort(key=lambda x: -x[2])

# === 3. Bus relevance check ===
bus_path = os.path.expanduser('~/.cache/bus/messages.tsv')
bus_keywords = set()
if os.path.isfile(bus_path):
    with open(bus_path) as f:
        lines_bus = f.readlines()
    for line in lines_bus[-200:]:
        bus_keywords.update(re.findall(r'[a-z]{5,}', line.lower()))

# === 4. Score and tier ===
total_tokens = sum(r['est_tokens'] for r in results)
for r in results:
    # Active relevance (0.30)
    if r['status'] == 'RETIRED':
        relevance = 10
    elif r['status'] == 'SUSPENDED':
        relevance = 30
    else:
        relevance = 80
    
    # Bus frequency (0.20) — how many of this file's keywords appear in recent bus
    if r['keywords'] and bus_keywords:
        bus_hits = len(r['keywords'] & bus_keywords) / len(r['keywords']) * 100
    else:
        bus_hits = 50  # neutral
    
    # Size cost (0.25) — inverse: smaller = better
    max_lines = max(rr['lines'] for rr in results)
    size_score = max(0, 100 - (r['lines'] / max_lines * 100))
    
    # Overlap penalty (0.25) — less overlap = better
    overlap_count = sum(1 for o in overlaps if r['name'] in (o[0], o[1]))
    overlap_score = max(0, 100 - overlap_count * 30)
    
    r['score'] = int(relevance * 0.30 + bus_hits * 0.20 + size_score * 0.25 + overlap_score * 0.25)
    
    if r['score'] >= 80:
        r['tier'] = 'ESSENTIAL'
    elif r['score'] >= 50:
        r['tier'] = 'USEFUL'
    elif r['score'] >= 25:
        r['tier'] = 'BLOATED'
    else:
        r['tier'] = 'DEAD'

results.sort(key=lambda r: -r['score'])

# === 5. Output ===
print('=' * 72)
print(f'Rules Evolution Engine | {len(results)} rules files | ~{total_tokens:,} tokens/session')
print('=' * 72)
print()

print('CONTEXT BUDGET')
print(f'  Total rules injected per session: {len(results)} files')
print(f'  Total lines: {sum(r[\"lines\"] for r in results):,}')
print(f'  Estimated token cost: ~{total_tokens:,} tokens')
print(f'  Top 5 largest:')
for r in sorted(results, key=lambda x: -x['lines'])[:5]:
    print(f'    {r[\"name\"]} ({r[\"lines\"]} lines, ~{r[\"est_tokens\"]:,} tokens)')
print()

# Tier summary
tiers = defaultdict(list)
for r in results:
    tiers[r['tier']].append(r['name'])

print('TIER SUMMARY')
for tier in ['ESSENTIAL', 'USEFUL', 'BLOATED', 'DEAD']:
    if tiers[tier]:
        print(f'  {tier:10} ({len(tiers[tier]):>2}): {', '.join(tiers[tier][:5])}')
        if len(tiers[tier]) > 5:
            print(f'             +{len(tiers[tier])-5} more')
print()

print('FILE DETAILS')
print(f'  {\"#\":>3}  {\"File\":<40} {\"Score\":>5} {\"Tier\":<10} {\"Lines\":>5} {\"Status\":<10} {\"Agents\"}')
for i, r in enumerate(results, 1):
    agents = ','.join(sorted(r['agents'])) if r['agents'] else '-'
    print(f'  {i:>3}  {r[\"name\"]:<40} {r[\"score\"]:>5} {r[\"tier\"]:<10} {r[\"lines\"]:>5} {r[\"status\"]:<10} {agents}')
print()

if overlaps:
    print('OVERLAP MAP (Jaccard > 0.25)')
    for a, b, jacc, shared in overlaps[:10]:
        print(f'  {a} <-> {b}: {jacc:.0%} overlap ({shared} shared terms)')
    print()

print('RECOMMENDATIONS')
dead = [r for r in results if r['tier'] == 'DEAD']
bloated = [r for r in results if r['tier'] == 'BLOATED']
if dead:
    print(f'  ARCHIVE: {len(dead)} dead rules — {', '.join(r[\"name\"] for r in dead)}')
if bloated:
    print(f'  COMPRESS: {len(bloated)} bloated rules — review for condensation')
if overlaps:
    print(f'  MERGE: {len(overlaps)} file pairs with >25% keyword overlap')
retired = [r for r in results if r['status'] == 'RETIRED']
if retired:
    print(f'  REMOVE: {len(retired)} rules reference RETIRED agents — still consuming tokens every session')
"
```

## Constraints

- READ-ONLY. Do not modify any rules files.
- Do not fabricate scores. Parse actual file content.
- Jaccard similarity is approximate — shared 5+ char words, not semantic similarity.
- Token estimates use max(4 tokens/line, 0.25 tokens/char).
