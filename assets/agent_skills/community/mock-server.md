---
name: mock-server
description: Spin up a mock HTTP server from API schema or example responses using stdlib http.server
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<schema_or_dir> [--port 9999] [--latency 50ms]"
category: backend-infra
status: candidate
---
# mock-server | Stdlib Mock HTTP Server

## When to Use
- Integration testing without hitting real APIs (GitHub, Linear, Google Calendar)
- Developing against an API that is not yet available
- Reproducing specific error scenarios (timeouts, 500s, rate limits)
- Testing circuit breaker and retry behavior with controlled failures

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=mock-server] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Parse Arguments
- `$ARGUMENTS`: path to schema file, examples directory, or inline JSON
- `--port`: port to bind (default 9999)
- `--latency`: artificial response delay (default 0ms)
- `--error-rate`: percentage of requests that return 500 (default 0)
- `--timeout-rate`: percentage of requests that hang (default 0)

### 2. Build Route Table
From schema or examples directory, create route mappings:
- Each `.json` file in examples becomes a GET endpoint
- Schema endpoints get auto-generated valid responses
- Support for path parameters via simple pattern matching
- Default 404 handler for unmatched routes

### 3. Generate Server Script
Create a Python script using only `http.server` and `json`:
```python
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, time, random

class MockHandler(BaseHTTPRequestHandler):
    ROUTES = { ... }  # populated from step 2
    
    def do_GET(self):
        # latency simulation
        # error rate simulation
        # route matching and response
```

### 4. Start Server
Run the generated script in background. Verify it responds to health check.
Print the PID and port for later cleanup.

### 5. Usage Instructions
Provide the exact environment variables or config to point adapters at the mock:
- `GITHUB_API_URL=http://localhost:9999`
- Adapter-specific override patterns

## Output Format

```
mock-server | <source>

## Server Started
- PID: 12345
- URL: http://localhost:9999
- Routes: 8 endpoints

## Route Table
| Method | Path              | Response | Latency |
|--------|-------------------|----------|---------|
| GET    | [health]           | 200      | 0ms     |
| GET    | /api/repos        | 200      | 50ms    |
| POST   | /api/events       | 201      | 50ms    |
| GET    | /api/error        | 500      | 0ms     |

## Adapter Config
export GITHUB_API_URL=http://localhost:9999

## Cleanup
kill 12345  # or: [mock-server] stop
```

## Skill Chains

### Mandatory

None — local mock server with no external impact.

### Advisory

- **Routing**: See `harness-routing.md` for SUT-type routing. This skill covers mock HTTP servers only.
- After starting mock → `[api-test]` against it
- After testing → `[load-test]` against mock for baseline
- For contract testing → `[contract-test] --service http://localhost:9999`

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (local server, no external impact)
- **Operator**: Override any restriction
