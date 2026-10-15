---
name: ask-the-stack
description: Query the full knowledge stack (CLP + bibliography + bus + evidence docs) for research-grounded answers
version: 1.0.0
execution-mode: advisory
argument-hint: <question>
category: fleet-ops
status: candidate
---
# [ask-the-stack]

> Ask the full knowledge stack a question. Returns answers grounded in CLP ledger, bibliography, bus history, and evidence docs -- not model inference alone.

## When to Use
- Before writing a pitch or email: "what do we know about enterprise AI governance failures?"
- Before a discovery call: "what does our research say about [company's] sector?"
- When you need sourced claims, not hallucinated ones
- After overnight ARCANA synthesis: "what did ARCANA conclude about [topic]?"

## Execution

### Phase 1 -- CLP Ledger Search
```bash
python3 -m hummbl_governance.cognition search "$QUERY" --limit 10 --json 2>/dev/null | \
  python3 -c "import json,sys; [print(f'[{r[\"source\"]}] {r[\"content\"][:120]}') for line in sys.stdin for r in [json.loads(line)]]" 2>/dev/null || \
  python3 -m hummbl_governance.cognition search "$QUERY" --limit 10
```

### Phase 2 -- Bibliography Search
Search `~/PROJECTS/hummbl-bibliography/` for entries matching query terms:
```bash
grep -ri "$QUERY" ~/PROJECTS/hummbl-bibliography/ --include="*.json" --include="*.md" -l 2>/dev/null | head -5
```
If bibliography entries found, grep for title/tier/doi of matching entries.

### Phase 3 -- Bus Milestone / SITREP Search
```bash
grep -i "$QUERY" ~/.cache/bus/messages.tsv 2>/dev/null | \
  grep -E "MILESTONE|SITREP|DISCOVERY" | tail -5 | \
  awk -F'\t' '{printf "[%s] %s\n", substr($1,1,16), $5}'
```

### Phase 4 -- Evidence Docs Search
```bash
grep -ril "$QUERY" /work/active/hummbl-research/docs/evidence/ 2>/dev/null | head -5
```
For matched files, show first 3 lines of each.

### Phase 5 -- Synthesis
Synthesize findings across all sources.

## Output Format

```
[ask-the-stack] | "<query>"
======================================

## Answer
[2-4 sentence answer grounded in retrieved sources]

## Evidence
| Source | Type | Key Finding |
|--------|------|-------------|
| [ledger entry ID or bus ts] | CLP/Bus/Evidence | [excerpt] |

## Confidence
[HIGH/MEDIUM/LOW] -- based on source quality and coverage

## Gaps
[What the stack doesn't know about this question -- be honest]

## Next Action
[If gaps exist: suggest [daily-research] or [deep-research] on the gap]
```
