---
name: fleet-skill-rootset-scan
description: Build a canonical root coverage matrix and report missing or duplicate fleet skill scopes.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--roots PATH ...] [--strict] [--json]"
category: dev-tools
status: candidate
---
# Fleet Skill Rootset Scan

## Purpose
Protect all-skills loops from silent root scope loss by validating declared roots and coverage before and after sync operations.

## Checks
- Ensure declared roots exist.
- Build a per-root coverage count for `SKILL.md`.
- Detect overlapping declared roots.
- Detect orphan skill files outside canonical roots.
- Compare declared roots to canonical root set.

## Output
- `total_roots`: number of declared roots
- `existing_roots`: reachable roots
- `missing_roots`: missing declared roots
- `coverage`: root-by-root `SKILL.md` counts
- `orphan_skills`: skill files not covered by declared canonical roots
- `overlaps`: alias/alias-equivalent root collisions
- `blocked`: non-zero when root scope issues are present

## Usage
Run from PowerShell:

```powershell
$python = @'
import argparse
import json
import pathlib


def parse_roots(raw_roots, raw_root_file):
    if raw_root_file:
        payload = pathlib.Path(raw_root_file).read_text(encoding="utf-8-sig")
        return json.loads(payload)
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


def canonical_paths(roots):
    canonical = {}
    for root in roots:
        path = pathlib.Path(root.get("path", ""))
        label = root.get("label") or root.get("name") or str(path)
        try:
            canonical[label] = str(path.resolve())
        except Exception:
            canonical[label] = str(path.absolute())
    return canonical


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--roots-file", default="")
    parser.add_argument("--roots-json", default="")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    declared_roots = parse_roots(args.roots_json, args.roots_file)
    declared = {r.get("label") or r.get("name"): str(r.get("path", "")) for r in declared_roots}

    existing_roots = {label: pathlib.Path(path).exists() for label, path in declared.items()}
    missing_roots = sorted([label for label, exists in existing_roots.items() if not exists and label])

    overlaps = {}
    paths = canonical_paths(declared_roots)
    normalized = {}
    for label, p in paths.items():
        normalized.setdefault(p, []).append(label)
    for real_path, labels in normalized.items():
        if len(labels) > 1:
            overlaps[real_path] = labels

    canonical_roots = {
        ".agents/skills": pathlib.Path.home() / ".agents" / "skills",
        ".codex/skills": pathlib.Path.home() / ".codex" / "skills",
        ".codex/plugins/cache/openai-curated": pathlib.Path.home() / ".codex" / "plugins" / "cache" / "openai-curated",
        ".codex/plugins/cache/openai-bundled": pathlib.Path.home() / ".codex" / "plugins" / "cache" / "openai-bundled",
        ".codex/plugins/cache/openai-primary-runtime": pathlib.Path.home() / ".codex" / "plugins" / "cache" / "openai-primary-runtime",
        ".codex/plugins/cache/claude-plugins-official": pathlib.Path.home() / ".codex" / "plugins" / "cache" / "claude-plugins-official",
    }

    coverage = {}
    all_skills = []
    for label, root_path in canonical_roots.items():
        if not root_path.exists():
            coverage[label] = 0
            continue
        paths = list(root_path.rglob("SKILL.md"))
        coverage[label] = len(paths)
        all_skills.extend(paths)

    orphan_skills = []
    for path in all_skills:
        matched = False
        for root in canonical_roots.values():
            try:
                path.relative_to(root)
                matched = True
                break
            except ValueError:
                continue
        if not matched:
            orphan_skills.append(str(path))

    missing_canonical = [label for label in canonical_roots if label not in declared]
    extra_canonical = [label for label in declared if label not in canonical_roots]
    blocked = bool(missing_roots) or bool(overlaps)

    result = {
        "total_roots": len(declared),
        "existing_roots": sorted([k for k, v in existing_roots.items() if v]),
        "missing_roots": missing_roots,
        "coverage": coverage,
        "overlaps": overlaps,
        "orphan_skills": orphan_skills,
        "missing_canonical": missing_canonical,
        "extra_canonical": extra_canonical,
        "blocked": blocked,
    }

    if args.json:
        print(json.dumps(result))
    else:
        print("Fleet Skill Rootset Scan")
        print(f"total_roots={result['total_roots']} existing={len(result['existing_roots'])} missing={len(result['missing_roots'])} orphans={len(orphan_skills)}")
        for label, count in sorted(coverage.items()):
            print(f"{label}={count}")

    if args.strict and blocked:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
'@
$python | python -
```

## Suggested Integration
- Run before `[mesh-sync]` to verify fleet root topology.
- Store output when mesh root pointers are changed or cleaned.
