---
name: port-map
description: Map listening ports to services, detect conflicts, verify expected bindings
version: 0.1.0
execution-mode: advisory
argument-hint: "[--expected] [--remote $REMOTE_HOST]"
category: backend-infra
status: candidate
---
# port-map | Port-to-Service Mapping

## When to Use
- Before starting a new service to avoid port conflicts
- Debugging connection refused errors
- Verifying all expected services are running
- Pre-flight check before integration testing

## Execution

### 1. Scan Local Ports
```bash
lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | grep -v "^COMMAND"
```
Parse: PID, process name, port, bind address.

### 2. Expected Service Map (if --expected)
Check against known service ports:

| Port  | Service            | Bind      | Machine  |
|-------|--------------------|-----------|----------|
| 3000  | Dashboard frontend | 127.0.0.1 | MBP      |
| 8000  | Dashboard API      | 127.0.0.1 | MBP      |
| 8081  | configured messaging service         | 127.0.0.1 | MBP      |
| 11434 | Ollama             | 127.0.0.1 | $REMOTE_HOST |
| 11435 | Open Brain         | 0.0.0.0   | $REMOTE_HOST |

Flag: missing expected services, unexpected ports, wrong bind addresses.

### 3. Conflict Detection
- Multiple processes on same port
- Services binding to 0.0.0.0 that should be localhost-only
- Known port collisions (e.g., Ollama disabled on MBP)

### 4. Remote Scan (if --remote $REMOTE_HOST)
```bash
ssh -o ConnectTimeout=10 $REMOTE_HOST "lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null"
```
Map $REMOTE_HOST ports against expected services.

### 5. Cross-Machine Reachability
For services expected to be reachable cross-machine:
```bash
curl -s --max-time 3 http://maks-mac-mini:11435/health  # remote-node dormant since 2026-07-01 — expected DOWN
```

## Output Format

```
port-map | <hostname>

## Listening Ports
| Port  | Process      | PID   | Bind      | Status   |
|-------|-------------|-------|-----------|----------|
| 3000  | node        | 1234  | 127.0.0.1 | OK       |
| 8000  | python      | 5678  | 127.0.0.1 | OK       |
| 8081  | java        | 9012  | 127.0.0.1 | OK       |
| 5432  | postgres    | 3456  | 127.0.0.1 | UNEXPECTED |

## Expected Services
| Service          | Port  | Status    |
|------------------|-------|-----------|
| Dashboard front  | 3000  | RUNNING   |
| Dashboard API    | 8000  | RUNNING   |
| configured messaging service       | 8081  | RUNNING   |
| Ollama           | 11434 | DISABLED (MBP) |

## Conflicts
- None (or list)

## Warnings
- Port 5432 (postgres) running but not in expected map
- Ollama correctly absent on MBP (CPU constraint)
```

## Skill Chains
- Before starting services -> `[port-map]` to check for conflicts
- After port conflict -> `[process-check]` to investigate
- Before load testing -> `[port-map] --expected` to verify targets
