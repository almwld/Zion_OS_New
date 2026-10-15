---
name: uptime-check
description: HTTP health check across multiple endpoints with latency measurement and status codes
version: 0.1.0
execution-mode: advisory
argument-hint: "<url...> [--timeout SECONDS] [--expected-status 200]"
category: backend-infra
status: candidate
---
# Uptime Check

Perform HTTP health checks against one or more endpoints, measuring response latency, verifying status codes, and detecting outages. Useful for quick service availability sweeps and pre-deploy verification.

## When to Use
- Verifying all services are up after a deploy or restart
- Periodic availability sweep of production endpoints
- Debugging intermittent connectivity or latency issues
- Pre-launch readiness check for all public-facing URLs

## Execution
1. Parse `$ARGUMENTS` for URL list, `--timeout` (default: 10s), and `--expected-status` (default: 200).
2. For each URL, send an HTTP GET request using `curl -o /dev/null -s -w` to capture status code, total time, DNS time, and connect time.
3. Compare returned status code against expected status.
4. Flag any response exceeding 2x the average latency as SLOW.
5. Flag any non-matching status code or timeout as DOWN.
6. Calculate aggregate statistics: average latency, p95, availability percentage.

## Output Format
```
Uptime Check | <endpoint-count> endpoints

| Endpoint | Status | Latency | DNS | Connect | Result |
|----------|--------|---------|-----|---------|--------|
| https://api.example.com/health | 200 | 142ms | 12ms | 28ms | OK |
| https://app.example.com | 200 | 89ms | 8ms | 15ms | OK |
| https://old.example.com | 503 | 2104ms | 11ms | 30ms | DOWN |

Summary: 2/3 UP (66.7%) | Avg latency: 778ms | p95: 2104ms

Findings:
- [CRITICAL] old.example.com returned 503 (expected 200)
- [WARNING] old.example.com latency 2104ms exceeds threshold

Next action: Investigate old.example.com -- check server logs and load balancer.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Endpoint down | `[alert-rule]` to set up monitoring notification |
| Endpoint down in production | `[incident]` for triage and response |
| All endpoints healthy | `[status-page]` to update public status |
