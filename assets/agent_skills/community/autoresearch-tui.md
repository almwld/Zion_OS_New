---
name: autoresearch-tui
description: Real-time observability TUI for the autoresearch overnight GPU training loop. One file, stdlib only, ANSI + UTF-8.
version: 0.1.0
execution-mode: advisory
category: observability
status: candidate
---

# autoresearch-tui

Real-time observability TUI for the autoresearch overnight GPU training loop. One file, stdlib only, ANSI + UTF-8.

## When to use

- Operator asks "what's the GPU doing?" or "how's the overnight loop going?"
- You need to check experiment progress, val_bpb trend, or GPU health without killing the supervisor/worker processes
- Morning harvest: checking what experiments ran overnight and which ones kept
- Detecting failures: circuit-breaker trips, OOM, thermal issues, queue stalls

## How to launch

```bash
cd ~\PROJECTS\autoresearch-pipeline
python tui.py
```

With explicit paths (if cwd differs):

```bash
python tui.py --pipeline-dir ~\PROJECTS\autoresearch-pipeline --repo-dir ~\PROJECTS\autoresearch-win-rtx --interval 5
```

- `--interval` defaults to 5 seconds. Use `--interval 10` for less flicker.
- Ctrl+C to exit. The TUI does NOT touch the GPU or the pipeline — it only reads.
- Safe to run alongside the supervisor+worker loop. No side effects.

## What it shows

**Header line**: shows `refresh=Ns  cycle=N  HH:MM:SS` — the cycle counter increments each refresh, timestamp is local time.

**Note on layout**: Row numbers below are approximate. Only GPU (row 3) and EXPERIMENTS (row 5) are fixed. Sections below EXPERIMENTS shift based on how many experiments are active (0-3), since active experiments expand the patch-diff display. Don't anchor on exact row numbers — look for the section headers.

### GPU (row 3)
- **MEM bar**: VRAM used/total. Training typically uses 5-10 GB on RTX 3080 Ti (12 GB).
- **UTIL bar**: GPU compute utilization. Should be near 100% during training, drops to ~0% between experiments.
- **TEMP**: color-coded — green <75C, yellow 75-85C, red >=85C. RTX 3080 Ti throttles at 93C. If red, alert the operator.
- **PWR**: power draw in watts. Sustained ~350W is normal under full load.
- Note: the "RTX 3080 Ti" label is hardcoded in the TUI source, not probed from hardware. On a different GPU the string will still say 3080 Ti.

### EXPERIMENTS (row 5)
- **active=N**: how many experiments are in running/dispatched/queued state.
- **total_seen=N**: cumulative count of all state.json files across queue/ and runs/ (includes terminal states). Useful for morning harvest — tells you total experiments the pipeline has processed.
- **branch**: the git branch experiments are committing to (e.g. `nemoclaw-experiment` or `autoresearch/sep2-overnight`).
- Each active experiment shows:
  - State (`running`, `dispatched`, `queued`)
  - Run ID (timestamp + hash)
  - Reason (e.g. "executing training")
  - **Patch diff**: red `-` lines (old value) and green `+` lines (new value) — this is the mechanistic interpretability layer. Shows exactly what hyperparameter the supervisor changed.

### val_bpb PROGRESSION (row 9)
- **experiments=N**: total rows in results.tsv.
- **keeps=N**: experiments with status=keep (val_bpb improved).
- **best=**: lowest val_bpb achieved, with delta vs baseline (green if below baseline, red if above).
- **sparkline**: Unicode bar chart of keep-history. Taller bars = lower val_bpb = better (inverted so "up = good").
- **Results table**: last 8 experiments with commit hash, val_bpb (+delta), memory, status (green=keep, yellow=discard, red=crash), and description.

### HYPERPARAMETERS (row ~14)
- All params parsed from the current `train.py` (the file the agent edits).
- Shows `N params tracked` count. Typically 18-27 depending on train.py structure.
- Shows live drift: as experiments modify train.py, these values change.
- Key params: DEPTH, ASPECT_RATIO, HEAD_DIM, TOTAL_BATCH_SIZE, MATRIX_LR, EMBEDDING_LR, SCALAR_LR, UNEMBEDDING_LR, WARMDOWN_RATIO, WEIGHT_DECAY, FINAL_LR_FRAC.
- If TOTAL_BATCH_SIZE shows `262144.0` instead of `524288.0`, an experiment halved the batch size.
- Parser limitation: only matches `^[A-Z_]+ = ...` lines (uppercase, start-of-line). Lowercase or indented params won't appear. Handles `2 ** N` expressions.

### EXPERIMENT LINEAGE (row 21)
- Git log on the experiment branch. Each commit is one experiment.
- Format: `<short-hash> [autoresearch] <run-id>` or the original baseline commit.
- Use this to trace the experiment chain: each experiment branches from the last accepted (kept) result.

### LIVE LOGS (row 29)
- Tails of `supervisor.log` and `worker.log` if they exist in the pipeline directory.
- If logs aren't piped to files (running as background shells), shows a hint with the shell IDs.

## How to read it for morning harvest

1. **Check val_bpb PROGRESSION**: how many experiments ran? How many kept? What's the best delta vs baseline?
2. **Check the results table**: scan for `crash` status (red) — those are failed experiments. Look at descriptions for what was tried.
3. **Check HYPERPARAMETERS**: what's the current state of train.py? Which params drifted from baseline?
4. **Check EXPERIMENT LINEAGE**: git log shows the experiment chain. Each `[autoresearch]` commit is one experiment.
5. **Check GPU**: if util is 0% and no active experiments, the loop may have stopped (circuit-breaker or queue exhausted).

## Failure modes to watch for

| Signal | Meaning | Action |
|--------|---------|--------|
| TEMP red (>=85C) | Thermal risk | Alert operator. GPU auto-throttles at 93C. |
| UTIL 0% + no active experiments | Loop stopped | Check supervisor log for circuit-breaker or queue exhaustion. |
| Many `crash` statuses in results | Repeated failures | Worker circuit-breaker trips after 3 consecutive identical failures. Check what perturbation caused crashes. |
| val_bpb not improving over many experiments | Supervisor stuck in local minimum | May need to restart supervisor or adjust PERTURBATION_RULES. |
| MEM bar near full | VRAM creep | Experiments increasing model/batch size. Worker should reject OOM runs but watch for it. |

## What NOT to do

- Do NOT kill the supervisor or worker processes from the TUI. The TUI is read-only.
- Do NOT modify train.py, results.tsv, or queue/ files while the TUI is running — the pipeline owns those.
- Do NOT launch the TUI if you're not on the same machine as the GPU (nvidia-smi won't work).

## Source

- TUI file: `~\PROJECTS\autoresearch-pipeline\tui.py`
- Pipeline: `~\PROJECTS\autoresearch-pipeline`
- Training repo: `~\PROJECTS\autoresearch-win-rtx`
- Reports depot: `~\PROJECTS\autoresearch-reports`

## Chain

- Morning harvest → read TUI → check results.tsv → git log → harvest reports from autoresearch-reports/reports/
- Failure detected → read supervisor/worker logs → diagnose → alert operator with specifics
- After loop completes → copy runs/ artifacts to autoresearch-reports/reports/ and findings/
