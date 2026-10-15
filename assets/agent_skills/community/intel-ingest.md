---
name: intel-ingest
description: Ingest intelligence into the Cognitive Ledger, Open Brain, Bus, and all other intel ingestion surfaces. Routes any INT-typed intel (HUMINT/OSINT/MASINT/GITINT/BUSINT/OPSINT/CODEINT/LOGINT/REGINT/FININT/TECHINT/CYBINT/IMINT/TOPOINT) to every ingestion surface.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<INT-code> \"<content>\" [--source <url|file|agent>] [--confidence 0.0-1.0] [--tags t1,t2] [--type discovery|lesson|decision|correction|convention|inference|HULE|synthesis|MILESTONE|attestation] [--supersedes <entry_id>]"
category: fleet-ops
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Ledger size**: Run `wc -l "$REPO_ROOT/_state/cognition/ledger.jsonl" 2>/dev/null || echo "0 (empty)"`
- **Open Brain**: Run `curl -s http://127.0.0.1:11435/status 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'{d.get(\"total_docs\",0)} docs indexed')" 2>/dev/null || echo "not accessible locally"`
- **Last bus intel receipt**: Run `grep "intel-ingest" "$REPO_ROOT/_state/coordination/messages.tsv" 2>/dev/null | tail -1 || echo "(none)"`
- **Memory dir**: Run `eval "$("$HOME/.agents/scripts/resolve-memory.sh")"; ls ${RUNTIME_MEM:+$RUNTIME_MEM/} 2>/dev/null | head -5 || echo "no memory dir"`

# Intel Ingest

The single entry point for ingesting **any** intelligence discipline into **every** ingestion surface. Broader than `[research-ingest]` (research-only) and `[note]` (single thought): `intel-ingest` accepts all 14 INT channels from the HUMMBL Intelligence Lexicon (DoD-inspired, internally bounded) and fans out to Cognitive Ledger + Open Brain + Coordination Bus + Memory files in one call.

> **Lexicon source of truth**: `hummbl-governance/docs/research/idea-packs/2026-05-16-intelligence-lexicon-agent-taxonomy.md` and `PROJECTS/platform/docs/reference/vernacular/AGENTIC_VERNACULAR.md`. Official-inspired INT labels are **internal evidence-channel metaphors only** — never imply government affiliation, collection authority, or surveillance capability.

## When to Use
- After any `[daily-research]`, `[deep-research]`, `[web-research]`, `[competitive-intel]`, `[redteam]`, `[blueteam]`, or `[industry-watch]` run produces findings
- When a CVE, advisory, or threat signal lands and needs to reach every surface
- When market/competitor intel (pricing, funding, launch) needs durable persistence
- When operational intel (incident learning, fleet event, health anomaly) must be auditable
- When `[note]` is too thin and `[research-ingest]` is too narrow (research-only)
- When the same finding must reach ledger + bus + Open Brain + memory atomically

## INT Channel Routing

Use the INT code as the first argument. The skill maps it to the correct ledger type, default confidence, and target memory file.

Valid ledger `--type` values: `lesson, decision, discovery, correction, convention, inference, HULE, synthesis, MILESTONE, attestation`. The table below picks a sensible default per INT channel; override with `--type` when the intel warrants it (e.g. a CYBINT finding that changes architecture → `decision`).

| INT code | Label | Default type | Default conf | Memory file |
|----------|-------|--------------|--------------|-------------|
| `HUMINT` | Consented human-source input | `inference` | 0.7 | `feedback_*.md` |
| `OSINT` | Public/commercial sources | `discovery` | 0.7 | `research_*.md` |
| `MASINT` | Measurements, benchmarks, evals | `discovery` | 0.85 | `benchmark_*.md` |
| `IMINT` | Screenshots, diagrams, UI captures | `discovery` | 0.6 | `visual_*.md` |
| `GEOINT` | Geospatial/spatial-scene only | `discovery` | 0.7 | `spatial_*.md` |
| `FININT` | Spend, billing, cost telemetry | `discovery` | 0.9 | `finance_*.md` |
| `TECHINT` | Code/config/dep/bin artifacts | `discovery` | 0.8 | `tech_*.md` |
| `CYBINT` | Security posture, exposure, creds | `discovery` | 0.85 | `security_*.md` |
| `GITINT` | Git history, diffs, branches, PRs | `decision` | 0.9 | `git_*.md` |
| `BUSINT` | Coordination bus, receipts, agent state | `discovery` | 0.95 | `bus_*.md` |
| `OPSINT` | Live ops: processes, ports, CI, health | `discovery` | 0.85 | `ops_*.md` |
| `CODEINT` | Static/dynamic codebase intel | `discovery` | 0.8 | `code_*.md` |
| `LOGINT` | Logs, traces, structured event streams | `discovery` | 0.85 | `log_*.md` |
| `REGINT` | Regulatory, policy, legal signals | `discovery` | 0.7 | `compliance_*.md` |
| `TOPOINT` | Repo/filesystem/service topology | `discovery` | 0.8 | `topology_*.md` |

**SIGINT**: legacy/restricted — do NOT route here. Use `LOGINT`, `BUSINT`, `OPSINT`, or `MASINT` instead.

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=intel-ingest] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Parse and classify
Read `$ARGUMENTS`: `<INT-code>` (required), `<content>` (required), plus `--source`, `--confidence`, `--tags`, `--type`, `--supersedes`. If INT code is missing or unknown, BLOCK and ask the caller to pick from the table above. Reject `SIGINT` and direct the caller to the appropriate replacement.

### 2. Duplicate check (mandatory)
```bash
source "$REPO_ROOT/.venv/bin/activate"
python -m hummbl_governance.cognition search "<core claim keywords>" --limit 5
```
- Same claim, same source → **SKIP** (already ingested; report entry_id)
- Same claim, better source → **SUPERSEDE** (`--supersedes <old_id>`)
- Updated claim → **CORRECT** (`--type correction --supersedes <old_id>`)
- New claim → **ADD**

### 3. Write to Cognitive Ledger
```bash
python -m hummbl_governance.cognition post-verified \
  --agent "<caller canonical identity>" \
  --vendor "<vendor>" \
  --model "<model>" \
  --type "<type from table or override>" \
  --scope project \
  --content "[<INT-code>] <content>. Source: <source>." \
  --evidence "<source> — <what the source says>" \
  --confidence "<confidence>" \
  --tags "<INT-code-lower>,intel,<extra tags>" \
  --assurance-level SELF
```
Tags MUST include the lowercase INT code (e.g. `cybint`, `osint`) so `[ledger] search` and `[bus-analytics]` can route by discipline.

### 4. Trigger Open Brain reindex (if accessible)
```bash
curl -s -X POST http://127.0.0.1:11435/reindex 2>/dev/null && echo "Reindexed" \
  || echo "Open Brain not local — nightly consolidator on remote-node will pick up (remote-node dormant since 2026-07-01 — consolidator no longer runs)"
```

### 5. Post bus receipt
```bash
python3 -m hummbl_governance.bus.bus_writer "<caller identity>" all STATUS \
  "Intel ingested [<INT-code>]: <one-line summary>. Source: <source>. Confidence: <conf>. Ledger entry: <id>. Targets: ledger+bus+openbrain+memory."
```

### 6. Update memory file
Append a dated bullet to the matching memory file under `$RUNTIME_MEM` (resolve via `~/.agents/scripts/resolve-memory.sh`; create if missing). Format:
```markdown
- **YYYY-MM-DD [<INT-code>]** <content> (source: <source>, conf: <conf>, ledger: <id>)
```
Keep entries to one line. If the file grows past ~50 lines, suggest `[memory-dedup]`.

## Output Format
```
Intel Ingest | <INT-code> | <source summary>
════════════════════════════════════════════

## Ingested
- Ledger ID: <id>  | type: <type>  | confidence: <conf>
- Tags: <INT-code-lower>, intel, <tags>
- Bus receipt: posted
- Open Brain: <reindexed | deferred to nightly>
- Memory file: <path> (<appended | created>)

## Skipped / Superseded
- <entry_id>: <reason>

## Lexicon boundary
Internal evidence-channel metaphor only. No government affiliation implied.
```

## Skill Chains

### Mandatory (MUST pass before ingestion)
- **Duplicate check** (step 2) MUST pass — no duplicate entries to append-only ledger
- **`[preprint-scan]`** SHOULD run for any OSINT source claiming peer-reviewed status
- **Standards claims** (OWASP ASI-N, NIST SP-N, ISO Art.N, EU AI Act Art.N) require a live-fetch receipt before ingestion — fetch canonical source URL and confirm exact text. Transcribing from prior ledger entries is not acceptable.

### Advisory
- After `[daily-research]` or `[research-pipeline]` → `[intel-ingest]` to persist findings
- After `[redteam]` / `[blueteam]` / `[wargame]` → `[intel-ingest] CYBINT ...`
- After `[competitive-intel]` or `[industry-watch]` → `[intel-ingest] OSINT ...`
- After `[incident]` or `[postmortem]` → `[intel-ingest] OPSINT ...`
- After `[cost-status]` or `[runway]` → `[intel-ingest] FININT ...`
- After `[ai-regulation]` or `[healthcare-ai-watch]` → `[intel-ingest] REGINT ...`
- After `[git-archaeology]` or `[git-blame-analysis]` → `[intel-ingest] GITINT ...`
- After batch ingest (10+ entries) → `python -m hummbl_governance.cognition reindex`
- After ingest that changes positioning → `[pitch]` or `[content-review]`

## Constraints
- NEVER fabricate ledger entries — every entry must have a real source
- NEVER delete or modify existing ledger entries — append-only
- ALWAYS check duplicates before writing
- ALWAYS include source in the content field
- Confidence MUST reflect source tier (S1=0.9+, S2=0.8+, S3=0.7+, S4=0.5-0.7, S5=0.3-0.5, S6=<0.3)
- Tags MUST include the lowercase INT code for searchability
- Reject `SIGINT` — direct caller to `LOGINT`/`BUSINT`/`OPSINT`/`MASINT`
- Do NOT use `GEOINT` for repo/filesystem topology — use `TOPOINT`
- Public-facing use of official-inspired INT labels requires the disclaimer "inspired by IC/DoD terminology" per `.claude/rules/claim-honesty-protocol.md`
- COMPACTION INTERRUPT RECOVERY: if compaction occurs before ingest completes, the bus closeout STATUS MUST enumerate un-ingested INT codes/topics so the next session can recover. Format: "Ingest interrupted — N items queued: [<INT-code>: <topic>, ...]. Resume with [intel-ingest]."

## Base120 Context
- Primary: **DE3** (Categorization) — INT-channel taxonomy
- Related: **IN1** (Evidence Hierarchy) — confidence tracks source tier
- Related: **SY8** (Feedback Loops) — corrections link to originals via `--supersedes`

## Authority
- **T1 (TRUSTED)**: May ingest without restriction
- **T2 (Active/High)**: May ingest without restriction (ledger append is low-risk)
- **T3 (Medium)**: May ingest with source verification; `correction`/`decision` types require operator notification
- **T4 (Probationary)**: May ingest `discovery`/`finding`/`reference` types only; `correction`/`decision` BLOCKED
- **Operator**: Override any restriction
