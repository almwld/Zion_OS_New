---
name: fleet-skill-intel-surge-router
description: Convert all-skills findings into low-friction routing actions for Intel-Surge/triage.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--report PATH] [--output PATH] [--as-json] [--strict] [--allow-high]"
category: fleet-ops
status: candidate
---
# Fleet Skill Intel Surge Router

## Purpose
Turn loop artifacts into explicit routing actions so cleanup and cleanup-ownership lanes can be assigned without manual triage.

## Checks
- Read latest cycle non-pass entries from report.
- Convert status clusters into routed action tuples.
- Emit lane, priority, and action hints for operator intake.

## Output
- `status` aggregate
- `routes`: actionable cleanup clusters
- `items`: non-pass items with grouped owner recommendations

## Usage
Run from PowerShell:

```powershell
$python = @'
import argparse
import json
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", default=str(Path.home() / "_internal" / "fleet" / "all-skills-test" / "all-skills-test-report-latest.json"))
    parser.add_argument("--output", default="")
    parser.add_argument("--as-json", dest="as_json", action="store_true")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--allow-high", action="store_true")
    args = parser.parse_args()

    path = Path(args.report)
    if not path.exists():
        raise SystemExit(f"missing report path: {path}")

    payload = json.loads(path.read_text(encoding="utf-8"))
    cycles = payload.get("cycles", [])
    if not cycles:
        raise SystemExit("no cycles in report")

    latest = cycles[-1]
    cycle_smoke = latest.get("smoke_totals", {})
    cycle_non_pass = latest.get("non_pass") if isinstance(latest.get("non_pass"), list) else []

    grouped = defaultdict(list)
    for item in cycle_non_pass:
        grp = item.get("group", "unknown")
        status = str(item.get("status", "UNKNOWN"))
        grouped[(grp, status)].append(item)

    routes = []
    items = []
    for (grp, status), entries in sorted(grouped.items(), key=lambda kv: kv[0][0]):
        count = len(entries)
        if status == "FAIL":
            lane = "fleet/cleanup-blocking"
            priority = "P1"
        elif status == "WARN":
            lane = "fleet/cleanup-soft"
            priority = "P2"
        else:
            lane = "fleet/cleanup-unknown"
            priority = "P3"
        routes.append({
            "lane": lane,
            "priority": priority,
            "group": grp,
            "count": count,
            "status": status,
            "summary": f"{count} {status} findings in {grp}",
        })
        for entry in entries:
            items.append({
                "path": entry.get("path"),
                "group": grp,
                "status": status,
                "checks": entry.get("checks", []),
            })

    drift = latest.get("drift", {})
    if isinstance(drift, dict):
        if drift.get("added", 0) > 0:
            routes.append({
                "lane": "fleet/fleet-growth-review",
                "priority": "P2",
                "group": "drift",
                "count": drift.get("added", 0),
                "status": "WARN",
                "summary": f"{drift.get('added', 0)} added skills this cycle",
            })
        if drift.get("removed", 0) > 0:
            routes.append({
                "lane": "fleet/fleet-drift-ops",
                "priority": "P1",
                "group": "drift",
                "count": drift.get("removed", 0),
                "status": "FAIL",
                "summary": f"{drift.get('removed', 0)} skills removed from inventory",
            })

    status = "PASS"
    if any(item["status"] == "FAIL" for item in items):
        status = "FAIL"
    elif any(item["status"] == "WARN" for item in items):
        status = "WARN"

    result = {
        "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "source_report": str(path),
        "iteration": latest.get("iteration"),
        "status": status,
        "totals": latest.get("smoke_totals", {}),
        "routes": routes,
        "items": items,
    }

    if args.output:
        Path(args.output).write_text(json.dumps(result, indent=2), encoding="utf-8")
    if args.as_json:
        print(json.dumps(result))
    else:
        print("Intel Surge Router")
        print(f"status={result['status']} iteration={result['iteration']} routes={len(routes)} items={len(items)}")
        for route in routes[:12]:
            print(f"{route['priority']} {route['lane']} group={route['group']} count={route['count']} summary={route['summary']}")

    high_count = len([route for route in routes if route["priority"] == "P1"])
    if args.strict and (status == "FAIL" or (high_count > 0 and not args.allow_high)):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
'@
$python | python -
```

## Suggested Integration
- Run after `fleet-skill-health-pulse` and attach `routes` to Intel-Surge packets.
- Keep `--as-json` output in `$env:USERPROFILE\_internal\fleet\all-skills-test\intel-surge-route-latest.json` for downstream handoff.
