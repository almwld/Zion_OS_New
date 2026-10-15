---
name: graph-build
description: Build or refresh Graphify knowledge-graph artifacts for HUMMBL corpora (projects, bki, arcana, research)
version: 0.1.0
execution-mode: side_effecting
category: dev-tools
status: candidate
---
# [graph-build]

Build or refresh a Graphify knowledge-graph artifact for a HUMMBL corpus.

## Usage

```
[graph-build] <corpus>                    # full build (LLM-driven)
[graph-build] <corpus> --update           # incremental AST-only refresh
[graph-build] <corpus> --cluster-only     # rerun Leiden on existing graph
[graph-build] <corpus> --cost-override    # skip cost gate (operator only)
[graph-build] <corpus> --keep N           # retain N builds instead of 5
```

Supported corpora: `projects`, `bki`, `arcana`, `research`

## What it does

1. **Resolve corpus path** from `hummbl_governance/config/graph_corpora.toml` (or
   hard-coded fallbacks below).
2. **Cost gate** (full builds only) — estimate API cost, call cost-governor.
3. **Invoke Graphify** via the appropriate subcommand.
4. **Copy artifact** to `~/.agents/_state/graphs/<corpus>/graph-<TS>.json`
   and update `latest.json` pointer.
5. **Prune** old builds (keep last 5 by default).
6. **Emit CLP event** `graph_build` (or `graph_build_failed` on error).

## Corpus definitions (fallback)

| corpus | path | mode | schedule |
|---|---|---|---|
| projects | `$HOME/PROJECTS/` | full + update | full monthly, update daily |
| bki | `/work/active/hummbl-research/docs/bki/` | full only | on bibliography update |
| arcana | `/work/active/arcana/` | full only | monthly |
| research | `/work/active/hummbl-research/docs/` | full + update | full monthly, update weekly |

Override via `HUMMBL_CORPUS_<NAME>_PATH` env var.

## Steps (when invoked)

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=graph-build] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### Step 1 — Validate corpus

Reject if corpus not in known set.  Suggest available corpora on error.

### Step 2 — Cost gate (full builds only)

```bash
python -c "
import os, sys
# Lightweight corpus hash + file-count sample for estimate
# If estimate > budget and no --cost-override, abort with clear message
"
```

If `--cost-override` present, log override as CLP event and proceed.

### Step 3 — Invoke Graphify

```powershell
# Ensure graphify is installed
python -c "import graphify" 2>$null
if ($LASTEXITCODE -ne 0) { pip install graphifyy -q }

# Select command per mode
# full    → graphify <corpus_path>
# update  → graphify update <corpus_path>
# cluster-only → graphify cluster-only <corpus_path>
```

Graphify writes output adjacent to `<corpus_path>` by default (e.g.
`<corpus_path>/graphify-out/graph.json`).

### Step 4 — Stage artifact

```powershell
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$dest = "$HOME/.agents/_state/graphs/<corpus>/graph-${ts}.json"
$latest = "$HOME/.agents/_state/graphs/<corpus>/latest.json"
New-Item -ItemType Directory -Force -Path (Split-Path $dest)
Copy-Item -Path "<corpus_path>/graphify-out/graph.json" -Destination $dest
# On Windows with no symlink privileges, use copy; else symlink
if (Test-Path $latest) { Remove-Item $latest }
Copy-Item $dest $latest   # or: New-Item -ItemType SymbolicLink $latest -Target $dest
```

### Step 5 — Prune old builds

Keep the most recent N builds (default 5, overridden by `--keep`).
Remove older `graph-*.json` files.

### Step 6 — Emit CLP event

```bash
python -m hummbl_governance.cognition post-verified \
  --agent graph-build \
  --type graph_build \
  --json '{
    "timestamp": "<ISO8601>",
    "corpus": "<corpus>",
    "corpus_path": "<path>",
    "mode": "full|update|cluster-only",
    "graphify_version": "<version>",
    "wrapper_version": "0.1.0",
    "build_duration_seconds": <int>,
    "anthropic_cost_usd": <float>,
    "artifact_path": "<relative path>",
    "artifact_hash": "sha256:<hash>",
    "node_count": <int>,
    "edge_count": <int>,
    "edges_by_confidence": {"EXTRACTED": N, "INFERRED": N, "AMBIGUOUS": N}
  }'
```

On failure, emit `graph_build_failed` with `stderr` captured.

## Failure modes

| symptom | action |
|---|---|
| Graphify not installed | `pip install graphifyy` (auto in Step 3) |
| Cost gate blocks build | Abort; suggest `--cost-override` with operator warning |
| `graph.json` missing after build | Abort; emit `graph_build_failed` |
| Corpus path does not exist | Abort before any cost or invocation |
| Disk full during copy | Abort; emit `graph_build_failed` with errno |
| Prune fails (permission) | Warn; do not fail the whole build |

## Receipt

After success, post to coordination bus:

```
BUS  graph_build  <corpus>  graph-<TS>.json  nodes=N  edges=M  cost=$X.XX
```

## Skill Chains

### Mandatory

None — artifact generation; local file writes only (graph JSON artifacts to `_state/graphs/`). Cost gate is built-in for full builds.

### Advisory

- `[doc-harden]` — harden research corpus after graph build to verify claims

## Authority

- **T1 (TRUSTED)**: May run (full build, update, cluster-only — all modes)
- **T2 (Active/High)**: May run (full build, update, cluster-only — all modes)
- **T3 (Medium)**: May run (full build, update, cluster-only — all modes)
- **T4 (Probationary)**: May run (file generation only — `--cost-override` requires operator approval)
- **Operator**: Override any restriction
