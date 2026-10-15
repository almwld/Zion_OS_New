---
name: fleet-skill-placeholder-cleanup
description: Classify unresolved placeholders across SKILL.md files and emit severity-ranked remediation deltas.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--roots-file PATH] [--roots-json JSON] [--mode pass|needs_edit|blocked|all] [--json] [--strict]"
category: fleet-ops
status: candidate
---
# Fleet Skill Placeholder Cleanup

## Purpose
Produce a deterministic cleanup queue for placeholder usage inside `SKILL.md` assets so remediation can be scoped and prioritized.

## Checks
- Scan each discovered `SKILL.md` and strip code blocks.
- Classify placeholder findings by severity:
  - `blocked` for high-risk unresolved markers.
  - `needs_edit` for non-blocking placeholders that still need replacement.
  - `pass` for clean files.

## Output
- `total`: files scanned
- `pass`: clean files
- `needs_edit`: files with low-risk placeholders
- `blocked`: files with high-risk markers
- `items`: per-file status and findings

## Usage
Run from PowerShell:

```powershell
$python = @'
import argparse
import json
import pathlib
import re


def parse_frontmatter(text: str):
    m = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n", text, flags=re.S)
    if not m:
        return None, text
    fm_raw = m.group(1).splitlines()
    fm = {}
    for line in fm_raw:
        if ":" in line:
            key, value = line.split(":", 1)
            fm[key.strip()] = value.strip().strip('"').strip("'")
    return fm, text[m.end() :]


def parse_roots(raw_roots: str, raw_root_file: str):
    if raw_root_file:
        return json.loads(pathlib.Path(raw_root_file).read_text(encoding="utf-8-sig"))
    if raw_roots:
        return json.loads(raw_roots)
    return [
        {"label": ".agents/skills", "path": str(pathlib.Path.home() / ".agents" / "skills")},
        {"label": ".codex/skills", "path": str(pathlib.Path.home() / ".codex" / "skills")},
        {"label": ".codex/plugins/cache/openai-curated", "path": str(pathlib.Path.home() / ".codex" / "plugins" / "cache" / "openai-curated")},
        {"label": ".codex/plugins/cache/openai-bundled", "path": str(pathlib.Path.home() / ".codex" / "plugins" / "cache" / "openai-bundled")},
        {"label": ".codex/plugins/cache/openai-primary-runtime", "path": str(pathlib.Path.home() / ".codex" / "plugins" / "cache" / "openai-primary-runtime")},
        {"label": ".codex/plugins/cache/claude-plugins-official", "path": str(pathlib.Path.home() / ".codex" / "plugins" / "cache" / "claude-plugins-official")},
    ]


def strip_code(text: str) -> str:
    text = re.sub(r"(?s)```.*?```", " ", text)
    text = re.sub(r"`[^`]*`", " ", text)
    return text.lower()


def classify_findings(body: str):
    candidates = []
    cleaned = strip_code(body or "")
    if re.search(r"\b(todo|tbd|fixme)\b", cleaned):
        candidates.append(("blocked", "high_risk_marker"))
    if re.search(r"path/to/", cleaned):
        candidates.append(("needs_edit", "path_placeholder"))
    if re.search(r"<needs_fill>", cleaned):
        candidates.append(("needs_edit", "needs_fill"))
    if re.search(r"<placeholder>", cleaned):
        candidates.append(("needs_edit", "placeholder_template"))
    return candidates


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--roots-file", default="")
    parser.add_argument("--roots-json", default="")
    parser.add_argument("--mode", default="all", choices=["all", "pass", "needs_edit", "blocked"])
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    roots = parse_roots(args.roots_json, args.roots_file)
    total = pass_count = needs_edit_count = blocked_count = 0
    items = []

    for root_info in roots:
        root = pathlib.Path(root_info.get("path", ""))
        if not root.is_dir():
            continue
        for path in root.rglob("SKILL.md"):
            total += 1
            raw = path.read_text(encoding="utf-8", errors="replace")
            frontmatter, body = parse_frontmatter(raw)
            findings = []
            if frontmatter is None:
                status = "blocked"
                findings.append({"severity": "blocked", "marker": "missing_frontmatter"})
            else:
                findings = [{"severity": s, "marker": m} for s, m in classify_findings(body)]
                if any(item["severity"] == "blocked" for item in findings):
                    status = "blocked"
                elif findings:
                    status = "needs_edit"
                else:
                    status = "pass"

            if status == "pass":
                pass_count += 1
            elif status == "needs_edit":
                needs_edit_count += 1
            else:
                blocked_count += 1

            if args.mode == "all" or status == args.mode:
                items.append({"path": str(path), "status": status, "findings": findings})

    result = {
        "total": total,
        "pass": pass_count,
        "needs_edit": needs_edit_count,
        "blocked": blocked_count,
        "items": items,
    }

    if args.json:
        print(json.dumps(result))
    else:
        print("Fleet Skill Placeholder Cleanup | summary")
        print(f"total={result['total']} pass={result['pass']} needs_edit={result['needs_edit']} blocked={result['blocked']}")
        for item in items:
            status = item["status"]
            details = item["findings"] or []
            marker_line = ", ".join([f"{d['severity']}:{d['marker']}" for d in details]) if details else "clean"
            print(f"{status} {item['path']} {marker_line}")

    if args.strict and blocked_count > 0:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
'@
$python | python -
```

## Suggested Integration
- Run after `fleet-skill-smoke` to turn placeholder debt into prioritized cleanup queue items.
- Export JSON into Intel-Surge for weekly cleanup planning.
