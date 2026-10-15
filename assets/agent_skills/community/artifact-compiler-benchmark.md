---
name: artifact-compiler-benchmark
description: Run multi-dimensional latency, memory, and scaling benchmarks for the Compatibility-Aware Artifact Compiler, with optional automated postings to the HUMMBL cognitive ledger.
version: 1.0.0
execution-mode: side_effecting
argument-hint: "[--iterations N] [--post-ledger]"
category: backend-infra
status: candidate
---
# artifact-compiler-benchmark | Artifact Compiler Benchmarking

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=artifact-compiler-benchmark] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

## When to Use
- Establishing performance baselines for format detection, compatibility grading, and document serialization.
- Profiling Markdown parser scaling, memory consumption, and block survival fidelity.
- Recording performance assertions and baseline drift to the global HUMMBL Cognitive Ledger.

## Execution

To execute this benchmark harness, run the standalone profiling script located within the `artifact-compiler` workspace.

```powershell
# Run from $env:USERPROFILE\PROJECTS\artifact-compiler
$env:PYTHONPATH="src"
python tests/benchmark_harness.py [--iterations N] [--post-ledger]
```

### Options:
- `--iterations N`: Override the default profiling iteration count (default: 500 iterations for micro-components, 50 iterations for scaling).
- `--post-ledger`: Calculate the final report metrics and append a beautifully serialized summary record directly to the HUMMBL Cognitive Ledger (`ledger.jsonl`).

## Output Manifests
All raw execution results are exported as a structured JSON manifest at:
`$env:USERPROFILE\PROJECTS\artifact-compiler\_state\benchmarks\performance_report.json`

## Baseline Metrics (Verified win32 Ryzen 7)
- **Format Detection**: ~0.176 ms mean latency (5676.2 ops/s) | ~27.0 KB peak heap footprint.
- **Compatibility Checks**: ~0.002 ms mean latency (560098.6 ops/s).
- **Serialization Roundtrip**: ~3.192 ms mean latency (313.3 ops/s) | ~190.2 KB peak heap footprint.
- **Markdown Parser Scaling**:
  - **1KB**: ~1.60 ms mean latency | ~24.8 KB peak heap (30 blocks survived)
  - **10KB**: ~11.04 ms mean latency | ~174.3 KB peak heap (233 blocks survived)
  - **100KB**: ~109.50 ms mean latency | ~1655.6 KB peak heap (2214 blocks survived)

## Related Skills
- `[benchmark]` — General stdlib function profiling.
- `[ledger]` — Post and search the HUMMBL Cognitive Ledger.

## Skill Chains

### Mandatory

None — benchmark execution is read-only performance measurement; no production state is modified.

### Advisory

- After `[artifact-compiler-benchmark]` → `[ledger]` to search prior benchmark records for trend comparison
- After `[artifact-compiler-benchmark] --post-ledger` → `[benchmark]` for general stdlib function profiling
- After baseline drift detected → `[commit]` to record updated baseline metrics

## Authority

- **T1 (TRUSTED)**: May run freely
- **T2 (Active/High)**: May run freely
- **T3 (Medium)**: May run freely
- **T4 (Probationary)**: May run (read-only benchmarks — no production state modified)
- **Operator**: Override any restriction
