---
name: research-pipeline
description: Explicit 5-stage research orchestrator (Internal Sweep→External Sweep→Gate→Ingest→Dispatch) with depth flags, focus routing, and BKI parallel track. Use when you need a documented, reproducible research run — not ad-hoc search.
version: 1.4.0
execution-mode: side_effecting
meta-skill: orchestrate
meta-skill-mode: invocation-time
meta-skill-topology: ladder
argument-hint: "--mode preview|persistent [--depth quick|full|overnight] [--focus <domain|bki|arcana|all>] [--audience <ciso|caio|board|investor|none>] [--no-internal-sweep]"
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---
# Research Pipeline

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action (host prefix is required for agent-originated posts).
```
Type: SKILL_INVOKE
To: all
Message: host=<machine> [skill=research-pipeline] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`. The message body MUST begin with `host=$(hostname)` or canonical mesh host name per `bus-protocol.md §Machine tagging`.)

Example bash invocation:
```bash
python ~/bin/bus-global.py post <from_id> all SKILL_INVOKE \
  "host=$(hostname) [skill=research-pipeline] [mode=side_effecting] [args_hash=<args_sha256>] [session=<session_id>]"
```

### 0.1 Authorization Preflight (MANDATORY before Stage 0)

Every run MUST explicitly select `--mode preview|persistent`. If the flag is
absent, stop and ask the operator before searching. The runtime MUST NOT infer
authorization from invocation, autonomy language, or topic alone.

```bash
# Read-only pipeline preview.
python ~/.agents/scripts/research-run-guard.py preflight \
  --mode preview --session-id <session_id>

# Full durable pipeline. Include only grants explicitly supplied by the operator.
python ~/.agents/scripts/research-run-guard.py preflight \
  --mode persistent --session-id <session_id> \
  --authorization-ref <operator-message-or-decision-receipt> \
  --authorize-mutation branch --authorize-mutation worktree \
  --authorize-mutation ledger --authorize-mutation artifact \
  --authorize-mutation commit --authorize-mutation bus
```

Persistent mode fails closed unless all six mutation grants are present. Post
`BLOCKED` and stop before Stage 0 when the guard exits nonzero; do not silently
fall back to preview. An explicitly authorized staging destination can be
recorded with `--receipt-dir <path> --staging-authorized`.

- **Preview** may perform Stages 0–2 as read-only discovery and gating. It must
  not run Stage 3, report candidates as findings, write research artifacts,
  create/switch worktrees or branches, commit, or push. Stage 4 is limited to a
  coordination receipt containing query coverage and candidate counts—never
  finding content.
- **Persistent** may run all stages only after a passing preflight.

If discovery has started and the run later blocks, stage query provenance only
inside the already-authorized directory:

```bash
python ~/.agents/scripts/research-run-guard.py stage-query \
  --session-id <session_id> --receipt-dir <authorized_path> \
  --staging-authorized --source <source_name> --query <query_text> \
  --retrieved-at <YYYY-MM-DDTHH:MM:SSZ> --result-count <N> \
  --candidate-url <URL> --stop-reason <reason>
```

The content-addressed receipt is fixed at `unreviewed-candidates` and
`not-reported`; it never satisfies the ingest or finding-reporting gate.

Explicit 5-stage pipeline. Each stage is named, skippable with justification, and receipted.

**Stage 0 is mandatory** unless `--no-internal-sweep` is passed. It prevents redundant external research by checking what the fleet already knows first.

## Arguments

| Flag | Values | Default | Effect |
|------|--------|---------|--------|
| `--mode` | `preview` / `persistent` | none (required) | Selects zero-persistence discovery or the explicitly authorized durable pipeline |
| `--depth` | `quick` / `full` / `overnight` | `full` | Controls sweep breadth |
| `--focus` | domain string, `bki`, `arcana`, `all` | `all` | Routes to correct track |
| `--audience` | `ciso` / `caio` / `board` / `investor` / `none` | `none` | Activates dispatch stage pitch targeting |
| `--domain` | `ai-governance` / `multi-agent` / `ai-safety` / `platform` / `cloud-compliance` / `agentic-market` / `all` | `all` | Scopes sweep to specific domain within --focus |
| `--no-internal-sweep` | (flag) | not set | Skips Stage 0 — use only when you know the topic has no prior fleet research |

## Pre-Stage 0 — Design Check (epistemological weakness screening)

Before any sweep, identify known epistemological weaknesses in the research domain:

- **Case-study bias**: Will the evidence base rely on creator/practitioner case studies? If so, findings will be survivorship-biased — plan for platform-mechanic or independent-measurement evidence to anchor confidence.
- **Single-source claims**: Are there claims that rely on a single source? Flag for corroboration at Stage 2.
- **Stale statistics**: Does the domain involve fast-changing metrics (platform growth, market share, algorithm behavior)? Flag for freshness verification at Stage 2.
- **Platform-reported figures**: Are key statistics self-reported by platforms with a commercial interest? Flag for source-type classification at Stage 2.

Record the design check in the Pipeline Receipt. (Origin: 2026-09-08 AAR — survivorship bias and stale statistics caught in ARCANA review, not at design time.)

## Stage 0 — Internal Sweep (MANDATORY unless --no-internal-sweep)

**Purpose**: Before spending external API credits or web searches, check what the fleet already knows. The Cognitive Ledger (1660+ entries), bibliography (592 entries across 24 tiers), research docs (260+ files), bus history (23K+ messages), Base120 models (120 operators), memory pins (22 files), and rules (209 files) may already contain the answer or substantial context.

**Skip conditions**: `--no-internal-sweep` flag passed, OR topic is explicitly novel with no prior fleet exposure.

### 0.1 Cognitive Ledger search

```bash
# Search the canonical ledger for prior findings on the topic
LEDGER="${COGNITION_LEDGER:-$HOME/.agents/state/cognition/ledger.jsonl}"
python3 -c "
import json, sys
topic = sys.argv[1].lower()
with open('$LEDGER') as f:
    for line in f:
        try:
            e = json.loads(line)
            content = e.get('content', '').lower()
            tags = ' '.join(e.get('tags', [])).lower()
            if topic in content or topic in tags:
                print(f'[{e.get(\"id\",\"?\")[:16]}] {e.get(\"type\",\"?\")} conf={e.get(\"confidence\",\"?\")} agent={e.get(\"agent\",\"?\")} ts={e.get(\"timestamp\",\"?\")[:10]}')
                print(f'  {e.get(\"content\",\"\")[:200]}')
                print()
        except: pass
" "$TOPIC"
```

Record: number of hits, top 3 most relevant entries by confidence.

### 0.2 Bibliography scan

```bash
# Search bibliography abstracts and keywords for the topic
BIB_DIR="$HOME/PROJECTS/hummbl-bibliography/bibliography"
if [ -d "$BIB_DIR" ]; then
    grep -ril "$TOPIC" "$BIB_DIR"/*.bib 2>/dev/null | head -10
    # For each hit, extract the entry title and abstract
    for f in $(grep -ril "$TOPIC" "$BIB_DIR"/*.bib 2>/dev/null | head -5); do
        echo "=== $(basename $f) ==="
        grep -A5 "$TOPIC" "$f" | head -10
    done
fi
```

Record: number of matching entries, which tiers they're in, transformation tags.

### 0.3 Research docs scan

```bash
# Search governance research docs + hummbl-research docs + essays + case studies
for dir in \
    "$HOME/PROJECTS/hummbl-research/docs" \
    "$HOME/PROJECTS/hummbl-research/essays" \
    "$HOME/PROJECTS/hummbl-research/case-studies"; do
    if [ -d "$dir" ]; then
        grep -ril "$TOPIC" "$dir" 2>/dev/null | head -10
    fi
done
```

Record: number of matching docs, top 3 most relevant by filename/topic match.

### 0.4 Bus history search

```bash
# Search coordination bus for prior agent conclusions on the topic
python3 "$HOME/bin/bus-global.py" search "$TOPIC" 2>/dev/null | head -30
```

Record: number of hits, key conclusions posted by agents (STATUS/DECISION/SITREP messages).

### 0.5 Base120 model lookup

Identify which of the 120 mental models apply to frame the problem space:

```bash
# Search Base120 model definitions for the topic
MODELS_DIR="$HOME/PROJECTS/hummbl-research/models"
if [ -d "$MODELS_DIR" ]; then
    grep -ril "$TOPIC" "$MODELS_DIR" 2>/dev/null | head -10
    # Also list model codes by family for framing
    ls "$MODELS_DIR"/*/ 2>/dev/null | head -30
fi
```

Record: which transformation families (P/IN/CO/DE/RE/SY) and specific models apply.

### 0.6 Memory + rules scan

```bash
# Search memory pins and rules for operational constraints on the topic
grep -ril "$TOPIC" "$HOME/.devin/memories/" "$HOME/.agents/rules/" 2>/dev/null | head -10
```

Record: relevant memory pins, rules that constrain action on this topic.

### Stage 0 Output

Synthesize findings into an **Internal Sweep Report**:

```
## Internal Sweep Report — <topic>
Date: <ISO datetime>

### Already Known
- [Ledger] <N> entries found. Top: <entry_id> — <summary> (conf=<X>)
- [Bibliography] <N> entries in tiers <list>. Key: <title> (<tier>)
- [Research docs] <N> docs found. Key: <filename> — <summary>
- [Bus] <N> messages. Key conclusion: <agent> posted <summary> on <date>
- [Base120] Models <codes> apply. Framing: <which transformation>
- [Memory/Rules] <N> pins/rules. Constraint: <summary>

### Gaps Identified
- <what's missing that external research must fill>
- <what's outdated and needs verification>

### External Research Scope
- Stage 1 should focus on: <specific sub-topics not covered internally>
- Skip: <sub-topics already well-covered>
- Verify: <claims that need fresh sources>
```

**If the Internal Sweep Report shows substantial prior coverage**: narrow Stage 1 scope to only the identified gaps. Do NOT re-research what the fleet already knows.

**If the Internal Sweep Report shows no prior coverage**: proceed to Stage 1 with full scope.

## Stage 1 — External Sweep

Select tools based on `--depth`:

| Depth | Tools invoked |
|-------|--------------|
| `quick` | `[web-research]` (targeted Q&A, 1-3 queries) |
| `full` | `[daily-research]` + `[web-research]` (gap-fill) |
| `overnight` | `[daily-research]` + `[industry-watch]` + `[anthropic-watch]` + `[deep-research]` (isolated agent) |

If `--focus bki`: also run `[bki-evidence-flywheel]` in parallel with main sweep.
If `--focus arcana`: include ARCANA synthesis artifacts in sweep scope.

**Sweep output**: raw findings list with source URL, source tier (S1-S6), initial confidence (0.0-1.0).

## Stage 2 — Quality Gate

For every finding where source tier is S2p, S3, S4, S5, or S6:
- Run `[preprint-scan]` to verify peer-review status, retraction status, confidence floor
- Downgrade confidence per tier if preprint or unverified:
  - S2p: cap at 0.75; flag as `[PREPRINT]`
  - S5/S6: cap at 0.40; flag as `[UNVERIFIED]`
- Drop findings below 0.70 confidence — do NOT ingest
- For `--focus bki`: also run `[bki-cite-audit]` on any BKI-sourced citations

**Primary-source verification** (mandatory for secondary-sourced statistics):
- Any statistical claim cited via a secondary source MUST be verified against the cited primary source.
- If the primary source is not accessible, doesn't contain the figure, or the attribution is inaccurate → label as HYPOTHESIS, not FINDING.
- Do not promote secondary-sourced statistics to FINDINGS without primary-source confirmation.
- (Origin: 2026-09-08 AAR — "67% reach decline" attributed to ConvertKit 2024 was not findable in the primary source.)

**Freshness check** (mandatory for statistical claims):
- For any statistical claim, verify the data's *collection date*, not just the citation's publication date.
- A 2024 data point cited in a 2026 article is stale unless explicitly confirmed as still current.
- Flag the collection date in the finding's source metadata.
- (Origin: 2026-09-08 AAR — "58%" zero-click figure was 2024 data cited without date in a 2026 secondary source; current 2026 figure is 68.01%.)

**Survivorship bias screening** (mandatory for case-study-based findings):
- Findings based on creator/practitioner case studies are capped at confidence 0.85 and labeled PRACTITIONER_EVIDENCE, not DISCOVERY.
- Case studies are survivorship-biased: creators who tried the same strategy and failed don't write case studies.
- Distinguish *platform mechanics* (structural, durable, non-copyable) from *creator systems* (anecdotal, depreciating, copyable).
- Weight platform-mechanic findings higher than creator-system findings in synthesis.
- (Origin: 2026-09-08 AAR — ARCANA review found case-study evidence base was epistemically invalid under fat-tailed distributions.)

**Mechanical R1-R4 check** (mandatory before Stage 3 for any written artifact):
- Run `python scripts/intel_surge_quality_check.py <artifact.md>`; it checks 4-field provenance (R1), date-stamped counts (R2), class marks incl. `[SEC-SRC]` (R3), FT1-FT4 tiers on actionable windows (R4), and the declared grade.
- Exit 1 caps the artifact at Grade C. Warnings go to the reviewer; the check does not replace non-author review.

**Gate output**: verified findings list with adjusted confidence, drop log, primary-source verification log, freshness check log, survivorship bias classifications, R1-R4 check result.

## Stage 3 — Ingest

**Persistent mode only.** Preview mode skips this stage by contract and must
not represent candidates as findings.

For every finding ≥ 0.70 confidence from Stage 2:
- Run `[research-ingest]` (4-target write: CLP ledger + evidence docs + Open Brain + bus receipt)
- Use correct `--type`: `discovery` (new finding) | `correction` (downgrade) | `lesson` (process learning)
- Tag with `--focus` value and `--depth` value for retrieval
- Run `[research-digest]` at end of stage to verify coverage and surface any missed entries

**Ingest output**: count ingested, count dropped, ledger entry IDs.

## Stage 4 — Dispatch

In persistent mode:
- Run `[research-digest] recent` to confirm coverage
- Post bus SITREP with pipeline receipt

In preview mode, post only a coordination receipt with searched sources,
queries, and candidate counts. Do not include finding content or downstream
recommendations.

Conditional in persistent mode only:
- If governance/AI safety/BKI findings found → `[arcana-to-pitch] --audience $AUDIENCE` (if audience set)
- If competitor signals found → `[competitive-intel]` (flag for follow-up)
- If client deliverable needed → `[evidence-pack]` (bundle verified findings)
- If `--focus bki` and new HIGH-grade citations → append to `bki_citation_audit.md`

**Dispatch output**: bus SITREP posted, downstream skill invocations noted.

## Persistent Pipeline Receipt (required output format)

```
## Pipeline Receipt — research-pipeline
Date: <ISO datetime>
Mode: <preview|persistent>
Depth: <quick|full|overnight>
Focus: <domain>
Audience: <value|none>

### Stages
- [x] Preflight: <pass|blocked>, authorization receipt: <path-or-stdout-receipt>
- [x] Stage 0 Internal Sweep: <N> ledger hits, <N> bib hits, <N> doc hits, <N> bus hits. Gaps: <list>
- [x] Stage 1 External Sweep: <N> raw findings from <tools used>
- [x] Stage 2 Gate: <N> verified, <N> dropped (reasons: <list>)
- [x] Stage 3 Ingest: <N> ledger entries written, <N> evidence docs updated
- [x] Stage 4 Dispatch: SITREP posted, <downstream skills invoked>

### Top 3 Findings
1. **<Finding>** | Source: <URL> | Tier: <S1-S6> | Confidence: <0.0-1.0>
   HUMMBL implication: <one sentence>

2. **<Finding>** | Source: <URL> | Tier: <S1-S6> | Confidence: <0.0-1.0>
   HUMMBL implication: <one sentence>

3. **<Finding>** | Source: <URL> | Tier: <S1-S6> | Confidence: <0.0-1.0>
   HUMMBL implication: <one sentence>

### Drop Log
- <finding excerpt> — dropped, reason: <confidence below floor | retracted | fabricated stat>
```

## Preview Receipt (required output format in preview mode)

```text
## Preview Receipt — research-pipeline
Date: <ISO datetime>
Mode: preview
Depth: <quick|full|overnight>
Focus: <domain>
Preflight: pass, receipt: <path-or-stdout-receipt>

### Query Coverage
- Internal sources searched: <names and query terms>
- External sources searched: <names and query terms>
- Candidate count: <N>

### Unreviewed Candidates — NOT REPORTED AS FINDINGS
- <candidate URL>

### Prohibited Stages
- Stage 3 Ingest: not run
- Finding synthesis and downstream recommendations: not run
```

## Rules

- Never start Stage 0 until `research-run-guard.py preflight` passes for the explicitly selected mode.
- Never skip Stage 0 (Internal Sweep) unless `--no-internal-sweep` is explicitly passed. Re-researching what the fleet already knows wastes credits and time.
- Never skip Stage 2 (Gate). If preprint-scan is unavailable, flag manually and halve confidence.
- Never ingest below 0.70 confidence as `discovery`. Use `correction` type for downgrades.
- `--audience none` skips pitch targeting but SITREP is still mandatory.
- Source every claim: URL, arXiv ID, or `[ESTIMATE: basis]` tag inline.
- No Ollama on MBP (`overnight` depth uses deep-research isolated agent, not local LLM).
- EU AI Act and NIST AI RMF angles are always worth surfacing on governance-adjacent findings.
- Stage 0 findings from the ledger are prior knowledge — cite them by entry ID, not by re-stating.

## Differences from `[research]`

| Dimension | `[research]` (mode) | `[research-pipeline]` (orchestrator) |
|-----------|-------------------|--------------------------------------|
| Internal sweep | Not present | Mandatory Stage 0 (ledger + bib + docs + bus + Base120 + memory) |
| Depth control | Fixed OVERNIGHT | `quick` / `full` / `overnight` flags |
| Quality gate | Optional (mentioned) | Mandatory Stage 2 with drop log |
| BKI track | Not explicit | `--focus bki` routes to full BKI track |
| Audience targeting | Not present | `--audience` flag activates pitch dispatch |
| Output format | Informal synthesis | Structured pipeline receipt |
| When to use | Open-ended research sessions | Reproducible, documented research runs |

Begin pipeline execution now.

## Skill Chains

### Mandatory

- `research-run-guard.py preflight` before Stage 0; the selected mode controls which stages may mutate state.

### Advisory

- → `[aar]` (after session closes, review pipeline effectiveness)
- → `[evidence-pack]` (if findings need external bundling for client/pitch)
- → `[competitive-intel]` (if market signals found during sweep)
- → `[arcana-to-pitch]` (if governance findings need pitch conversion)

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run preview; persistent mode requires operator approval
- **T4 (Probationary)**: May run preview; persistent mode is BLOCKED
- **Operator**: Override any restriction
