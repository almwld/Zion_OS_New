---
name: api-test
description: Generate and run HTTP API tests against live or mocked endpoints
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<base_url> [--schema path] [--endpoints GET /health,POST /api/bus]"
category: backend-infra
status: candidate
---
# api-test | HTTP API Testing

## When to Use
- Validating API endpoints after deployment or changes
- Smoke testing dashboard API (port 8000) or Open Brain (port 11435)
- Verifying response schemas match contracts
- Testing error handling and edge cases

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=api-test] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Parse Arguments
- `$ARGUMENTS`: base URL (required)
- `--schema`: path to OpenAPI or JSON schema for validation
- `--endpoints`: comma-separated METHOD [path] pairs to test
- If no endpoints specified, discover from schema or try common ones ([health], /api/status)

### 2. Build Test Suite
For each endpoint, generate tests:
- **Happy path**: valid request, expect 2xx
- **Status code**: verify exact expected code (200, 201, 204)
- **Headers**: verify Content-Type, CORS headers if applicable
- **Response body**: validate against schema if provided
- **Error cases**: missing auth, bad input (expect 4xx), invalid method (expect 405)

### 3. Execute Tests
Use `urllib.request` for all HTTP calls. For each test:
- Record: method, url, status, latency, response body, headers
- Timeout: 10s per request
- Capture both success and failure details

### 4. Schema Validation
If schema provided, validate each response body:
- Use `your_project.cognition.schema_validator` (stdlib JSON Schema)
- Or manual field presence/type checks
- Report schema mismatches with path to failing field

### 5. Generate Report
Aggregate pass/fail counts, list all failures with details.

## Output Format

```
api-test | <base_url>

## Summary
- Endpoints tested: 5
- Tests run: 18
- Passed: 16 | Failed: 2

## Results
| Endpoint       | Method | Status | Latency | Schema | Result |
|----------------|--------|--------|---------|--------|--------|
| [health]        | GET    | 200    | 12ms    | VALID  | PASS   |
| /api/bus       | GET    | 200    | 45ms    | VALID  | PASS   |
| /api/bus       | POST   | 405    | 3ms     | --     | PASS   |
| /api/agents    | GET    | 500    | 102ms   | --     | FAIL   |

## Failures
1. GET /api/agents -- Expected 200, got 500. Body: "Internal Server Error"
2. POST /api/bus -- Schema mismatch: field "timestamp" expected string, got null

## Next Actions
- [ ] Fix /api/agents 500 error
- [ ] Update contract for /api/bus timestamp field
```

## Skill Chains

### Mandatory

None — test execution is read-only against test endpoints; no persistent state is modified.

### Advisory

- **Routing**: See `harness-routing.md` for SUT-type routing. This skill covers HTTP APIs only. For Cloudflare Workers use chain: `wrangler dev` → `api-test`.
- Before testing → `[port-map]` to verify services are listening
- After schema failures → `[contract-test]` for deeper contract validation
- After fixing failures → `[api-test]` again to verify

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Run with operator notification for live endpoints
- **T4 (Probationary)**: May run against mocks only
- **Operator**: Override any restriction
