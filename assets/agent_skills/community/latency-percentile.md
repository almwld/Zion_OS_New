---
name: latency-percentile
description: Analyze latency distributions — p50/p90/p95/p99/p99.9 with tail latency identification and SLO burn rate
version: 0.1.0
execution-mode: advisory
argument-hint: "<latency-data> [--percentiles 50,90,95,99,99.9] [--slo <ms>]"
category: backend-infra
status: candidate
---
# latency-percentile | Latency Distribution and SLO Analysis

## When to Use
- Analyzing production latency data to understand tail behavior
- Checking SLO compliance and computing burn rate
- Comparing latency before and after a deployment
- Identifying outliers and their contributing factors

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: latency data (CSV, JSONL, or log file with latency column)
- `--percentiles 50,90,95,99,99.9`: percentiles to compute (default: all five)
- `--slo <ms>`: target latency SLO (e.g. `200` for 200ms at p99)
- `--slo-target 99`: which percentile the SLO applies to (default 99)

### 2. Load and Validate Data
- Read latency values into a sorted array
- Detect and report unit (ms, us, s) from column name or values
- Remove negative or zero values (invalid latencies)
- Report count, min, max, and any gaps in timestamps

### 3. Compute Percentiles
- Sort latencies (if not already sorted)
- For each requested percentile, compute using nearest-rank method:
  - `p_k = values[ceil(k/100 * N) - 1]`
- Also compute mean, median, and standard deviation
- Report in human-readable units (ms, s)

### 4. Tail Latency Analysis
- Identify top 0.1% slowest requests; compute p99/p50 ratio (flag if > 10x)
- Cluster outliers by timestamp; report IQR for robustness

### 5. SLO Burn Rate (if --slo)
- Compute fraction exceeding SLO threshold; burn rate = `actual_error_rate / allowed_error_rate`
- Allowed error rate = `1 - (slo_target / 100)`
- Fast burn: > 14.4x (2% budget in 1 hour) | Slow burn: > 1x
- Report budget remaining and projected exhaustion time

### 6. Distribution Visualization
- Generate ASCII histogram with SLO threshold and percentile markers
- Identify bimodal patterns (cache hit vs miss, fast vs slow path)

## Output Format

```
latency-percentile | <data-source>

## Configuration
- Samples: 50,000 | Unit: ms | SLO: 200ms at p99

## Percentiles
| Percentile | Latency (ms) |
|------------|--------------|
| p50        | 45           |
| p90        | 120          |
| p95        | 180          |
| p99        | 340          |
| p99.9      | 890          |

## Summary
- Mean: 72 ms | Median: 45 ms | Stdev: 95 ms
- Min: 8 ms | Max: 1,240 ms
- Tail ratio (p99/p50): 7.6x

## SLO Analysis
- SLO: 200ms at p99 | Target: 99% under threshold
- Actual: 98.2% under threshold | Error rate: 1.8%
- Allowed error rate: 1.0% | Burn rate: 1.8x (SLOW BURN)
- Budget remaining: 64% | Projected exhaustion: 11 days

## Tail Outliers
- Top 0.1%: 890-1,240 ms (50 requests)
- Temporal cluster: 14:00-14:05 UTC (coincides with deploy)

## Verdict
SLO_VIOLATION / SLOW_BURN / HEALTHY / INSUFFICIENT_DATA
```

## Skill Chains
- After SLO analysis -> `[sla-track]` to update SLA reports
- After latency profiling -> `[web-perf]` for web-specific optimization
- Before benchmarking -> `[benchmark]` to establish comparison baseline
- For streaming inference latency -> `[stream-inference]` to generate TTFT and total latency data for Cloudflare Workers AI (`python ~/bin/stream_test.py <model> --prompt "test"`)
