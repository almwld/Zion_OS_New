---
name: rsi-dashboard
description: Recursive self-improvement metrics and system compounding signals.
version: 0.1.0
execution-mode: advisory
argument-hint: "[summary | weekly | skill SKILL_NAME]"
category: fleet-ops
status: candidate
---
# RSI Dashboard — Recursive Self-Improvement Metrics

Measure whether the system is compounding or just accumulating.

## When to Use
- Weekly review: "how's the system improving?"
- After retrospectives: check if learnings are being reused
- After skill creation: verify new skills get invoked
- Anytime: "are we getting better?"

## Data Sources

### 1. Skill Telemetry (primary)
TSV file at `~/.claude/telemetry/skill-usage.tsv` (Windows) or `~/$PROJECT_ROOT/_state/telemetry/skill-usage.tsv` (local machine).

Columns: `timestamp_utc`, `skill`, `args`, `machine`, `session_id`

Populated by the `post-skill-telemetry.sh` PostToolUse hook.

### 2. Tool Audit Log (secondary)
JSONL file at `~/.agents/audit-reports/tool-usage.jsonl`.

Columns: `ts`, `tool`, `input_summary`

### 3. Skill Index
Skill count from `~/.agents/skills/` directory.

### 4. Memory Files
Memory count from project memory directories.

### 5. Bus Messages (local machine only)
`~/$PROJECT_ROOT/_state/coordination/messages.tsv` for agent activity.

## Metrics to Compute

### Tier 1 — Instrumented (from telemetry)
```bash
# On this machine:
TFILE="$HOME/.claude/telemetry/skill-usage.tsv"
# On local machine via SSH:
# TFILE="~/$PROJECT_ROOT/_state/telemetry/skill-usage.tsv"

echo "=== Skill Invocation Frequency ==="
# Top 10 most-used skills (excludes header)
tail -n +2 "$TFILE" 2>/dev/null | cut -f2 | sort | uniq -c | sort -rn | head -10

echo "=== Daily Invocation Rate ==="
# Invocations per day
tail -n +2 "$TFILE" 2>/dev/null | cut -f1 | cut -dT -f1 | sort | uniq -c | sort

echo "=== Machine Distribution ==="
tail -n +2 "$TFILE" 2>/dev/null | cut -f4 | sort | uniq -c | sort -rn

echo "=== Session Density ==="
# Skills per session (higher = more skill reuse per session)
tail -n +2 "$TFILE" 2>/dev/null | cut -f5 | sort | uniq -c | sort -rn | head -10

echo "=== Unique Skills Used ==="
tail -n +2 "$TFILE" 2>/dev/null | cut -f2 | sort -u | wc -l

echo "=== Never-Used Skills ==="
# Compare invoked skills vs available skills
AVAILABLE=$(ls ~/.agents/skills/ | grep -v _index)
USED=$(tail -n +2 "$TFILE" 2>/dev/null | cut -f2 | sort -u)
comm -23 <(echo "$AVAILABLE") <(echo "$USED") | head -20
echo "... (showing first 20)"

echo "=== Skill Adoption Curve ==="
# New skills appearing for the first time, by date
tail -n +2 "$TFILE" 2>/dev/null | sort -t$'\t' -k1,1 | awk -F'\t' '!seen[$2]++ {print $1, $2}' | head -20
```

### Tier 2 — Derived (trend analysis)
```bash
echo "=== Weekly Velocity ==="
# Skills invoked per week
tail -n +2 "$TFILE" 2>/dev/null | cut -f1 | cut -dT -f1 | \
  awk '{y=substr($1,1,4); m=substr($1,6,2); d=substr($1,9,2); \
  cmd="date -d \""$1"\" +%G-W%V 2>/dev/null || date -j -f %Y-%m-%d \""$1"\" +%G-W%V 2>/dev/null"; \
  cmd | getline week; close(cmd); print week}' | sort | uniq -c

echo "=== Skill Diversity Index ==="
# Shannon entropy of skill usage (higher = more diverse use)
TOTAL=$(tail -n +2 "$TFILE" 2>/dev/null | wc -l)
if [ "$TOTAL" -gt 0 ]; then
  tail -n +2 "$TFILE" 2>/dev/null | cut -f2 | sort | uniq -c | \
    awk -v total="$TOTAL" '{p=$1/total; entropy += -p*log(p)/log(2)} END {printf "Shannon entropy: %.2f bits (max %.2f for %d skills)\n", entropy, log(NR)/log(2), NR}'
fi

echo "=== System Growth ==="
echo "Skills available: $(ls ~/.agents/skills/ | grep -v _index | wc -l)"
echo "Memory files: $(eval "$("$HOME/.agents/scripts/resolve-memory.sh")"; ls ${RUNTIME_MEM:+$RUNTIME_MEM/*.md} "$FLEET_MEM" 2>/dev/null | wc -l)"
echo "Audit log entries: $(wc -l < ~/.agents/audit-reports/tool-usage.jsonl 2>/dev/null || echo 0)"
echo "Telemetry entries: $(tail -n +2 "$TFILE" 2>/dev/null | wc -l)"
```

### Tier 3 — RSI Health Score
Compute a composite score (0-100) based on:

| Metric | Weight | Score Logic |
|--------|--------|-------------|
| Skill reuse rate | 25% | % of available skills invoked at least once in last 30 days |
| Session density | 20% | Avg skills per session (target: 3+) |
| Diversity index | 15% | Shannon entropy / max entropy |
| Adoption speed | 15% | Days from skill creation to first invocation (lower = better) |
| Error half-life | 15% | Sessions between guardrail trigger and encoded fix (lower = better) |
| Knowledge persistence | 10% | % of retrospective findings that appear in ledger or memory |

**Interpretation:**
- 0-30: Accumulating (lots of stuff, not compounding)
- 31-60: Early compounding (skills being reused, patterns encoding)
- 61-80: Strong RSI (system measurably accelerating)
- 81-100: Flywheel (self-sustaining improvement loop)

## Cross-Machine Aggregation

To get a unified view across all machines:
```bash
echo "=== Aggregated Telemetry ==="
# Local data
LOCAL=$(tail -n +2 "$HOME/.claude/telemetry/skill-usage.tsv" 2>/dev/null | wc -l)
# local machine data (via SSH)
local machine=$(ssh mbp "tail -n +2 ~/$PROJECT_ROOT/_state/telemetry/skill-usage.tsv 2>/dev/null | wc -l" 2>/dev/null || echo 0)
echo "Windows: $LOCAL invocations"
echo "local machine: $local machine invocations"
echo "Total: $((LOCAL + local machine)) invocations"

# Merge and analyze
{ tail -n +2 "$HOME/.claude/telemetry/skill-usage.tsv" 2>/dev/null; \
  ssh -o ConnectTimeout=10 mbp "tail -n +2 ~/$PROJECT_ROOT/_state/telemetry/skill-usage.tsv 2>/dev/null" 2>/dev/null; } | \
  cut -f2 | sort | uniq -c | sort -rn | head -15
```

## Output Format
```
RSI Dashboard | <date>
═══════════════════════

## Telemetry Summary
- Total invocations: N (Windows: X, local machine: Y)
- Unique skills used: N / M available (Z% reuse rate)
- Avg skills/session: N
- Most-used: skill1 (N), skill2 (N), skill3 (N)

## Trend (last 7 days)
- Daily rate: N invocations/day (↑/↓ vs prior week)
- New skills adopted: [list]
- Never-used skills: N (top 5: ...)

## RSI Health Score: NN/100 — [Accumulating|Compounding|Strong RSI|Flywheel]

## Recommendations
- [Actionable items based on metrics]

## Raw Metrics
[Tier 1 + Tier 2 output]
```

## Skill Chains
| After completing... | Consider... |
|--------------------|-----------------------|
| `[rsi-dashboard]` | `[retrospective]` (reflect on what to improve), `[skill-create]` (if gap found) |
| `[weekly-review]` | `[rsi-dashboard]` (measure system health) |
| `[retrospective]` | `[rsi-dashboard]` (verify learnings are encoding) |

## Base120 Mapping
- **SY5** (Feedback Loops) — the dashboard IS the feedback signal for the RSI loop
- **DE7** (Pareto 80/20) — identify which 20% of skills drive 80% of value
- **RE13** (Velocity) — measure whether the system is accelerating
