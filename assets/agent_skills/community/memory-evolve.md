---
name: memory-evolve
description: Score memory files for staleness, relevance, duplication — prune/update/consolidate recommendations
version: 0.1.0
execution-mode: advisory
argument-hint: "[full | prune-only | index-check]"
category: cognitive
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- Run `MEMORY.md lines: !`eval "$("$HOME/.agents/scripts/resolve-memory.sh")"; [ -n "$RUNTIME_MEM" ] && [ -f "$RUNTIME_MEM/MEMORY.md" ] && wc -l < "$RUNTIME_MEM/MEMORY.md" || echo "0"` (limit: 200)`
- **Topic files**: Run `eval "$("$HOME/.agents/scripts/resolve-memory.sh")"; [ -n "$RUNTIME_MEM" ] && ls "$RUNTIME_MEM"/*.md 2>/dev/null | grep -v MEMORY.md | wc -l || echo "0"`

# Memory Evolution Engine

Score all memory files for staleness, relevance, duplication, and size efficiency. Produce actionable PRUNE/UPDATE/CONSOLIDATE lists. **Read-only** -- never modify memory files or MEMORY.md.

## Modes

- **full** (default): Run all scoring components, produce complete report.
- **prune-only**: Score only, output just the PRUNE list (files safe to archive/delete).
- **index-check**: Cross-reference MEMORY.md entries against filesystem only (orphans + phantoms). Fastest mode.

## Execution

### Step 1: Inventory and cross-reference

Collect all memory files and parse MEMORY.md index entries. Identify orphans (file exists, no index entry) and phantoms (index entry, no file).

```bash
eval "$("$HOME/.agents/scripts/resolve-memory.sh")"
MEMDIR="$RUNTIME_MEM"
[ -n "$MEMDIR" ] && [ -f "$MEMDIR/MEMORY.md" ] || { echo "No runtime MEMORY.md found"; exit 1; }

# All topic files (excluding MEMORY.md itself)
find "$MEMDIR" -maxdepth 1 -name '*.md' ! -name 'MEMORY.md' -printf '%f\n' 2>/dev/null | sort > /tmp/memevolve_files.txt

# All file references in MEMORY.md (extract markdown link targets and bare .md filenames)
grep -oP '[a-z0-9_-]+\.md' "$MEMDIR/MEMORY.md" 2>/dev/null | sort -u > /tmp/memevolve_index_refs.txt

# Orphans: in filesystem but not referenced in MEMORY.md
comm -23 /tmp/memevolve_files.txt /tmp/memevolve_index_refs.txt > /tmp/memevolve_orphans.txt

# Phantoms: referenced in MEMORY.md but no file on disk
comm -13 /tmp/memevolve_files.txt /tmp/memevolve_index_refs.txt > /tmp/memevolve_phantoms.txt

echo "=== FILES ==="
cat /tmp/memevolve_files.txt
echo "=== ORPHANS ==="
cat /tmp/memevolve_orphans.txt
echo "=== PHANTOMS ==="
cat /tmp/memevolve_phantoms.txt
```

If mode is `index-check`, report orphans/phantoms and stop here.

### Step 2: Score each file

Run the scoring engine. This is a single Python script that computes all four scoring dimensions for every topic file.

```python
python3 << 'PYEOF'
import os, re, math, json, subprocess, time
from pathlib import Path
from datetime import datetime

MEMDIR_CANDIDATES = [
    Path.home() / ".devin/memories",
    Path.home() / ".codex/memories",
    Path.home() / ".claude/projects/C--Users-Owner/memory",
    Path.home() / ".claude/projects/-Users-others/memory",
]
# Runtime env-var detection takes precedence over first-existing
_chisel = os.environ.get("CHISEL_SESSION_DB", "")
_claude_proj = os.environ.get("CLAUDE_PROJECT_DIR", "")
_codex_home = os.environ.get("CODEX_HOME", "")
if _chisel:
    MEMDIR = Path.home() / ".devin/memories"
elif _claude_proj and (Path(_claude_proj) / "memory" / "MEMORY.md").exists():
    MEMDIR = Path(_claude_proj) / "memory"
elif _codex_home and (Path(_codex_home) / "MEMORY.md").exists():
    MEMDIR = Path(_codex_home)
else:
    MEMDIR = next((p for p in MEMDIR_CANDIDATES if (p / "MEMORY.md").exists()), MEMDIR_CANDIDATES[0])
BUS_FILE_CANDIDATES = [
    Path.home() / ".cache" / "bus" / "messages.tsv",
]
BUS_FILE = next((p for p in BUS_FILE_CANDIDATES if p.exists()), BUS_FILE_CANDIDATES[0])
FM_ROOT = Path.home() / ".agents"
NOW = time.time()

def file_age_days(path):
    try:
        return (NOW - os.path.getmtime(path)) / 86400
    except OSError:
        return 9999

def recency_score(days):
    """Exponential decay: score = 100 * exp(-days/90)"""
    return max(0, min(100, 100 * math.exp(-days / 90)))

def extract_key_terms(filepath):
    """Extract likely key terms from a memory file (headings, bold text, identifiers)."""
    try:
        text = filepath.read_text(errors='replace')
    except OSError:
        return []
    terms = set()
    # Headings
    for m in re.finditer(r'^#+\s+(.+)', text, re.MULTILINE):
        for word in m.group(1).split():
            w = re.sub(r'[^a-zA-Z0-9_-]', '', word)
            if len(w) > 3:
                terms.add(w.lower())
    # Bold text
    for m in re.finditer(r'\*\*([^*]+)\*\*', text):
        for word in m.group(1).split():
            w = re.sub(r'[^a-zA-Z0-9_-]', '', word)
            if len(w) > 3:
                terms.add(w.lower())
    # Filename stem as term
    stem = filepath.stem.replace('_', ' ').replace('-', ' ')
    for word in stem.split():
        if len(word) > 3:
            terms.add(word.lower())
    return list(terms)[:20]  # cap at 20 terms

def relevance_score(terms):
    """Grep key terms against recent bus messages (last 100) and git log (last 50)."""
    if not terms:
        return 0
    hits = 0
    total_checks = 0

    # Bus messages (last 100 lines)
    bus_text = ""
    try:
        if BUS_FILE.exists():
            lines = BUS_FILE.read_text(errors='replace').strip().split('\n')
            bus_text = '\n'.join(lines[-100:]).lower()
    except OSError:
        pass

    # Git log (last 50 commits)
    git_text = ""
    try:
        result = subprocess.run(
            ['git', 'log', '--oneline', '-50', '--format=%s'],
            capture_output=True, text=True, timeout=10,
            cwd=str(FM_ROOT if FM_ROOT.exists() else Path.home())
        )
        git_text = result.stdout.lower()
    except (subprocess.TimeoutExpired, OSError):
        pass

    combined = bus_text + '\n' + git_text
    if not combined.strip():
        return 50  # no data to check against, neutral score

    for term in terms:
        total_checks += 1
        if term in combined:
            hits += 1

    if total_checks == 0:
        return 50
    ratio = hits / total_checks
    return min(100, int(ratio * 150))  # scale so 67% hit rate = 100

def size_efficiency_score(filepath, memdir):
    """Score based on file size vs index entry size. Flag extremes."""
    try:
        file_bytes = filepath.stat().st_size
    except OSError:
        return 0

    # Find the MEMORY.md line referencing this file
    index_line_len = 0
    try:
        memory_text = (memdir / "MEMORY.md").read_text(errors='replace')
        fname = filepath.name
        for line in memory_text.split('\n'):
            if fname in line:
                index_line_len = len(line)
                break
    except OSError:
        pass

    # Scoring logic:
    # Very small files (<200 bytes) = possibly too small, merge candidate -> 40
    # Sweet spot (200-3000 bytes) = 100
    # Large (3000-5000 bytes) = 70
    # Over 5KB = 50 (flagged)
    # No index entry at all = 30 (orphan)
    if index_line_len == 0:
        base = 30  # orphan penalty
    elif file_bytes < 200:
        base = 40
    elif file_bytes <= 3000:
        base = 100
    elif file_bytes <= 5120:
        base = 70
    else:
        base = 50

    return base

def reference_health_score(filepath):
    """Check if referenced paths and projects actually exist."""
    try:
        text = filepath.read_text(errors='replace')
    except OSError:
        return 0

    # Extract file paths (absolute)
    paths = re.findall(r'(/[A-Za-z0-9_./-]{10,})', text)
    # Extract PROJECTS/ references
    projects = re.findall(r'PROJECTS/([a-zA-Z0-9_-]+)', text)
    # Extract hummbl_governance/ references
    fm_paths = re.findall(r'hummbl_governance/([a-zA-Z0-9_/.-]+)', text)

    if not paths and not projects and not fm_paths:
        return 80  # no references to check, mildly healthy

    total = 0
    alive = 0
    home = Path.home()

    for p in paths[:10]:
        total += 1
        if Path(p).exists():
            alive += 1

    for proj in projects[:5]:
        total += 1
        if (home / "PROJECTS" / proj).exists():
            alive += 1

    for fp in fm_paths[:5]:
        total += 1
        if (FM_ROOT / fp).exists() or (home / "hummbl_governance" / fp).exists():
            alive += 1

    if total == 0:
        return 80
    return int(100 * alive / total)

# --- Main ---
results = []

if not MEMDIR.exists():
    print(json.dumps({"error": "Memory directory not found"}))
    raise SystemExit(1)

topic_files = sorted(
    f for f in MEMDIR.glob("*.md") if f.name != "MEMORY.md"
)

memory_md = MEMDIR / "MEMORY.md"
memory_lines = 0
try:
    memory_lines = len(memory_md.read_text(errors='replace').strip().split('\n'))
except OSError:
    pass

for tf in topic_files:
    days = file_age_days(tf)
    terms = extract_key_terms(tf)

    s_recency = recency_score(days)
    s_relevance = relevance_score(terms)
    s_size = size_efficiency_score(tf, MEMDIR)
    s_refhealth = reference_health_score(tf)

    weighted = (
        0.25 * s_recency +
        0.30 * s_relevance +
        0.20 * s_size +
        0.25 * s_refhealth
    )

    if weighted >= 80:
        tier = "THRIVING"
    elif weighted >= 50:
        tier = "HEALTHY"
    elif weighted >= 25:
        tier = "STALE"
    else:
        tier = "DEAD"

    file_bytes = 0
    try:
        file_bytes = tf.stat().st_size
    except OSError:
        pass

    results.append({
        "file": tf.name,
        "composite": round(weighted, 1),
        "recency": round(s_recency, 1),
        "relevance": round(s_relevance, 1),
        "size_eff": round(s_size, 1),
        "ref_health": round(s_refhealth, 1),
        "tier": tier,
        "age_days": round(days, 1),
        "bytes": file_bytes,
        "over_5kb": file_bytes > 5120,
    })

# Sort by composite score ascending (worst first)
results.sort(key=lambda r: r["composite"])

output = {
    "memory_lines": memory_lines,
    "topic_count": len(topic_files),
    "results": results,
}
print(json.dumps(output))
PYEOF
```

### Step 3: Generate report

Read the JSON output from Step 2 and the orphan/phantom lists from Step 1. Assemble the final report in the required format.

```python
python3 << 'PYEOF'
import json, sys
from pathlib import Path

def read_list(path):
    try:
        return [l.strip() for l in Path(path).read_text().strip().split('\n') if l.strip()]
    except OSError:
        return []

orphans = read_list("/tmp/memevolve_orphans.txt")
phantoms = read_list("/tmp/memevolve_phantoms.txt")

try:
    data = json.loads(Path("/tmp/memevolve_scores.json").read_text())
except (OSError, json.JSONDecodeError):
    print("ERROR: Scoring data not found. Run Step 2 first.")
    sys.exit(1)

ml = data["memory_lines"]
tc = data["topic_count"]
results = data["results"]

tiers = {"THRIVING": [], "HEALTHY": [], "STALE": [], "DEAD": []}
for r in results:
    tiers[r["tier"]].append(r)

if ml <= 180:
    idx_status = "OK"
elif ml <= 200:
    idx_status = "WARNING"
else:
    idx_status = "OVER_LIMIT"

print(f"Memory Evolution Engine | {tc} files | MEMORY.md: {ml}/200 lines")
print("=" * 68)
print()
print("INDEX HEALTH")
print(f"  MEMORY.md: {ml} lines (limit 200) -- [{idx_status}]")
print(f"  Topic files: {tc}")
print(f"  Orphans (file exists, no index entry): {orphans if orphans else ['none']}")
print(f"  Phantoms (index entry, no file): {phantoms if phantoms else ['none']}")
print()
print("TIER SUMMARY")
for tier_name in ["THRIVING", "HEALTHY", "STALE", "DEAD"]:
    files = tiers[tier_name]
    names = ", ".join(r["file"] for r in files) if files else "(none)"
    print(f"  {tier_name:10s} ({len(files)}): {names}")
print()

if tiers["STALE"] or tiers["DEAD"]:
    print("DETAIL (STALE + DEAD)")
    for r in tiers["STALE"] + tiers["DEAD"]:
        flags = []
        if r["over_5kb"]:
            flags.append(">5KB")
        if r["ref_health"] < 30:
            flags.append("DEAD_REFS")
        if r["age_days"] > 180:
            flags.append(f"AGED_{int(r['age_days'])}d")
        flag_str = f" [{', '.join(flags)}]" if flags else ""
        print(f"  {r['file']:50s} score={r['composite']:5.1f}  "
              f"rec={r['recency']:.0f} rel={r['relevance']:.0f} "
              f"size={r['size_eff']:.0f} ref={r['ref_health']:.0f}{flag_str}")
    print()

oversized = [r for r in results if r["over_5kb"]]
if oversized:
    print("SIZE WARNINGS (>5KB)")
    for r in oversized:
        print(f"  {r['file']} -- {r['bytes']} bytes")
    print()

print("TOP FINDINGS")
prune = [r["file"] for r in tiers["DEAD"]]
print(f"  PRUNE: {prune if prune else ['(none -- no DEAD-tier files)']}")
update = [r["file"] for r in tiers["STALE"]]
print(f"  UPDATE: {update if update else ['(none -- no STALE-tier files)']}")
consolidate = [r["file"] for r in results if r["bytes"] < 200 and r["tier"] in ("HEALTHY", "STALE")]
print(f"  CONSOLIDATE: {consolidate if consolidate else ['(none -- no merge candidates)']}")

print()
print("MEMORY.md COMPRESSION")
dead_entries = [r["file"] for r in tiers["DEAD"]] + phantoms
print(f"  Lines to remove: {dead_entries if dead_entries else ['(none)']}")

memdir = next(
    (
        p for p in [
            Path.home() / ".devin/memories",
            Path.home() / ".codex/memories",
            Path.home() / ".claude/projects/C--Users-Owner/memory",
            Path.home() / ".claude/projects/-Users-others/memory",
        ]
        if (p / "MEMORY.md").exists()
    ),
    Path.home() / ".devin/memories",
)
long_lines = []
try:
    for i, line in enumerate(memdir.joinpath("MEMORY.md").read_text(errors='replace').split('\n'), 1):
        if len(line) > 150:
            long_lines.append(f"L{i} ({len(line)} chars)")
except OSError:
    pass
print(f"  Lines to shorten (>150 chars): {long_lines if long_lines else ['(none)']}")
projected = ml - len(dead_entries)
print(f"  Projected line count after cleanup: {projected}")
PYEOF
```

### Combined execution (preferred)

In practice, run Steps 1-3 as a single pipeline to avoid temp-file coordination. The executor should:

1. Run the Step 1 bash commands for orphan/phantom detection
2. Run the Step 2 Python scoring (capture JSON output to `/tmp/memevolve_scores.json`)
3. Run the Step 3 Python formatter

## Scoring Components

| Component | Weight | Method |
|-----------|--------|--------|
| Recency | 0.25 | `100 * exp(-days_since_modified / 90)` -- 90-day half-life |
| Relevance | 0.30 | Key terms grepped against last 100 bus messages + last 50 git commits |
| Size efficiency | 0.20 | File bytes vs index entry presence. Sweet spot: 200-3000 bytes |
| Reference health | 0.25 | Check if referenced file paths, PROJECTS/ dirs, and hummbl_governance/ paths exist |

## Tier Definitions

| Tier | Score Range | Meaning |
|------|-------------|---------|
| THRIVING | 80-100 | Recently updated, actively referenced, paths alive |
| HEALTHY | 50-79 | Still relevant, may need refresh |
| STALE | 25-49 | Not referenced recently, validity uncertain |
| DEAD | 0-24 | Broken paths, completed projects, or info now in code/git |

## Rules

- **Read-only**. This skill never modifies memory files or MEMORY.md.
- **No fabricated scores**. Every score derives from actual file inspection (mtime, grep hits, path existence checks).
- **Flag files over 5KB** as potentially too large for memory system efficiency.
- After running, consider: `[memory-registry]` to act on recommendations, `[ledger]` to persist findings.

## Output Header

```
Memory Evolution Engine | <context from arguments>
```

## Next Action

Report findings. Suggest specific `[memory-registry]` operations for any PRUNE or CONSOLIDATE items. No further action needed unless user promotes to remedial.
