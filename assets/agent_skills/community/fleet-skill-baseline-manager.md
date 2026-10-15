---
name: fleet-skill-baseline-manager
description: Manage all-skills baseline snapshots with deterministic diff summaries and controlled updates.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--snapshot PATH] [--roots-file PATH] [--roots-json JSON] [--mode show|status|init|refresh] [--max-removed N] [--force] [--strict] [--json]"
category: fleet-ops
status: candidate
---
# Fleet Skill Baseline Manager

## Purpose
Create and maintain the all-skills baseline with strict, repeatable behavior for drift visibility.

## Checks
- Build canonical inventory from discovered `SKILL.md` files.
- Compare to a baseline snapshot and compute `added`, `removed`, and `modified`.
- Provide gated update actions:
  - `init` creates baseline once (or with `--force`).
  - `refresh` overwrites baseline with a full live snapshot.
  - `show` and `status` only report without writing.

## Output
- `total` live inventory size
- `baseline_total`
- `added`, `removed`, `modified`
- `template_removed` list
- `blocked` boolean (when thresholds are exceeded under strict mode)

## Usage
Run from PowerShell:

```powershell
$python = @'
import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path


def _normalize_root_defs(raw):
    if raw is None:
        return []
    if isinstance(raw, dict):
        return [raw]
    if isinstance(raw, list):
        return raw
    return []


def parse_root_defs(raw_roots: str, raw_root_file: str):
    if raw_root_file:
        payload = Path(raw_root_file).read_text(encoding="utf-8-sig")
        return _normalize_root_defs(json.loads(payload))
    if raw_roots:
        return _normalize_root_defs(json.loads(raw_roots))
    return [
        {"label": ".agents/skills", "path": str(Path.home() / ".agents" / "skills")},
        {"label": ".codex/skills", "path": str(Path.home() / ".codex" / "skills")},
        {"label": ".codex/plugins/cache/openai-curated", "path": str(Path.home() / ".codex" / "plugins" / "cache" / "openai-curated")},
        {"label": ".codex/plugins/cache/openai-bundled", "path": str(Path.home() / ".codex" / "plugins" / "cache" / "openai-bundled")},
        {"label": ".codex/plugins/cache/openai-primary-runtime", "path": str(Path.home() / ".codex" / "plugins" / "cache" / "openai-primary-runtime")},
        {"label": ".codex/plugins/cache/claude-plugins-official", "path": str(Path.home() / ".codex" / "plugins" / "cache" / "claude-plugins-official")},
    ]


def _file_signature(path: Path) -> dict[str, object]:
    data = path.read_bytes()
    h = hashlib.sha256(data).hexdigest()
    return {"hash": h, "size": len(data)}


def build_inventory(roots: list[dict[str, str]]) -> dict[str, dict[str, object]]:
    current: dict[str, dict[str, object]] = {}
    root_pairs = [(Path(r["path"]).resolve(), r.get("label") or Path(r["path"]).name) for r in roots]
    for root, label in root_pairs:
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("SKILL.md")):
            rel_path = str(path)
            try:
                rel = path.resolve().relative_to(root)
                rel_path = f"{label}/{rel.as_posix()}"
            except ValueError:
                pass
            current[rel_path] = {
                "path": rel_path,
                "abs_path": str(path),
                "label": label,
                **_file_signature(path),
            }
    return current


def load_baseline(snapshot: Path) -> dict[str, dict[str, object]]:
    if not snapshot.exists():
        return {}
    try:
        payload = json.loads(snapshot.read_text(encoding="utf-8"))
        skills = payload.get("skills", {})
        if isinstance(skills, dict):
            return skills
    except (OSError, json.JSONDecodeError):
        return {}
    return {}


def write_snapshot(snapshot: Path, current: dict[str, dict[str, object]], mode: str):
    payload = {
        "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "mode": mode,
        "skills": current,
    }
    snapshot.parent.mkdir(parents=True, exist_ok=True)
    snapshot.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--snapshot", default=str(Path.home() / "_internal" / "fleet" / "all-skills-test" / "skill-inventory-baseline.json"))
    parser.add_argument("--roots-file", default="")
    parser.add_argument("--roots-json", default="")
    parser.add_argument("--mode", default="show", choices=["show", "status", "init", "refresh"])
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--max-removed", type=int, default=3)
    parser.add_argument("--max-template-removed", type=int, default=0)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    roots = parse_root_defs(args.roots_json, args.roots_file)
    snapshot = Path(args.snapshot)
    current = build_inventory(roots)
    baseline = load_baseline(snapshot)

    current_keys = set(current)
    baseline_keys = set(baseline)
    added = sorted(current_keys - baseline_keys)
    removed = sorted(baseline_keys - current_keys)
    modified = sorted([k for k in (current_keys & baseline_keys) if current[k]["hash"] != baseline[k].get("hash") or current[k]["size"] != baseline[k].get("size")])
    template_removed = [entry for entry in removed if "template" in entry.lower() or "placeholder" in entry.lower()]

    result = {
        "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "mode": args.mode,
        "snapshot": str(snapshot),
        "baseline_total": len(baseline),
        "current_total": len(current),
        "added": added,
        "removed": removed,
        "modified": modified,
        "template_removed": template_removed,
        "strict_profile": {
            "max_removed": args.max_removed,
            "max_template_removed": args.max_template_removed,
        },
    }

    if args.mode in {"init", "refresh"}:
        if args.mode == "init" and snapshot.exists() and not args.force:
            result["status"] = "blocked"
            result["reason"] = "snapshot_exists_use_refresh_or_force"
            print(json.dumps(result))
            raise SystemExit(2)
        write_snapshot(snapshot, current, args.mode)
        result["status"] = "updated"
        result["baseline_total"] = len(current)
        result["added"] = []
        result["removed"] = []
        result["modified"] = []
        result["template_removed"] = []
        print(json.dumps(result))
        return

    blocked = False
    if args.strict:
        if len(removed) > args.max_removed:
            blocked = True
        if len(template_removed) > args.max_template_removed:
            blocked = True

    result["status"] = "blocked" if blocked else "ok"
    result["blocked"] = blocked
    print(json.dumps(result))
    if args.strict and blocked:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
'@
$python | python -
```

## Suggested Integration
- Pair with `fleet-skill-drift` for quick baseline sanity checks before long loops.
- Use `--mode init` to bootstrap a clean snapshot from a known-good run.
- Use `--mode refresh` only from a controlled operator lane (non-watch automation).
