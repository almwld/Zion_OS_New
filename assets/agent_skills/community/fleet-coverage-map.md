---
name: fleet-coverage-map
description: Map task categories to skills and find capability gaps — tasks that no skill covers. Surfaces whitespace where new skills should be created.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--category <cat>] [--gaps-only]"
category: dev-tools
status: candidate
providers:
  required: [python]
---
# fleet-coverage-map

Build a matrix of task categories vs installed skills to find capability gaps.
Each skill is classified by its primary category (from frontmatter description
and "When to Use" section). Categories with zero or one skill are gap candidates.

## When to Use

- When planning a skill creation sprint (what should we build next?)
- After `[skill-evolve]` surfaces underused skills (are they in sparse categories?)
- When an operator asks "what capabilities are we missing?"
- Before `[find-skills]` to understand if a capability gap exists vs a routing problem
- Quarterly fleet health review

## Usage

```bash
[fleet-coverage-map]                # Full coverage matrix + gap analysis
[fleet-coverage-map] --gaps-only    # Only show categories with <2 skills
[fleet-coverage-map] --category X   # Deep dive on category X
```

## Scripts

This skill includes executable analysis scripts in `scripts/`:

| Script | Purpose | Output |
|--------|---------|--------|
| `scripts/graph-analysis.py` | Skill dependency graph: components, max depth, cycle detection | JSON: total_skills, components, max_depth, cycles |
| `scripts/routing-analysis.py` | Routing distribution: entropy, Gini, ambiguous triggers | JSON: trigger_entropy, trigger_gini, ambiguous_trigger_words |
| `scripts/coverage-map.py` | Category coverage and gap analysis | JSON: categories, gap_categories, unclassified |

Run individually:
```bash
python3 scripts/graph-analysis.py
python3 scripts/routing-analysis.py
python3 scripts/coverage-map.py
```

## Execution

### 1. Define task categories

```python
CATEGORIES = {
    "dev-workflow": "test, build, commit, branch, code-quality",
    "ops-monitoring": "health, services, logs, alerts, deploy, incidents",
    "agent-coordination": "bus, dispatch, delegate, audit, fleet",
    "code-quality": "audit, refactor, clean, dead-code, complexity",
    "research-analysis": "search, compare, synthesize, evidence, citations",
    "business-strategy": "pitch, runway, investor, revenue, pipeline",
    "product-mgmt": "stories, prioritize, scope, roadmap, PRD",
    "security-compliance": "scan, threat, legal, nist, soc2, gdpr",
    "architecture": "API, MCP, diagram, dependency, design",
    "cognition-memory": "ledger, memory, decision, RSI, learning",
    "session-meta": "tempo, context, handoff, start, end, gm",
    "content-marketing": "blog, social, newsletter, SEO, copy",
    "data-ml": "dataset, model, train, evaluate, RAG, embeddings",
    "cloudflare": "workers, KV, R2, D1, pages, DNS, email",
    "legal-hr": "contracts, agreements, offers, policies, NDAs",
    "skill-lifecycle": "create, test, audit, evolve, merge, archive",
    "governance": "frameworks, risk, compliance, policies, board",
    "ux-design": "accessibility, UI, UX, flows, design-system",
    "financial": "budget, forecast, cap-table, burn, expenses",
    "communication": "email, discord, signal, telegram, stakeholder",
}
```

### 2. Classify each skill

```bash
cd $HOME && python3 -c "
import os, re, glob, json
from collections import defaultdict

CATEGORIES = {
    'dev-workflow': ['test', 'build', 'commit', 'branch', 'code-quality', 'tdd', 'debug', 'flake', 'coverage'],
    'ops-monitoring': ['health', 'service', 'log', 'alert', 'deploy', 'incident', 'monitor', 'uptime', 'sla', 'slo', 'cron'],
    'agent-coordination': ['bus', 'dispatch', 'delegate', 'audit', 'fleet', 'agent', 'swarm', 'subagent', 'coordination'],
    'code-quality': ['audit', 'refactor', 'clean', 'dead-code', 'complexity', 'lint', 'type-check', 'import', 'deslop'],
    'research-analysis': ['search', 'compare', 'synthes', 'evidence', 'citation', 'research', 'bibliometric', 'meta-analysis', 'systematic'],
    'business-strategy': ['pitch', 'runway', 'investor', 'revenue', 'pipeline', 'competitive', 'market', 'icp', 'deal'],
    'product-mgmt': ['story', 'prioritize', 'scope', 'roadmap', 'prd', 'okr', 'kpi', 'sprint', 'rice'],
    'security-compliance': ['scan', 'threat', 'legal', 'nist', 'soc2', 'gdpr', 'hipaa', 'security', 'redteam', 'blueteam', 'wargame'],
    'architecture': ['api', 'mcp', 'diagram', 'dependency', 'design', 'arch', 'rfc', 'adr', 'concept-map'],
    'cognition-memory': ['ledger', 'memory', 'decision', 'rsi', 'learning', 'note', 'insight', 'cognitive'],
    'session-meta': ['tempo', 'context', 'handoff', 'start', 'end', 'gm', 'session', 'sitrep', 'thoth', 'seshat'],
    'content-marketing': ['blog', 'social', 'newsletter', 'seo', 'copy', 'content', 'thread', 'press', 'changelog-post'],
    'data-ml': ['dataset', 'model', 'train', 'evaluate', 'rag', 'embedding', 'ml', 'bias', 'quantize', 'distill'],
    'cloudflare': ['worker', 'kv', 'r2', 'd1', 'pages', 'dns', 'email', 'turnstile', 'wrangler', 'cloudflare'],
    'legal-hr': ['contract', 'agreement', 'offer', 'policy', 'nda', 'hr', 'job', 'performance', 'contractor'],
    'skill-lifecycle': ['skill-create', 'skill-test', 'skill-audit', 'skill-evolve', 'skill-merge', 'skill-diff', 'skill-deps', 'skill-collision', 'skill-export', 'skill-promote', 'skill-demote', 'skill-archive', 'chain', 'routing'],
    'governance': ['framework', 'risk', 'compliance', 'policy', 'board', 'governance', 'gap-analysis', 'remediation', 'audit-prep', 'control'],
    'ux-design': ['accessibility', 'a11y', 'ui', 'ux', 'flow', 'design-system', 'color', 'contrast', 'aria', 'keyboard'],
    'financial': ['budget', 'forecast', 'cap-table', 'burn', 'expense', 'invoice', 'cashflow', 'revenue', 'unit-economics'],
    'communication': ['email', 'discord', 'signal', 'telegram', 'stakeholder', 'send-', 'async-update', 'internal-comms'],
}

category_map = defaultdict(list)

for path in sorted(glob.glob(os.path.expanduser('~/.agents/skills/*/SKILL.md'))):
    skill_name = os.path.basename(os.path.dirname(path))
    with open(path, errors='replace') as f:
        content = f.read(8192)
    # Extract description
    desc_match = re.search(r'^description:\s*(.+)', content, re.M)
    desc = desc_match.group(1).strip('\"').lower() if desc_match else ''
    # Classify
    text = (skill_name + ' ' + desc).lower()
    best_cat = None
    best_score = 0
    for cat, keywords in CATEGORIES.items():
        score = sum(1 for kw in keywords if kw in text)
        if score > best_score:
            best_score = score
            best_cat = cat
    if best_cat:
        category_map[best_cat].append(skill_name)
    else:
        category_map['uncategorized'].append(skill_name)

# Print coverage matrix
print('CATEGORY\tCOUNT\tSKILLS')
for cat in sorted(CATEGORIES.keys()) + ['uncategorized']:
    skills = sorted(category_map.get(cat, []))
    print(f'{cat}\t{len(skills)}\t{\", \".join(skills[:8])}{\" ...\" if len(skills) > 8 else \"\"}')

# Find gaps
print()
print('GAP CATEGORIES (<3 skills):')
for cat in sorted(CATEGORIES.keys()):
    count = len(category_map.get(cat, []))
    if count < 3:
        print(f'  {cat}: {count} skills — {sorted(category_map.get(cat, []))}')
" 2>&1
```

### 3. Surface gap recommendations

For each gap category (<3 skills):
- Is this a real gap or a niche that doesn't need more skills?
- What common tasks in this category have no skill?
- Suggest 1-2 new skill concepts to fill the gap

## Output Format

```
fleet-coverage-map | <date>
══════════════════════════════════════════

Coverage Matrix:
  <category>: N skills — <top skills>
  ...

Gap Categories (<3 skills):
  <category>: N skills — SUGGEST: <new skill concept>
  ...

Total skills: N | Categories: M | Gaps: K

Verdict: WELL-COVERED | K GAPS FOUND
Next: [skill-create] to fill gaps, [skill-evolve] to rebalance over-covered categories
```

## Skill Chains

### Mandatory

None — read-only analysis.

### Advisory

- After `[fleet-coverage-map]` → `[skill-create]` to fill identified gaps
- Before `[skill-create]` → `[fleet-coverage-map]` to verify the gap is real
- After `[skill-evolve]` → `[fleet-coverage-map]` to see if retirements created gaps
- After `[skill-archive]` → `[fleet-coverage-map]` to check if archival created a gap
- Pair with `[skill-selection-eval]` to measure if gap-filling improved selection difficulty

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction
- **T3 (Medium)**: May run without restriction
- **T4 (Probationary)**: May run (read-only)
- **Operator**: Override any restriction
