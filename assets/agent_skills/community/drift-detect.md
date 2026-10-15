---
name: drift-detect
description: Detect behavioral drift in agent outputs over time — trending analysis of bus messages, commit patterns, output quality
version: 1.0.0
execution-mode: advisory
argument-hint: "[agent-name] [--days 7]"
category: dev-tools
status: candidate
---
# Drift Detect

Detect behavioral drift in agent outputs by analyzing bus message patterns over sliding windows. Compares recent behavior against historical baseline to flag frequency changes, type distribution shifts, and topic anomalies.

## Arguments

- `$ARGUMENTS` parsed as: `[agent-name] [--days N]`
- If no agent specified, analyze ALL agents
- Default window: 7 days (baseline: all prior history)

## Context Gathering

Before executing this skill, gather the following context:
- Run `wc -l _state/coordination/messages.tsv`
- Run `tail -1 _state/coordination/messages.tsv | cut -f1`

## Workflow

### 1. Extract Agent Activity

```bash
# All messages for a specific agent (replace AGENT with target)
awk -F'\t' 'NR>1 && $2 == "AGENT"' _state/coordination/messages.tsv > /tmp/drift_agent.tsv

# Or all agents — get unique agent names and counts
awk -F'\t' 'NR>1 { print $2 }' _state/coordination/messages.tsv | sort | uniq -c | sort -rn
```

### 2. Compute Message Frequency by Day

```bash
# Daily message counts per agent (recent window vs baseline)
awk -F'\t' 'NR>1 {
  split($1, d, "T")
  day = d[1]
  agent = $2
  counts[agent][day]++
}
END {
  for (a in counts)
    for (d in counts[a])
      print a "\t" d "\t" counts[a][d]
}' _state/coordination/messages.tsv | sort -t$'\t' -k1,1 -k2,2
```

### 3. Type Distribution Shift

```bash
# Message type distribution per agent — baseline vs recent
awk -F'\t' -v cutoff="YYYY-MM-DD" 'NR>1 {
  agent = $2; mtype = $4
  if ($1 < cutoff"T00:00:00Z") base[agent][mtype]++
  else                          recent[agent][mtype]++
}
END {
  for (a in base) {
    total_b = 0; total_r = 0
    for (t in base[a]) total_b += base[a][t]
    for (t in recent[a]) total_r += recent[a][t]
    if (total_r == 0) continue
    print "--- " a " ---"
    for (t in base[a]) {
      b_pct = (base[a][t] / total_b) * 100
      r_pct = (recent[a][t]+0) / total_r * 100
      delta = r_pct - b_pct
      flag = (delta > 15 || delta < -15) ? " *** DRIFT" : ""
      printf "  %-12s  base:%5.1f%%  recent:%5.1f%%  delta:%+.1f%%%s\n", t, b_pct, r_pct, delta, flag
    }
  }
}' _state/coordination/messages.tsv
```

### 4. Topic / Content Drift (keyword frequency)

```bash
# Extract top words from message column, compare windows
awk -F'\t' -v cutoff="YYYY-MM-DD" 'NR>1 && $2 == "AGENT" {
  n = split($5, words, " ")
  for (i=1; i<=n; i++) {
    w = tolower(words[i])
    gsub(/[^a-z0-9]/, "", w)
    if (length(w) > 3) {
      if ($1 < cutoff"T00:00:00Z") base[w]++
      else recent[w]++
    }
  }
}
END {
  for (w in recent) if (recent[w] >= 3 && !(w in base))
    print "NEW_TOPIC: " w " (" recent[w] " occurrences)"
  for (w in base) if (base[w] >= 3 && !(w in recent))
    print "DROPPED_TOPIC: " w " (was " base[w] " occurrences)"
}' _state/coordination/messages.tsv
```

### 5. Commit Pattern Drift (if agent has commits)

```bash
# Compare commit frequency and size for an agent's branches
git log --all --author="AGENT" --since="14 days ago" --format="%H %ai" --shortstat | \
  awk '/^[0-9a-f]/ { date=$2 } [files]? changed/ { print date, $0 }'
```

## Output Format

```
Drift Detect | AGENT | YYYY-MM-DD

## Message Frequency
  Day         Count   Sparkline
  2026-03-24  12      ████████████
  2026-03-25  15      ███████████████
  2026-03-26  8       ████████
  2026-03-27  3       ███        <-- drop
  2026-03-28  2       ██         <-- drop
  2026-03-29  14      ██████████████
  Baseline avg: 11.2/day | Recent avg: 7.3/day | Delta: -34.8%

## Type Distribution Shift
  Type         Baseline    Recent      Delta
  STATUS       45.2%       62.1%       +16.9% *** DRIFT
  PROPOSAL     22.1%       8.3%        -13.8%
  ACK          18.7%       20.5%       +1.8%
  SITREP       14.0%       9.1%        -4.9%

## Topic Drift
  NEW:     "oauth", "consent" (appeared 7 times, absent from baseline)
  DROPPED: "scheduler", "health" (12 baseline occurrences, 0 recent)

## Commit Cadence
  Baseline: 3.2 commits/day, 142 LOC/commit avg
  Recent:   1.1 commits/day, 387 LOC/commit avg
  *** Commit size increasing while frequency drops — batch accumulation risk

## Drift Score
  Frequency drift:   MODERATE (34.8% drop)
  Type drift:        HIGH (STATUS +16.9%)
  Topic drift:       MODERATE (2 new, 2 dropped)
  Commit drift:      HIGH (size 2.7x baseline)
  Overall:           MODERATE-HIGH — review agent tasking

## Recommendation
[Specific action based on findings — e.g., "Agent shifting to STATUS-only
messages suggests it may be stuck. Check for BLOCKED messages or stale work."]

No further action needed | Action: [specific next step]
```

## Sparkline Characters

Use block characters for ASCII sparklines: `▁▂▃▄▅▆▇█` (map value to 1-8 range).

## Drift Thresholds

| Metric | Low | Moderate | High |
|--------|-----|----------|------|
| Frequency delta | <15% | 15-40% | >40% |
| Type distribution delta | <10% | 10-20% | >20% |
| New/dropped topics | 0-1 | 2-3 | 4+ |
| Commit size ratio | <1.5x | 1.5-3x | >3x |

## Skill Chains

- After drift detected: `[agent-audit]` (deep investigation)
- If goal drift found: `[alignment-check]` (verify intent alignment)
- If commit drift: `[changelog]` (review what changed)
- If frequency drop: `[bus]` (check for BLOCKED messages)
