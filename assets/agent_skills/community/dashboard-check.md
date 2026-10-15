---
name: dashboard-check
description: Verify dashboard API + frontend health, SSE streaming, and data freshness
version: 0.1.0
execution-mode: advisory
argument-hint: "[--start] [--api-only] [--frontend-only]"
category: dev-tools
status: candidate
---
# [dashboard-check]

## When to Use
- After deploying dashboard changes
- Debugging dashboard connectivity issues
- Before demos or presentations
- Daily health check of the Mission Control dashboard
- After infrastructure changes (port conflicts, process restarts)

## Execution

### 1. Process Check
```bash
# Check if API server is running (port 8000)
lsof -i :8000 2>/dev/null || echo "Port 8000: not in use"
# Check if frontend is running (port 3000)
lsof -i :3000 2>/dev/null || echo "Port 3000: not in use"
# Check for dashboard processes
ps aux | grep -E "uvicorn|next|node" | grep -v grep | head -5
```

### 2. API Health (unless --frontend-only)
```bash
# API ping
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "API unreachable"
# API endpoints
curl -s http://localhost:8000/api/health 2>/dev/null | python3 -m json.tool 2>/dev/null | head -20
# SSE stream test (3 second sample)
timeout 3 curl -s -N http://localhost:8000/api/bus/stream 2>/dev/null | head -5 || echo "SSE not streaming"
# Agent fleet endpoint
curl -s http://localhost:8000/api/agents 2>/dev/null | python3 -m json.tool 2>/dev/null | head -15
# Kill switch status
curl -s http://localhost:8000/api/kill-switch 2>/dev/null | python3 -m json.tool 2>/dev/null | head -10
```

### 3. Frontend Health (unless --api-only)
```bash
# Frontend response
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null || echo "Frontend unreachable"
# Check build artifacts exist
ls dashboard/web/.next/ 2>/dev/null && echo "Next.js build exists" || echo "No build found"
# Check node_modules
ls dashboard/web/node_modules/ 2>/dev/null | wc -l
# Package.json scripts
grep -A10 '"scripts"' dashboard/web/package.json 2>/dev/null | head -12
```

### 4. Data Freshness
```bash
# Latest bus message timestamp
tail -1 _state/coordination/messages.tsv 2>/dev/null | cut -f1
# Latest briefing
ls -lt state/briefings/ 2>/dev/null | head -3
# Latest governance event
tail -1 _state/governance/audit.jsonl 2>/dev/null | python3 -m json.tool 2>/dev/null | head -5
# Health probe last check
grep -r "last_check\|timestamp" services/health.py | head -5
```

### 5. Start Services (if --start)
```bash
cd dashboard/
# Start API
python -m uvicorn api.main:app --host 0.0.0.0 --port 8000 &
# Start frontend
cd web && npm run dev &
```

## Output Format

```
Dashboard Check | <date>
============================================

Services
--------
  API (port 8000):       [UP] PID 12345, uvicorn, 2.1GB RSS
  Frontend (port 3000):  [UP] PID 12346, next-server, 180MB RSS
  SSE Stream:            [UP] streaming, 1 event/2.3s avg

API Endpoints
-------------
  [health]           200  [OK]   12ms
  /api/health       200  [OK]   45ms   7/7 adapters reporting
  /api/agents       200  [OK]   23ms   4 agents in fleet
  /api/kill-switch  200  [OK]   8ms    mode: DISENGAGED
  /api/bus/stream   200  [OK]   SSE connected, 3 events in 3s sample

Frontend
--------
  Home page:    200  [OK]
  Build:        .next/ exists (last build: 2h ago)
  Dependencies: 847 packages installed

Data Freshness
--------------
  Bus:          last message 4m ago     [FRESH]
  Briefing:     2026-03-25              [FRESH]
  Governance:   last event 12m ago      [FRESH]
  Health:       probes running          [FRESH]

Issues
------
  [NONE] All checks passed

  -- or --

  [WARN] SSE stream: no events in 3s sample (bus may be quiet)
  [ERR]  Frontend: .next/ build is 3 days old, consider rebuild

Next action: <recommendation>
```

## Skill Chains
- After `[dashboard-check]` with failures -> `[health]` for deeper service diagnostics
- After `[dashboard-check] --start` -> `[dashboard-check]` again to verify
- After `[dashboard-check]` -> `[process-check]` if unexpected port conflicts
