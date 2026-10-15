---
name: fleet-skill-health-pulse
description: Emit a compact fleet-health signal combining smoke, drift, and bus-lane activity.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--report PATH] [--bus-tsv PATH] [--bus-lines 20] [--json] [--strict]"
category: fleet-ops
status: candidate
---
# Fleet Skill Health Pulse

## Purpose
Create a lightweight readiness scorecard from loop output so fleet regression pressure is visible before routing work.

## Checks
- Parse the latest all-skills report for smoke pass/warn/fail totals.
- Parse drift deltas for inventory churn.
- Optional bus tail sampling for operational context.
- Derive a health score and health status.

## Output
- `health_score` (0-100)
- `status` (`PASS`, `WARN`, `FAIL`, `UNKNOWN`)
- Drift pressure and bus signal summary
- `alerts` list for routing/triage

## Usage
Run from PowerShell:

```powershell
$python = @'
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


def _to_status_int(raw: str) -> int:
    return {"PASS": 0, "WARN": 1, "FAIL": 2, "UNKNOWN": 3}.get(str(raw or "UNKNOWN").upper(), 3)


def _safe_load(path: Path):
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def _parse_bus(path: str | None, max_lines: int):
    if not path:
        return []
    p = Path(path)
    if not p.exists():
        return []
    try:
        lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return []
    tail = lines[-max_lines:] if max_lines > 0 else lines
    events = []
    for raw in tail:
        parts = raw.split("\t")
        if len(parts) < 5:
            continue
        events.append({
            "ts": parts[0],
            "from": parts[1],
            "to": parts[2],
            "type": parts[3],
            "message": "\t".join(parts[4:]),
        })
    return events


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", default=str(Path.home() / "_internal" / "fleet" / "all-skills-test" / "all-skills-test-report-latest.json"))
    parser.add_argument("--bus-tsv", default="")
    parser.add_argument("--bus-lines", type=int, default=20)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    report = _safe_load(Path(args.report))
    if not report:
        status = "UNKNOWN"
        totals = {"total": 0, "pass": 0, "warn": 0, "fail": 0}
        latest = None
        cycles = []
    else:
        cycles = report.get("cycles", []) or []
        latest = cycles[-1] if cycles else None
        status = str(report.get("status", "UNKNOWN")).upper()
        smoke = latest.get("smoke_totals", {}) if latest else {}
        totals = {
            "total": int(smoke.get("total", report.get("totals", {}).get("total", 0))),
            "pass": int(smoke.get("pass", report.get("totals", {}).get("pass", 0))),
            "warn": int(smoke.get("warn", report.get("totals", {}).get("warn", 0))),
            "fail": int(smoke.get("fail", report.get("totals", {}).get("fail", 0))),
        }

    total = max(totals["total"], 0)
    raw_ratio = (totals["pass"] / total) if total > 0 else 1.0
    fail_penalty = min(40, totals["fail"] * 25)
    warn_penalty = min(20, totals["warn"] * 5)
    health_score = max(0, int((raw_ratio * 100) - fail_penalty - warn_penalty))
    if status == "FAIL" or totals["fail"] > 0:
        status = "FAIL"
    elif totals["warn"] > 0:
        status = "WARN"
    elif health_score >= 95:
        status = "PASS"
    else:
        status = "WARN"

    drift = latest.get("drift", {}) if latest else {}
    alerts = []
    if status == "FAIL":
        alerts.append("blocker:smoke_failures")
    elif totals["warn"] > 10:
        alerts.append("risk:high_warn_volume")
    if drift.get("removed", 0) > 0:
        alerts.append("risk:skill_removals_detected")
    if drift.get("modified", 0) > 100:
        alerts.append("risk:high_drift_volume")

    bus_events = _parse_bus(args.bus_tsv, args.bus_lines) if args.bus_tsv else []
    bus_statuses = [evt["type"] for evt in bus_events]

    pulse = {
        "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "status": status,
        "health_score": health_score,
        "iterations": len(cycles),
        "totals": totals,
        "drift": {
            "added": drift.get("added", 0),
            "removed": drift.get("removed", 0),
            "modified": drift.get("modified", 0),
            "template_removed": drift.get("template_removed", 0),
        },
        "alerts": alerts,
        "bus_tail": {
            "count": len(bus_events),
            "status_types": bus_statuses,
            "events": bus_events[:3],
        },
        "latest_cycle": latest.get("iteration") if latest else None,
    }

    if args.json:
        print(json.dumps(pulse))
    else:
        print("Fleet Health Pulse")
        print(f"status={pulse['status']} health_score={pulse['health_score']} iterations={pulse['iterations']}")
        print(f"totals={pulse['totals']}")
        print(f"drift={pulse['drift']}")
        if alerts:
            print("alerts=" + ",".join(alerts))
        if bus_events:
            print("bus_tail_type_sample=" + ",".join(bus_statuses[-3:]))

    if args.strict and (status == "FAIL" or health_score < 95):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
'@
$python | python -
```

## Suggested Integration
- Run after any all-skills cycle in `fleet-skills-crab-loop.ps1`.
- Feed `--json` output into `fleet-skill-intel-surge-router` or operator handoff docs.
