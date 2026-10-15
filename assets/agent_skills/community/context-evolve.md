---
name: context-evolve
description: Measure token cost of every auto-injected file — rank by cost-per-relevance, suggest compression
version: 0.1.0
execution-mode: advisory
argument-hint: "[full | budget-only | top-consumers]"
category: hummbl-research
status: candidate
---
# Context Evolution Engine

Measure the token cost of every file that is auto-injected into Claude Code sessions. Rank by cost-per-relevance. Identify files that consume disproportionate context budget relative to how often they're actually useful.

## When to Use
- Context window feels tight (autocompact triggering early)
- After adding new rules files or expanding CLAUDE.md
- Monthly context budget audit
- Before deciding to split or merge configuration files

## Background

Every Claude Code session auto-injects:
- `CLAUDE.md` (project instructions)
- `CLAUDE.local.md` (machine-specific overrides)
- `~/.agents/rules/*.md` (all rules files — unconditionally)
- `MEMORY.md` (first 200 lines of memory index)
- Session-start hook output

Each line of injected content costs ~4 tokens. With a 200K effective context window (after system prompt), every unnecessary line reduces space for actual work.

## Execution

### Run the budget analysis

```bash
cd $HOME && python3 -c "
import os, glob

# === Configuration ===
TOKEN_PER_LINE = 4  # rough estimate for markdown
TOKEN_PER_CHAR = 0.25  # alternative estimate

# === 1. Enumerate all auto-injected files ===
injected_files = {}

# CLAUDE.md files
for f in ['CLAUDE.md', 'CLAUDE.local.md']:
    path = os.path.join('$HOME', f)
    if os.path.isfile(path):
        injected_files[f] = path

# Rules files
rules_dir = os.path.expanduser('~/.agents/rules/')
for f in sorted(glob.glob(os.path.join(rules_dir, '*.md'))):
    name = 'rules/' + os.path.basename(f)
    injected_files[name] = f

# MEMORY.md (first 200 lines) — resolve via runtime env vars
_chisel = os.environ.get('CHISEL_SESSION_DB', '')
_claude_proj = os.environ.get('CLAUDE_PROJECT_DIR', '')
_codex_home = os.environ.get('CODEX_HOME', '')
if _chisel:
    mem_path = os.path.expanduser('~/.devin/memories/MEMORY.md')
elif _claude_proj:
    mem_path = os.path.join(_claude_proj, 'memory', 'MEMORY.md')
elif _codex_home:
    mem_path = os.path.join(_codex_home, 'MEMORY.md')
else:
    # Fallback: first existing runtime memory MEMORY.md
    mem_path = None
    for _c in ['~/.devin/memories', '~/.codex', '~/.claude/projects/-Users-others/memory', '~/.agents/memory']:
        _p = os.path.expanduser(_c + '/MEMORY.md')
        if os.path.isfile(_p):
            mem_path = _p
            break
    if mem_path is None:
        mem_path = os.path.expanduser('~/.devin/memories/MEMORY.md')
if os.path.isfile(mem_path):
    injected_files['MEMORY.md (200-line cap)'] = mem_path

# === 2. Measure each file ===
results = []
total_lines = 0
total_chars = 0

for name, path in injected_files.items():
    try:
        with open(path) as fh:
            content = fh.read()
        lines = content.count('\n') + (1 if content and not content.endswith('\n') else 0)
        chars = len(content)
        
        # For MEMORY.md, cap at 200 lines
        if 'MEMORY' in name:
            actual_lines = lines
            lines = min(lines, 200)
            chars = len('\n'.join(content.split('\n')[:200]))
        
        tokens_by_line = lines * TOKEN_PER_LINE
        tokens_by_char = int(chars * TOKEN_PER_CHAR)
        est_tokens = max(tokens_by_line, tokens_by_char)  # use higher estimate
        
        results.append({
            'name': name,
            'lines': lines,
            'chars': chars,
            'est_tokens': est_tokens,
            'bytes': os.path.getsize(path),
        })
        total_lines += lines
        total_chars += chars
    except Exception as e:
        results.append({'name': name, 'lines': 0, 'chars': 0, 'est_tokens': 0, 'bytes': 0, 'error': str(e)})

# Sort by estimated tokens descending
results.sort(key=lambda r: -r['est_tokens'])

total_tokens = sum(r['est_tokens'] for r in results)

# === 3. Output ===
print('=' * 72)
print(f'Context Evolution Engine | {len(results)} injected files | ~{total_tokens:,} tokens/session')
print('=' * 72)
print()

print('BUDGET SUMMARY')
print(f'  Total auto-injected files: {len(results)}')
print(f'  Total lines: {total_lines:,}')
print(f'  Total characters: {total_chars:,}')
print(f'  Estimated tokens per session: ~{total_tokens:,}')
print(f'  Context budget impact: ~{total_tokens/200000*100:.1f}% of 200K window')
print()

print('FILE RANKING (by token cost)')
print(f'  {\"#\":>3}  {\"File\":<45} {\"Lines\":>6} {\"Tokens\":>7} {\"Share\":>6}')
print(f'  {\"---\":>3}  {\"-\"*45:<45} {\"------\":>6} {\"-------\":>7} {\"------\":>6}')
for i, r in enumerate(results, 1):
    share = r['est_tokens'] / total_tokens * 100 if total_tokens > 0 else 0
    print(f'  {i:>3}  {r[\"name\"]:<45} {r[\"lines\"]:>6} {r[\"est_tokens\"]:>7} {share:>5.1f}%')
print()

# === 4. Identify optimization targets ===
print('OPTIMIZATION TARGETS')

# Files consuming >10% of budget
heavy = [r for r in results if r['est_tokens'] / total_tokens > 0.10] if total_tokens > 0 else []
if heavy:
    print(f'  HEAVY (>10% of budget):')
    for r in heavy:
        share = r['est_tokens'] / total_tokens * 100
        print(f'    {r[\"name\"]} — {r[\"est_tokens\"]:,} tokens ({share:.1f}%)')
    print()

# Rules files that could be conditional
rules_files = [r for r in results if r['name'].startswith('rules/')]
if rules_files:
    rules_tokens = sum(r['est_tokens'] for r in rules_files)
    print(f'  RULES TOTAL: {len(rules_files)} files, {rules_tokens:,} tokens ({rules_tokens/total_tokens*100:.1f}% of budget)')
    print(f'  If conditional loading existed, only session-relevant rules would load.')
    print()

# MEMORY.md over-limit check
mem = [r for r in results if 'MEMORY' in r['name']]
if mem:
    mem_path_check = injected_files.get('MEMORY.md (200-line cap)')
    if not mem_path_check:
        mem_path_check = os.path.expanduser('~/.devin/memories/MEMORY.md')
    with open(mem_path_check) as fh:
        actual_lines = fh.read().count('\n')
    if actual_lines > 200:
        print(f'  MEMORY.md: {actual_lines} lines (OVER 200-line cap — {actual_lines - 200} lines truncated)')
    else:
        print(f'  MEMORY.md: {actual_lines} lines (within 200-line cap)')
    print()

print('RECOMMENDATIONS')
if heavy:
    print(f'  COMPRESS: {len(heavy)} files consume >10% each — review for redundancy')
if total_tokens > 15000:
    print(f'  WARNING: {total_tokens:,} tokens is >{15000:,} — consider pruning low-value rules')
if total_tokens <= 15000:
    print(f'  OK: {total_tokens:,} tokens is within reasonable budget (<15K)')
print(f'  STRATEGY: Rules are unconditionally loaded. Conditional loading (per-agent, per-task) would reduce budget by ~30-50%.')
print(f'  NOTE: Token estimates are approximate (max of 4 tokens/line and 0.25 tokens/char).')
"
```

## Output Format

```
Context Evolution Engine | N injected files | ~T tokens/session
========================================================================

BUDGET SUMMARY
  Total auto-injected files: N
  Total lines: L
  Estimated tokens per session: ~T
  Context budget impact: ~X% of 200K window

FILE RANKING (by token cost)
    #  File                                          Lines  Tokens   Share
    1  skill-routing.md                                609    2436   22.1%
    ...

OPTIMIZATION TARGETS
  HEAVY (>10% of budget): ...
  RULES TOTAL: ...
  MEMORY.md: ...

RECOMMENDATIONS
  COMPRESS: ...
  STRATEGY: ...
```

## Constraints

- READ-ONLY. Do not modify any files.
- Token estimates are approximate — use as relative ranking, not absolute counts.
- The 200K context window is a rough figure; actual available space depends on system prompt size.
- Do not count skill SKILL.md files — those are loaded on-demand, not auto-injected.

## Skill Chains
- For measure Neuron cost of Cloudflare model token usage -> `[usage-monitor]` (`python ~/bin/usage_monitor.py status`)
