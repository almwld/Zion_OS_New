---
name: deploy-canary
description: Post-deploy endpoint verification loop — polls endpoints after git push, posts BLOCKED or STATUS to bus
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--endpoints URL1,URL2] [--checks N] [--interval Ns] [--branch BRANCH]"
category: backend-infra
status: candidate
---
# Deploy Canary

Monitor endpoints after a deploy to verify they still respond. Polls git for push events, then runs HTTP checks against configured endpoints. Posts results to the coordination bus.

## When to Use
- After deploying a Cloudflare Worker or any web service
- After pushing changes that affect live endpoints
- When you need automated post-deploy verification
- As a safety net during CF Worker wiring (e.g., hummbl.io/assessment)

## Usage

```
[deploy-canary]                                          # defaults: hummbl.io endpoints, 10 checks, 30s
[deploy-canary] --endpoints https://hummbl.io/assessment,https://api.hummbl.io/assessment-capture
[deploy-canary] --checks 5 --interval 15s
[deploy-canary] --branch feat/claude/assessment-worker    # watch specific branch
```

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=deploy-canary] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### Phase 1: Detect Deploy (optional — skip if `--now` flag set)

1. Record current `origin/main` HEAD: `git rev-parse origin/main`
2. Poll at `--interval` (default 30s) for HEAD change: `git fetch origin main --quiet && git rev-parse origin/main`
3. When HEAD changes, log the new commit and proceed to Phase 2
4. If `--now` is passed, skip detection and go straight to verification

### Phase 2: Endpoint Verification Loop

1. Parse `--endpoints` (default: `https://hummbl.io/assessment,https://api.hummbl.io/assessment-capture`)
2. For each check iteration (default 10, at `--interval` default 30s):
   a. For each endpoint:
      - `curl -s -o /dev/null -w "%{http_code}" --max-time 10 <URL>`
      - Record HTTP status code and latency
   b. Display progress line per iteration
3. **On any non-200 response**:
   - Post BLOCKED to bus immediately:
     ```
     Type: BLOCKED
     To: all
     Message: deploy-canary: <URL> returned HTTP <code> at check <N>/<total>
     ```
     (The skill invocation runtime injects the caller's canonical identity as `from_id`.)
   - Continue remaining checks (don't abort — capture full failure pattern)
4. **On all-200 for all endpoints across all checks**:
   - Post STATUS to bus:
     ```
     Type: STATUS
     To: all
     Message: deploy-canary: all endpoints verified OK (<N> checks, <duration>)
     ```
     (The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### Phase 3: POST Endpoint Verification (if endpoint accepts POST)

For endpoints that are POST-capable (e.g., `assessment-capture`):
```bash
curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
  -X POST -H "Content-Type: application/json" \
  -d '{"test": true, "source": "deploy-canary"}' <URL>
```
Accept 200, 201, or 204 as success. Include result in progress display.

## Progress Display

```
Deploy Canary | hummbl.io/assessment + api.hummbl.io/assessment-capture
═══════════════════════════════════════════════════════════════

Commit: abc1234 (feat: wire assessment worker)
Endpoints: 2

[1/10]  14:22:05  hummbl.io/assessment → 200 (142ms)  api.hummbl.io/assessment-capture → 200 (89ms)
[2/10]  14:22:35  hummbl.io/assessment → 200 (138ms)  api.hummbl.io/assessment-capture → 200 (91ms)
...
[10/10] 14:26:35  hummbl.io/assessment → 200 (140ms)  api.hummbl.io/assessment-capture → 200 (88ms)

## Result
Status: PASS
Checks: 10/10
Duration: 4m 30s
All endpoints returned 200 across all checks.

Bus: STATUS posted — "deploy-canary: all endpoints verified OK (10 checks, 4m30s)"

## Next Action
No further action needed.
```

### Failure Display

```
[3/10]  14:23:05  hummbl.io/assessment → 502 (2041ms)  api.hummbl.io/assessment-capture → 200 (90ms)
  ⚠ BLOCKED posted to bus — hummbl.io/assessment returned 502

## Result
Status: FAIL
Checks: 10/10 (1 failure at check 3)
Failing endpoint: hummbl.io/assessment → HTTP 502
Duration: 4m 30s

Bus: BLOCKED posted — "deploy-canary: hummbl.io/assessment returned HTTP 502 at check 3/10"

## Next Action
Investigate the 502. Check Cloudflare Worker logs: `wrangler tail`
Consider `[rollback]` if the failure persists.
```

## Constraints

- **Max checks**: 30 (ceiling to prevent runaway loops)
- **Max interval**: 120s
- **Timeout per request**: 10s (via `--max-time`)
- **Bus posts are mandatory** — every run ends with either BLOCKED or STATUS
- **No destructive actions** — this skill only reads endpoints, never modifies them
- **Curl only** — no third-party HTTP libraries

## Skill Chains

### Mandatory

- None — this skill IS the post-deploy verification. It runs after a deploy
  to confirm endpoints are healthy. No pre-chain needed.

### Advisory

| After this skill... | Consider... |
|--------------------|-------------|
| All checks pass | `[health]` for broader system verification |
| Any check fails | `[rollback]` to revert the deploy |
| Persistent failures | `[incident]` to open a triage runbook |
| Deploy verified | `[bus]` to post a MILESTONE if it's a significant deploy |

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (read-only monitoring)
- **T3 (Medium)**: May run without restriction (read-only monitoring)
- **T4 (Probationary)**: May run (read-only — no destructive actions)
- **Operator**: Override any restriction
