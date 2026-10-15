---
name: fleet-skill-smoke
description: Fast smoke validation for all SKILL.md files across known skill roots, with explicit hard-fail for schema regressions.
version: 0.1.2
execution-mode: advisory
argument-hint: "[--roots ROOT1 ROOT2 ...] [--strict] [--json]"
category: fleet-ops
status: candidate
---
# Fleet Skill Smoke

Run a low-cost smoke check to catch immediate quality regressions before broader mesh operations (`[mesh-sync]`, `[fleet-status]`, or Intel-Surge planning loops).

## When to Use
- Right after adding/updating multiple SKILL.md files
- Before `[mesh-sync]` or cross-machine propagation
- In a long-running Intel-Surge loop between heavy checks
- When bus-backed coordination adds new skill folders from external contributors

## Checkset

For each discovered `SKILL.md`, validate:
1. YAML frontmatter exists with required keys: `name`, `description`, `version`, `execution-mode`.
2. File contains at least one markdown section header (`^# `).
3. The `name` and file path are not placeholders.
4. There are no unresolved marker tokens in prose (`TODO`, `TBD`, `FIXME`, `<NEEDS_FILL>`, `path/to/`).

## Execution

1. Resolve skill roots.
2. Enumerate all `SKILL.md` under `*/SKILL.md`.
3. Apply checks above and emit an aggregate row-per-skill result table.
4. Treat any `FAIL` as hard stop for `[mesh-sync]` in strict mode.
5. In `--json`, emit one compact JSON object suitable for append to `.jsonl` logs.

## Recommended Command (PowerShell)

```powershell
$python = @'
import argparse
import os
import pathlib
import re
import json

parser = argparse.ArgumentParser()
parser.add_argument("--json", action="store_true")
parser.add_argument("--strict", action="store_true")
parser.add_argument(
    "--roots",
    nargs="*",
    default=[
        str(pathlib.Path.home() / ".agents" / "skills"),
        str(pathlib.Path.home() / ".codex" / "skills"),
        str(pathlib.Path.home() / ".codex" / "plugins" / "cache"),
    ],
)
args = parser.parse_args()

def split_roots(raw_roots):
    out = []
    for item in raw_roots:
        for seg in item.split(","):
            seg = seg.strip().strip('"').strip("'")
            if seg:
                out.append(seg)
    return out

def parse_frontmatter(text):
    m = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n", text, flags=re.S)
    if not m:
        return None, text
    fm_raw = m.group(1).splitlines()
    fm = {}
    for line in fm_raw:
        if ":" not in line:
            continue
        k, v = line.split(":", 1)
        fm[k.strip()] = v.strip().strip('"').strip("'")
    return fm, text[m.end():]

required = {"name", "description", "version", "execution-mode"}
placeholder_markers = ("todo", "tbd", "fixme", "<needs_fill>", "path/to/")
warn = fail = ok = total = 0
rows = []

for root in split_roots(args.roots):
    if not os.path.isdir(root):
        continue
    for path in pathlib.Path(root).rglob("SKILL.md"):
        total += 1
        text = path.read_text(encoding="utf-8", errors="replace")
        fm, body = parse_frontmatter(text)
        status = "PASS"
        reasons = []

        if not fm:
            status, reasons = "FAIL", ["missing_frontmatter"]
        else:
            missing = sorted(required - set(fm))
            if missing:
                status, reasons = "FAIL", ["missing_fields:" + ",".join(missing)]
            elif (not re.search(r"^# ", body, re.M)) or not body.strip():
                status, reasons = "FAIL", ["missing_markdown_heading"]

        body_text = re.sub(r"(?s)```.*?```", "", body or "").lower()
        if status == "PASS" and any(marker in body_text for marker in placeholder_markers):
            status, reasons = "WARN", ["placeholder_reference"]

        if status == "PASS":
            ok += 1
        elif status == "WARN":
            warn += 1
        else:
            fail += 1
        rows.append({"path": str(path), "status": status, "reasons": reasons})

result = {"total": total, "pass": ok, "warn": warn, "fail": fail, "rows": rows}
if args.json:
    print(json.dumps(result))
else:
    print(f"Fleet skill smoke: total={total} pass={ok} warn={warn} fail={fail}")
    if args.strict:
        for row in rows:
            tag = row["status"]
            print(f"{tag} {row['path']} {';'.join(row['reasons'])}")

raise SystemExit(1 if fail > 0 else 0)
'@
$python | python -
```

## Output Format
```
Fleet Skill Smoke | <mode>

total=657 pass=... warn=... fail=...

- FAIL: <path> | <reason_code>
- WARN: <path> | <reason_code>
- PASS: <path>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| `[fleet-skill-drift]` | Turn fail/warn deltas into a time-series for Intel-Surge remediation |
| `[skill-audit]` | Pre-sync risk audit before fleet propagation |
| `[fleet-status]` | Validate path availability and sync reach before broad rollout |
