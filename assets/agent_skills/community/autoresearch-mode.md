---
name: autoresearch-mode
description: Governed, receipt-producing autonomous research mode with scheduled cadence and operator-facing artifacts.
version: 0.2.0
execution-mode: side_effecting
argument-hint: "[--pipeline-dir <path>] [--repo-dir <path>] [--device mps|cuda|cpu] [--host <host>] [--ceiling <value>]"
category: fleet-ops
status: candidate
---

# autoresearch-mode

**Trigger:** `autoresearch-mode` / `research-mode` / `run autoresearch weekly batch`
**Scope:** Governed autonomous ML research execution
**Parent mode:** `hummbl-governance`
**Mission type:** `RESEARCH`
**Bus identity:** `devin`

## Canonical Definition

> **autoresearch-mode** is a governed Mission-Mode instance for autonomous ML experiment design, execution, and knowledge distillation. It runs on a weekly cadence, respects cost ceilings, posts receipts to the coordination bus, and leaves structured artifacts (findings, proposals, mission closeouts) for operator review.

## One-Line Purpose

Run structured, governed, receipt-producing research experiments on a weekly cadence.

## Core Formula

```txt
autoresearch-mode =
  Scope: autoresearch workflow (pipeline + reports phases)
  + Doctrine: simplicity-first, evidence-governed, cost-bounded
  + Protected Variable: val_bpb trend + operator trust
  + Authorized: generate, execute, log, distill, propose
  + Prohibited: merge-to-main, exceed-ceiling, ignore-kill-switch
  + Activation: scripts/weekly_run.py --pipeline-dir . --repo-dir ~/repo
  + Receipt: bus posts + git commits + MissionCloseout
  + Exit: completed | abort (kill-switch) | failure (crash)
```

## PSI Stack (Cognitive Safety)

| Layer | File | Purpose |
|-------|------|---------|
| WM.md | `autoresearch-pipeline/WM.md` | World model — what the agent knows about the external research space |
| MM.md | `autoresearch-pipeline/MM.md` | Mental model — what the agent knows about itself |
| Base120 | `hummbl_governance/cognition/lattice_advisor.py` | Canonical reasoning operators — how the agent should reason |

## Activation

### Manual (operator-initiated)

```bash
cd /output/target-pipeline
python scripts/weekly_run.py \
  --pipeline-dir . \
  --repo-dir ~/my-experiment-repo \
  --device mps \
  --host remote-node  # remote-node dormant since 2026-07-01 — use --host agent-node --device cuda instead
```

### Scheduled (launchd)

```bash
# Install
ln -s $(pwd)/scripts/com.hummbl.autoresearch.weekly.plist \
  ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.hummbl.autoresearch.weekly.plist
```

## Mode Anatomy

### 1. Attention

- `val_bpb` trend (improving, flat, or degrading)
- Hardware health (GPU temp, OOM events, disk space)
- Queue freshness (pending topics, stale completed items)
- External research signals (new papers, new forks)
- Cognitive bias triggers (repetitive parameter changes, neglect of IN domain)

### 2. Authority

- **Agent** can: propose experiments, run them, log results, draft findings
- **Agent** cannot: merge findings to `main` without operator review; exceed cost ceiling; run experiments on operator-owned machines without approval
- **Operator** must: approve the weekly topic selection; review proposals before they become action items
- **Kill switch** overrides both: emergency halt requires no approval

### 3. Behavior

**Authorized:**
1. Select pending topic from queue (prioritized by tier + last_run)
2. Run healthcheck before experiment generation
3. Generate experiment via supervisor (with optional Base120 reasoning guidance)
4. Execute via worker
5. Evaluate significance (MAD scoring)
6. Log results to `results.tsv`
7. Draft findings if results are actionable
8. Update queue status
9. Post receipts to coordination bus
10. Commit artifacts to `autoresearch-reports`

**Prohibited:**
1. Never commit directly to `main` of any repo
2. Never send messages on behalf of the operator
3. Never run experiments on agent-node without `--device cuda` override
4. Never modify `prepare.py` (ground truth must be preserved)
5. Never exceed `MAX_EXPERIMENT_DURATION_MINUTES` without operator approval
6. Never ignore a `HALT_ALL` kill switch signal
7. Never propose an experiment that repeats a failed hypothesis (check ASI store first)

### 4. Boundary

**Hard boundaries:**
- Cost ceiling: $X/month for cloud compute; Workstation/remote-node are "free" (owned) — **note: remote-node dormant since 2026-07-01, only Workstation available**
- Time ceiling: Max 4 hours per weekly batch (operator availability)
- Safety ceiling: Any `HALT_NONCRITICAL` or `HALT_ALL` signal stops the mission immediately
- Data ceiling: Never upload proprietary data to external services

**Soft boundaries:**
- Simplicity preference: favor deletions over additions
- Cross-platform fairness: don't compare MPS and CUDA results directly
- Human-in-the-loop: findings become proposals only after operator review

### 5. Memory

- `WM.md` — the evolving world model
- `MM.md` — the evolving self-model
- `results.tsv` — raw experiment outcomes
- `findings/*.md` — distilled knowledge
- `proposals/*.md` — proposed actions
- `asi_store.jsonl` — failed hypotheses and their lessons
- `factor_model.json` — Bayesian beliefs about parameter effects
- `lessons_learned.md` — weekly self-evolution output
- CLP ledger entries — reasoning traces for audit

### 6. Receipt

**Evidence the mode leaves behind:**
1. **Bus posts:** `WIP_START`, `WIP_END`, `STATUS`, `MILESTONE`, `BLOCKED`
2. **Git commits:** On `feat/devin/*` branches, never `main`
3. **MissionCloseout:** Structured closeout with all metrics
4. **Findings:** Markdown documents with evidence and confidence scores
5. **Proposals:** Markdown documents with implementation plans
6. **CHANGELOG.md:** Versioned record of pipeline changes

### 7. Exit Criteria

**Graceful exit:**
- All experiments completed successfully
- Queue updated with new status
- Findings and proposals drafted
- MissionCloseout posted
- `WIP_END` on bus

**Abort exit:**
- Kill switch engaged (DISENGAGED → HALT_NONCRITICAL → HALT_ALL)
- Cost ceiling exceeded
- Hardware failure (GPU OOM, disk full, SSH disconnect)
- Operator sends "abort" signal
- Healthcheck fails 3 consecutive times

**Failure exit:**
- Supervisor crashes and cannot recover
- Worker produces NaN/Inf for 5 consecutive experiments
- Factor model becomes unrecoverable (all parameters have zero variance)

## Kill Switch Semantics

| Mode | Supervisor Action | Worker Action |
|------|-------------------|---------------|
| `DISENGAGED` | Continue normal operation | Continue normal operation |
| `HALT_NONCRITICAL` | Don't start new batches after current | Finish current experiment, then stop polling |
| `HALT_ALL` | Abort immediately, log state | Abort immediately, transition run to `failed` |
| `EMERGENCY` | Terminate process | `sys.exit(1)` |

## Bus Protocol

### Required during mission
- `WIP_START` — at mission start
- `WIP_END` — at mission closeout

### Allowed during mission
- `STATUS` — progress updates
- `MILESTONE` — experiment completed
- `BLOCKED` — failure or obstruction

### Suspended during mission (will raise `MissionBusFilterError`)
- `RESEARCH` — use `STATUS` instead
- `PROPOSAL` — deferred to post-mission
- `DECISION` — only operator makes decisions during research

### Deferred during mission
- `QUESTION` → converted to `QUEUED`

## Required Repositories

| Repo | Purpose | Required? |
|------|---------|-----------|
| `autoresearch-pipeline` | The pipeline itself | Yes |
| `autoresearch-reports` | Findings, proposals, runbook | Yes |
| `hummbl-governance` | Mission mode, Base120, kill switch, bus | Optional (graceful fallback) |

## Files

| File | Role |
|------|------|
| `scripts/weekly_run.py` | Main orchestrator |
| `scripts/queue_recurrence.py` | Auto-reschedule completed topics |
| `scripts/proposal_drafter.py` | Generate proposals from findings |
| `scripts/self_evolve.py` | Weekly self-evolution (MM.md update) |
| `scripts/mission_mode_stub.py` | Standalone mission primitives |
| `supervisor/supervisor.py` | Experiment generation |
| `worker/worker.py` | Experiment execution |
| `WM.md` | World model |
| `MM.md` | Mental model |

## Related

- **ADR-FM-0XX:** PSI (Psychological Safety Infrastructure) as 8th governance primitive
- **F-007-HARDENED:** Principal Engineer review of mode alignment
- **MODE_GENERAL_DOCTRINE.md:** Canonical *-mode definition
- **mission_mode.py:** Mission mode runtime service
- **mission_mode_bus_filter.py:** Bus type filtering during missions

## Skill Chains

### Mandatory

- **[MANDATORY]** Before any manual run, schedule installation, commit, or bus
  post, obtain a named operator or delegated assignment that identifies the
  pipeline directory, repository, research scope, host/device, and explicit
  time and cost ceilings.
- **[MANDATORY]** Verify the kill-switch state and retain a session-start
  receipt before the first stateful action. Stop immediately when the assigned
  ceiling or kill-switch boundary is reached.

## Authority

- **T1 (TRUSTED)**: May run an explicitly assigned, bounded
  experiment and record its receipts; may not merge to `main` or exceed the
  assigned ceiling.
- **T2 (Active/High)**: May run an explicitly assigned, bounded experiment
  and record its receipts; may not change the schedule or target an unassigned
  host.
- **T3 (Medium)**: BLOCKED — may perform read-only planning or inspection, but
  must not run experiments, install schedules, commit artifacts, or post bus
  receipts.
- **T4 (Probationary)**: BLOCKED — may not invoke this skill.
- **Operator**: Required to install or change a schedule, target a host outside
  the assignment, raise a time or cost ceiling, or authorize an exception.

## Version

0.2.0 — 2026-08-31
