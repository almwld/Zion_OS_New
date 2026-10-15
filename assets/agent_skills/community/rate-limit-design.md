---
name: rate-limit-design
description: Design rate limiting strategy for APIs with algorithm selection and code generation
version: 0.1.0
execution-mode: advisory
argument-hint: "<endpoint> [--strategy token-bucket|sliding-window|fixed-window] [--limit N/period]"
category: fleet-ops
status: candidate
---
# Rate Limit Design

Design and implement rate limiting for API endpoints. Supports token bucket, sliding window, and fixed window algorithms with per-client quotas, burst handling, and stdlib-only Python code generation.

## When to Use
- Designing a new API that needs request throttling
- Adding rate limits to an existing endpoint experiencing abuse or overload
- Comparing rate limiting algorithms for a specific use case
- Generating stdlib-only rate limiter code for the hummbl-governance project

## Execution
1. Parse `$ARGUMENTS` for endpoint name, `--strategy` (default: `token-bucket`), and `--limit` (e.g., `100/minute`)
2. Analyze the endpoint's expected traffic pattern (burst vs steady, authenticated vs anonymous)
3. Select and explain the chosen algorithm with tradeoffs vs alternatives
4. Generate stdlib-only Python implementation (no Redis, no third-party deps)
5. Include per-client tracking, response headers (X-RateLimit-Limit, X-RateLimit-Remaining, Retry-After), and 429 response handling
6. Generate test cases covering normal flow, limit hit, window reset, and concurrent access
7. Document configuration parameters and tuning guidance

## Output Format
```
Rate Limit Design | {endpoint}
────────────────────────────────
Strategy: {algorithm}
Limit: {N} requests per {period}
Burst: {burst allowance}

Algorithm Comparison:
| Algorithm       | Pros              | Cons              | Fit |
|-----------------|-------------------|-------------------|-----|
| Token Bucket    | smooth bursts     | memory per client  | ... |
| Sliding Window  | precise fairness  | higher computation | ... |
| Fixed Window    | simple, fast      | boundary spikes    | ... |

Implementation: {file path or inline code}
Tests: {test count and coverage}
Headers: X-RateLimit-Limit, X-RateLimit-Remaining, Retry-After
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Rate limiter designed | `[api-design]` to integrate into the endpoint contract |
| Implementation complete | `[load-test]` to verify behavior under pressure |
| Config parameters defined | `[config-matrix]` to test limit combinations |
| Cloudflare Neuron ceiling informs rate limit design | `[usage-monitor]` (`python ~/bin/usage_monitor.py status`) |
