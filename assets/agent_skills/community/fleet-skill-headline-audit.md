---
name: fleet-skill-headline-audit
description: Audit SKILL.md readability signals and detect heading drift for fleet-wide quality.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--roots-file PATH] [--roots-json JSON] [--include-no-heading] [--strict] [--json]"
category: fleet-ops
status: candidate
---
# Fleet Skill Headline Audit

## Purpose
Provide a deterministic audit of heading quality in `SKILL.md` files so missing titles and duplicate top headings are surfaced before sync and propagation.

## Checks
- Scan each discovered `SKILL.md` and strip frontmatter.
- Confirm each body has at least one level-one heading in strict mode.
- Flag duplicate level-one headings within the same file.
- Flag empty files.
- Classify severity as pass, needs edit, or blocked.

## Output
- `total`: files scanned
- `pass`: clean files
- `needs_edit`: files with recoverable heading issues
- `blocked`: files with strict heading violations
- `items`: per-file status and reasons

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


def parse_headings(body: str):
    headings = []
    for line in (body or "").splitlines():
        if line.startswith("# "):
            headings.append(line.strip())
    return headings


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--roots-file", default="")
    parser.add_argument("--roots-json", default="")
    parser.add_argument("--include-no-heading", action="store_true")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    roots = parse_roots(args.roots_json, args.roots_file)
    total = pass_count = needs_edit_count = blocked_count = 0
    entries = []

    for root_info in roots:
        root = pathlib.Path(root_info.get("path", ""))
        if not root.is_dir():
            continue
        for path in root.rglob("SKILL.md"):
            total += 1
            text = path.read_text(encoding="utf-8", errors="replace")
            fm, body = parse_frontmatter(text)
            findings = []
            if fm is None:
                status = "blocked"
                findings.append("missing_frontmatter")
            else:
                headings = parse_headings(body)
                if args.include_no_heading and not headings:
                    findings.append("no_heading")
                if args.strict and not headings:
                    findings.append("missing_top_level_heading")
                if any(headings.count(item) > 1 for item in headings):
                    findings.append("duplicate_level_one")
                if not findings:
                    status = "pass"
                else:
                    status = "needs_edit" if not args.strict else "blocked"
            if status == "pass":
                pass_count += 1
            elif status == "needs_edit":
                needs_edit_count += 1
            else:
                blocked_count += 1
            if findings:
                entries.append({"path": str(path), "status": status, "findings": findings})

    result = {
        "total": total,
        "pass": pass_count,
        "needs_edit": needs_edit_count,
        "blocked": blocked_count,
        "items": entries,
    }

    if args.json:
        print(json.dumps(result))
    else:
        print("Fleet Skill Headline Audit | strict={}".format(args.strict))
        print("total={} pass={} needs_edit={} blocked={}".format(result["total"], result["pass"], result["needs_edit"], result["blocked"]))
        for item in entries:
            print(f"{item['status']}: {item['path']} | {';'.join(item['findings'])}")

    if args.strict and blocked_count > 0:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
'@
$python | python -
```

## Suggested Integration
- Run before `[fleet-skill-drift]` in release-safe windows.
- Keep default non-strict mode if you are validating external contributions with broad placeholders.
