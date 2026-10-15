---
name: research-ingest
description: Ingest research findings into the knowledge system — Cognitive Ledger, evidence docs, Open Brain reindex, bus receipt.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<source-file | URL | inline finding> [--type discovery|lesson|decision|correction] [--tags tag1,tag2]"
category: fleet-ops
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Ledger size**: Run `wc -l _state/cognition/ledger.jsonl 2>/dev/null || echo "0 (empty)"`
- **Evidence docs**: Run `ls docs/research/evidence/*.md 2>/dev/null | wc -l || echo "0"`
- **Open Brain**: Run `curl -s http://127.0.0.1:11435/status 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'{d.get(\"total_docs\",0)} docs indexed')" 2>/dev/null || echo "not accessible locally"`

# Research Ingest

Turn raw research findings into structured, searchable, citable knowledge. This is the write side of the research pipeline — `[daily-research]` finds it, `[research-ingest]` persists it.

## When to Use
- After `[daily-research]` produces findings worth keeping
- After `[deep-research]` or `[web-research]` returns valuable results
- When you find a source that backs a claim in our docs or pitch materials
- When a finding invalidates or updates something we previously believed
- When ingesting external research (papers, reports, competitor analysis)
- After auditing Gemini or other agent output that contains valid research

## Ingestion Targets

Findings flow into up to 4 targets depending on value:

| Target | When | Persistence | Searchable |
|--------|------|-------------|------------|
| **Cognitive Ledger** | Always — every finding | `_state/cognition/ledger.jsonl` | via `search` CLI |
| **Evidence Doc** | Substantial findings with multiple sources | `docs/research/evidence/` | via grep/glob |
| **Open Brain** | After ledger write, if server accessible | BM25 index on $REMOTE_HOST | via `[search]` API |
| **Bus Receipt** | Always — audit trail | `$PROJECT_ROOT/_state/coordination/messages.tsv` | via bus grep |

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=research-ingest] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 0a. Verify ledger path (CRITICAL)
Before the first `post` call, verify the ledger path is correct:
```bash
# Check if COGNITION_LEDGER env var is set
echo "${COGNITION_LEDGER:-NOT_SET}"
# If NOT_SET, export it before running any cognition commands:
# export COGNITION_LEDGER=~/.agents/state/cognition/ledger.jsonl
# If set, verify the file exists:
ls -la "$COGNITION_LEDGER" 2>/dev/null || echo "Ledger file does not exist — will be created on first write"
# Verify the module resolves to the correct path:
python -m hummbl_governance.cognition state
```
**Always set `COGNITION_LEDGER` before running `post` commands.**
The module's default path resolves to `<package-root>/_state/cognition/ledger.jsonl`,
which is a package-local file — NOT the fleet ledger. Setting `COGNITION_LEDGER`
overrides this default (fixed in commit d6c05e7, 2026-09-07).

**Note**: The module is `hummbl_governance.cognition` (not `hummbl_cognition`),
and the subcommand is `post` (not `post-verified`). There is no `--ledger` CLI
flag — use the `COGNITION_LEDGER` env var instead.

(Origin: 2026-09-02 AAR — 8 entries written to
`packages/python/hummbl-cognition/src/_state/` instead of the fleet ledger.
2026-09-07 AAR — 5 entries written to
`packages/python/hummbl-governance/_state/cognition/ledger.jsonl` instead of
fleet ledger; root cause was module ignoring `COGNITION_LEDGER` env var.)

### 0b. Provenance window + bus mirror sync (CRITICAL)

`cognition post` is rejected unless a `SKILL_INVOKE` row from your agent
exists in the coordination bus within `SKILL_INVOKE_WINDOW_SECONDS`
(default **300s**). Two traps:

1. **The window expires mid-sweep.** A SKILL_INVOKE emitted at session start
   is stale by the time a >5-minute sweep + structuring finishes. Emit a
   fresh SKILL_INVOKE immediately before the `post` batch — do not reuse a
   session-start invoke.
2. **The check reads the LOCAL mirror, not the hub.** Provenance resolves
   `~/.cache/bus/messages.tsv` (or the repo-local `_state/` path), which only
   syncs when `bus-global.py status` runs. A `post` via the HTTP bridge does
   NOT update it — and neither does `tail`/`search` (they read the live hub
   without persisting). Your fresh SKILL_INVOKE will be invisible to the
   check until `status` writes the mirror.

Recipe before any `cognition post` batch:

```bash
python ~/bin/bus-global.py post <agent> all SKILL_INVOKE \
  "host=<canonical-host> [skill=research-ingest] [mode=side_effecting] [args_hash=<sha>] [session=<id>]"
python ~/bin/bus-global.py status   # persists mirror; SKILL_INVOKE must appear in it
```

If `post` still fails with `no recent SKILL_INVOKE`, re-run `status` and
retry — do not reach for `--no-skill-invoke-check` unless the run is
explicitly legacy/offline.

(Origin: 2026-09-20 AAR — `cognition post` rejected twice: a 10:43Z bridge
SKILL_INVOKE was absent from the local mirror (last synced entry 10:11Z)
until `bus-global.py tail` pulled it; and the session-start invoke had aged
out of the 300s window.)

### 1. Parse the input

Determine the source type from `$ARGUMENTS`:

| Input | Action |
|-------|--------|
| File path (`docs/research/evidence/*.md`) | Read and extract findings |
| URL | Fetch, evaluate, extract claims |
| Inline text | Parse directly |
| No arguments | Interactive — ask what to ingest |

### 2. Structure each finding

Every finding MUST have these fields before ingestion:

```
- claim: What we learned (1-2 sentences)
- source_url: Where it came from
- source_tier: S1-S6 per daily-research evaluation ladder
- confidence: 0.0-1.0 (S1=0.9+, S2=0.8+, S3=0.7+, S4=0.5-0.7, S5=0.3-0.5, S6=<0.3)
- domain: AI Governance | Multi-Agent | AI Safety | Platform Eng | Compliance | Market
- tags: comma-separated topic tags
- relevance: How this affects your organization (1 sentence)
- temporal: When was this true? Is it time-sensitive?
- standards_claims: Any reference to a numbered item in a public standard (OWASP ASI-N, NIST SP-N, ISO Art.N, EU AI Act Art.N) MUST include a live-fetch receipt — URL + the exact text confirming the number/name mapping. Do NOT transcribe from prior research entries; fetch the canonical source directly.
```

### 3. Check for duplicates

Before writing, search the ledger for existing entries on the same topic:
```bash
source .venv/bin/activate
export COGNITION_LEDGER=~/.agents/state/cognition/ledger.jsonl
python -m hummbl_governance.cognition search "<core claim keywords>" --limit 5
```

If `search` fails with `no index found; run 'reindex' first`, the cognition
index has not been built in this environment — run
`python -m hummbl_governance.cognition reindex` once, then retry. The index
is not auto-bootstrapped. (Origin: 2026-09-20 AAR — first-ever `search` in a
fresh env errored until `reindex` ran.)

If a match exists:
- Same claim, same source → **SKIP** (already ingested)
- Same claim, better source → **SUPERSEDE** (use `--supersedes <old_id>`)
- Updated claim → **CORRECT** (use `--type correction --supersedes <old_id>`)
- New claim on same topic → **ADD** (new entry, link via tags)

### 4. Write to Cognitive Ledger

For each unique finding:

```bash
source .venv/bin/activate
export COGNITION_LEDGER=~/.agents/state/cognition/ledger.jsonl
python -m hummbl_governance.cognition post \
  --agent "daily-research" \
  --vendor anthropic \
  --model "opus-4.6" \
  --type discovery \
  --scope project \
  --content "<claim>. Source: <url> (S<tier>). Relevance: <relevance>" \
  --evidence "<source_url> — <what the source says>" \
  --confidence <0.0-1.0> \
  --tags <domain>,<subtopic>,evidence \
  --assurance-level SELF
```

**Type selection guide:**
| Type | When |
|------|------|
| `discovery` | New finding — something we didn't know |
| `lesson` | Pattern or insight derived from findings |
| `decision` | Research led to an architectural or strategic choice |
| `correction` | Finding that invalidates a previous belief |
| `convention` | Established pattern confirmed by research |

### 5. Write Evidence Doc (if substantial)

If the finding has 2+ sources or changes our positioning, write to `docs/research/evidence/`:

```bash
# File: docs/research/evidence/YYYY-MM-DD_<topic>.md
```

Format:
```markdown
# Evidence: <Topic>
**Date**: YYYY-MM-DD
**Domain**: <domain>
**Confidence**: <0-100>%

## Finding
<what we learned>

## Sources
1. <url> — <what it says> (reliability: S<tier>)
2. <url> — <cross-reference> (reliability: S<tier>)

## Relevance to your organization
<how this affects positioning, product, or claims>

## Action
<what to do — update a doc, inform a decision, nothing yet>
```

### 6. Trigger Open Brain reindex (if accessible)

```bash
curl -s -X POST http://127.0.0.1:11435/reindex 2>/dev/null && echo "Reindexed" || echo "Open Brain not accessible (will sync on $REMOTE_HOST nightly)"
```

If Open Brain is not accessible locally, the nightly consolidator on $REMOTE_HOST will pick up new ledger entries automatically.

### 7. Post bus receipt

```bash
python3 -m hummbl_governance.bus.bus_writer "daily-research" all STATUS \
  "Research ingested: <N> findings to ledger, <N> evidence docs. Topics: <tags>. Confidence range: <min>-<max>."
```

## Batch Ingestion

For ingesting an entire evidence doc with multiple findings:

```
[research-ingest] docs/research/evidence/2026-03-25_ai_governance_landscape.md
```

The skill will:
1. Read the file
2. Extract each numbered finding
3. Check for duplicates per finding
4. Write each to the ledger individually (one entry per finding)
5. Post a single bus receipt summarizing the batch

## Superseding & Corrections

When new research invalidates old findings:

```
[research-ingest] --type correction "EU AI Act deadline moved to Sept 2026" --supersedes <entry_id>
```

This creates a correction entry linked to the original, preserving the audit trail. The original is never deleted (append-only ledger).

## Verification Levels

| Level | Meaning | When to Use |
|-------|---------|-------------|
| `SELF` | Single agent verified | Default — you found and evaluated it |
| `PEER` | Cross-agent verified | Gemini found it, Claude verified it |
| `VERIFIED` | Human-confirmed | User explicitly confirmed the finding |

## Output Format

```
Research Ingest | <source summary>
════════════════════════════════════

## Ingested
1. [<entry_id>] <claim summary> (confidence: <X>, tags: <tags>)
2. [<entry_id>] <claim summary> ...

## Skipped (duplicates)
- <claim> — already in ledger as <entry_id>

## Superseded
- <old_entry_id> → <new_entry_id>: <what changed>

## Targets Written
- Ledger: <N> entries
- Evidence docs: <N> files
- Open Brain: <reindexed | deferred to nightly>
- Bus: receipt posted

## Ledger Health
- Total entries: <N>
- Types: discovery=<N>, lesson=<N>, decision=<N>, correction=<N>
```

## Chain

| After... | Consider... |
|----------|-------------|
| Batch ingest from `[daily-research]` | `[research-digest]` to verify coverage |
| Correction ingested | Update the doc that cited the old claim |
| Large ingest (10+ entries) | `python -m hummbl_governance.cognition reindex` |
| Finding changes positioning | `[pitch]` or `[content-review]` to update materials |

## Constraints
- NEVER fabricate ledger entries — every entry must have a real source
- NEVER delete or modify existing entries — append-only ledger
- ALWAYS check for duplicates before writing
- ALWAYS include source URL in the content field
- Confidence MUST reflect source tier (don't claim 0.95 from an S5 blog post)
- Tags MUST include the domain name for searchability
- COMPACTION INTERRUPT RECOVERY: if context compaction occurs before ingest completes, the bus closeout STATUS MUST enumerate un-ingested finding IDs or topic names so the next session can recover without data loss. Format: "Ingest interrupted — N findings queued but not written: [topic1, topic2, ...]. Resume with [research-ingest]."

### Standards claims
Any finding that references a numbered item in a public standard (OWASP ASI-N, NIST SP-N, ISO Art.N, EU AI Act Art.N, etc.) requires a live-fetch receipt before ingestion: retrieve the canonical source URL and confirm the exact text matching the number and name. Transcribing from prior ledger entries or memory is not acceptable — fetch directly.

## Base120 Context
- Primary: **DE3** (Categorization) — structured knowledge taxonomy
- Related: **IN1** (Evidence Hierarchy) — confidence tracks source tier
- Related: **SY8** (Feedback Loops) — corrections link to originals

## Skill Chains

### Mandatory (MUST pass before ingestion)

- **`[preprint-scan]`** SHOULD run for any source claiming peer-reviewed status
- **Duplicate check** (step 3) MUST pass — no duplicate entries to append-only ledger

### Advisory

| After... | Consider... |
|----------|-------------|
| Batch ingest from `[daily-research]` | `[research-digest]` to verify coverage |
| Correction ingested | Update the doc that cited the old claim |
| Large ingest (10+ entries) | `python -m hummbl_governance.cognition reindex` |
| Finding changes positioning | `[pitch]` or `[content-review]` to update materials |

## Authority

- **T1 (TRUSTED)**: May ingest without restriction
- **T2 (Active/High)**: May ingest without restriction (ledger append is low-risk)
- **T3 (Medium)**: May ingest with source verification; corrections require operator notification
- **T4 (Probationary)**: May ingest `discovery` type only; `correction`/`decision` types BLOCKED
- **Operator**: Override any restriction
