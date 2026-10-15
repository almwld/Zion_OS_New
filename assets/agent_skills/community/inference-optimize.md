---
name: inference-optimize
description: Optimize ML inference with KV-cache, batching, speculative decoding, and attention optimization
version: 0.1.0
execution-mode: advisory
argument-hint: "<model-path> [--technique kv-cache|batching|speculative|flash-attn]"
category: backend-infra
status: candidate
---
# inference-optimize | Optimize ML Inference Latency & Throughput

## When to Use
- Reducing per-token inference latency for interactive applications
- Maximizing throughput under concurrent request load
- Profiling and eliminating inference bottlenecks (attention, memory bandwidth)
- Preparing a model for production serving with tuned runtime config

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: `<model-path>` (HF repo or local dir)
- `--technique`: `kv-cache` | `batching` | `speculative` | `flash-attn` (default `kv-cache`)
- `--batch-size`: concurrent request batch size (default 8)
- `--spec-model`: draft model for speculative decoding (if technique=speculative)
- `--seq-len`: benchmark sequence length (default 512)

### 2. Baseline Measurement
- Load model with default config and run inference on benchmark prompts
- Measure tokens/second, first-token latency, and VRAM usage
- Profile with `torch.profiler` to identify bottleneck (attention, matmul, memory)
- Record baseline metrics for comparison

### 3. Apply Optimization Technique
- **kv-cache**: enable past-key-values caching; configure cache budget and eviction policy
- **batching**: enable continuous/dynamic batching; tune max batch size and wait time
- **speculative**: load small draft model; verify accepted tokens per step (target 2-3x speedup)
- **flash-attn**: replace standard attention with FlashAttention-2; verify numerical equivalence

### 4. Benchmark Optimized Inference
- Re-run same benchmark prompts with optimization applied
- Measure tokens/second, first-token latency, VRAM usage
- Compare against baseline; flag if speedup < 1.3x (insufficient gain)
- Verify output tokens match baseline (tolerance: identical or <1% divergence)

### 5. Generate Config Recommendations
- Produce optimized serving config (batch size, cache budget, draft model path)
- Note hardware-specific flags (tensor parallelism, CUDA graphs)
- Save config to `<model-path>-inference-config.json`

## Output Format

```
inference-optimize | <model-path>

## Configuration
- Technique: flash-attn | Batch size: 8 | Seq len: 512

## Benchmark Results
| Metric            | Baseline   | Optimized  | Speedup |
|-------------------|------------|------------|---------|
| Tokens/second     | 142        | 387        | 2.72x   |
| First-token lat   | 85 ms      | 32 ms      | 2.66x   |
| VRAM usage        | 16.2 GB    | 14.8 GB    | -8.6%   |
| Output match      | --         | identical  | OK      |

## Profiler Hotspots
| Op            | Baseline time | Optimized time |
|---------------|---------------|----------------|
| attention     | 45.2 ms       | 12.1 ms        |
| matmul        | 18.3 ms       | 18.1 ms        |
| memory bound  | 22.1 ms       | 9.4 ms         |

## Verdict
OPTIMIZED | 2.72x throughput | flash-attn | output identical
```

## Skill Chains
- After optimization -> `[latency-percentile]` to measure tail latency
- After optimization -> `[benchmark]` to establish optimized baseline
- Before optimization -> `[model-serve]` to have a running server to tune
- Before optimization -> `[stream-inference]` to measure TTFT and throughput via `python ~/bin/stream_test.py --model <model> --prompt "test" --raw`
- For validate Neuron savings after optimization -> `[usage-monitor]` (`python ~/bin/usage_monitor.py status`)
