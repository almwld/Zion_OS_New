---
name: load-test
description: Generate and run HTTP load tests with stdlib urllib and concurrent.futures
version: 0.1.0
execution-mode: advisory
argument-hint: "<url> [--rps 50] [--duration 30] [--concurrency 10]"
category: backend-infra
status: candidate
---
# load-test | HTTP Load Testing

## When to Use
- Validating endpoint performance before deployment
- Stress testing dashboard API, Open Brain server, or health endpoints
- Establishing throughput baselines for capacity planning
- Detecting performance regressions after changes

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: target URL (required), optional flags
- Defaults: 50 rps, 30s duration, 10 concurrent workers
- Validate URL is reachable with single HEAD request first

### 2. Generate Load Test Script
Create a temporary Python script using only stdlib:
- `urllib.request` for HTTP calls
- `concurrent.futures.ThreadPoolExecutor` for concurrency
- `time.perf_counter_ns()` for precise latency measurement
- `statistics` module for percentile calculations
- Collect: status code, latency, response size per request

### 3. Execute Load Test
Run the generated script. Capture all response times in a list.
Print live progress every 5 seconds (requests completed, current error rate).

### 4. Compute Statistics
- Latency: p50, p75, p90, p95, p99, max
- Throughput: requests/sec achieved
- Error rate: non-2xx responses / total
- Transfer rate: total bytes / duration

### 5. Regression Check
Compare against baseline in `_state/benchmarks/load/` if it exists.
Flag if p95 increased >20% or error rate increased >1%.

## Output Format

```
load-test | <url>

## Configuration
- Target: <url>
- Concurrency: 10 | Duration: 30s | Target RPS: 50

## Results
- Total requests: 1,500
- Successful: 1,485 (99.0%)
- Failed: 15 (1.0%)

## Latency (ms)
| p50  | p75  | p90  | p95  | p99  | max   |
|------|------|------|------|------|-------|
| 12.3 | 18.7 | 25.1 | 42.0 | 89.3 | 150.2 |

## Throughput
- Requests/sec: 48.2
- Transfer: 2.3 MB/s

## Errors
- 408 Timeout: 10
- 503 Service Unavailable: 5

## Verdict
PASS / FAIL (with reason)
```

## Skill Chains
- **Routing**: See `harness-routing.md` for SUT-type routing. This skill covers HTTP load testing only.
- Before load test -> `[port-map]` to verify service is running
- After regression found -> `[perf-profile]` on the endpoint handler
- After establishing baseline -> `[benchmark]` to persist it
- For streaming TTFT not captured by HTTP load tests -> `[stream-inference]` (`python ~/bin/stream_test.py --model <model> --prompt test`)
