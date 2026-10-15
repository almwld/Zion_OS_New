#!/usr/bin/env python3
"""Vendor the complete HUMMBL Agent Skills corpus for Zion's offline runtime.

The upstream skill files are treated as untrusted documentation. This script
never executes a skill or any file from the upstream repository.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets" / "agent_skills"
FLAT = DEST / "community"
CATALOG = DEST / "community_catalog.json"
BUNDLE = DEST / "community_bundle.zip"
UPSTREAM = "https://github.com/hummbl-io/agent-skills.git"
MIN_SKILLS = 1000  # Fail closed if the upstream corpus is unexpectedly truncated.


def run(*args: str, cwd: Path | None = None) -> str:
    return subprocess.check_output(args, cwd=cwd, text=True, stderr=subprocess.STDOUT).strip()


def frontmatter(text: str) -> dict[str, str]:
    match = re.match(r"^---\s*\n(.*?)\n---\s*(?:\n|$)", text, re.S)
    values: dict[str, str] = {}
    if not match:
        return values
    for line in match.group(1).splitlines():
        item = re.match(r"^([A-Za-z0-9_-]+):\s*(.*?)\s*$", line)
        if item:
            values[item.group(1).lower()] = item.group(2).strip().strip('"').strip("'")
    return values


def read_readme_licenses(readme: str) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    for line in readme.splitlines():
        if not line.startswith("|") or line.startswith("|---") or ("license" in line.lower() and "description" in line.lower()):
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) < 4:
            continue
        name_match = re.search(r"`([^/ `]+)`", cells[0])
        if not name_match:
            continue
        result[name_match.group(1)] = {
            "author": cells[1],
            "license": cells[2],
            "description": cells[3],
        }
    return result


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    FLAT.mkdir(parents=True, exist_ok=True)
    for existing in FLAT.glob("*.md"):
        existing.unlink()
    with tempfile.TemporaryDirectory(prefix="zion-agent-skills-") as temp:
        source = Path(temp) / "upstream"
        run("git", "clone", "--depth=1", UPSTREAM, str(source))
        upstream_sha = run("git", "rev-parse", "HEAD", cwd=source)
        skills_root = source / "skills"
        if not skills_root.is_dir():
            raise SystemExit("Upstream repository has no skills/ directory")

        skill_files = sorted(path for path in skills_root.rglob("SKILL.md") if path.is_file() and not path.is_symlink())
        if len(skill_files) < MIN_SKILLS:
            raise SystemExit(f"Refusing incomplete corpus: found {len(skill_files)} skills, expected at least {MIN_SKILLS}")

        readme = (source / "README.md").read_text(encoding="utf-8", errors="replace")
        attribution_path = source / "ATTRIBUTION.md"
        attribution = attribution_path.read_text(encoding="utf-8", errors="replace") if attribution_path.exists() else ""
        license_map = read_readme_licenses(readme)
        entries: list[dict[str, str]] = []
        names: set[str] = set()
        flat_names: set[str] = set()
        staged = Path(temp) / "bundle"
        staged.mkdir()

        for skill_path in skill_files:
            raw = skill_path.read_text(encoding="utf-8", errors="replace")
            meta = frontmatter(raw)
            name = meta.get("name") or skill_path.parent.name
            slug = re.sub(r"[^a-z0-9._-]+", "-", name.lower()).strip("-.")
            if not slug or slug in names:
                raise SystemExit(f"Invalid or duplicate skill name: {name!r} ({skill_path})")
            names.add(slug)
            description = meta.get("description") or license_map.get(skill_path.parent.name, {}).get("description", "")
            if not description:
                description = f"Upstream Agent Skill: {name}"
            license_info = license_map.get(skill_path.parent.name, {})
            license_name = meta.get("license") or license_info.get("license") or "See upstream LICENSE and ATTRIBUTION.md"
            flat_file = f"{slug}.md"
            if flat_file in flat_names:
                raise SystemExit(f"Flat asset name collision: {flat_file}")
            flat_names.add(flat_file)
            flat_path = FLAT / flat_file
            flat_path.write_text(raw, encoding="utf-8")
            entries.append({
                "name": slug,
                "display_name": name,
                "description": description[:500],
                "license": license_name,
                "author": license_info.get("author", "See upstream ATTRIBUTION.md"),
                "source": f"https://github.com/hummbl-io/agent-skills/blob/{upstream_sha}/skills/{skill_path.relative_to(skills_root).as_posix()}",
                "asset": f"assets/agent_skills/community/{flat_file}",
                "keywords": " ".join(re.findall(r"[a-zA-Z0-9_+-]+|[\u0600-\u06ff]+", f"{name} {description}")).lower(),
                "upstream_path": skill_path.relative_to(source).as_posix(),
            })

        # Preserve every upstream skill file, reference, script, asset, license,
        # and attribution document in one offline archive. Nothing in this ZIP
        # is executed by the app.
        for relative_root in (Path("skills"),):
            root = source / relative_root
            for current, dirs, files in os.walk(root, followlinks=False):
                current_path = Path(current)
                dirs[:] = [directory for directory in dirs if not (current_path / directory).is_symlink()]
                for filename in files:
                    file_path = current_path / filename
                    if file_path.is_symlink() or not file_path.is_file():
                        continue
                    relative = file_path.relative_to(source)
                    target = staged / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(file_path, target)
        for filename in ("README.md", "LICENSE", "ATTRIBUTION.md"):
            source_file = source / filename
            if source_file.is_file():
                shutil.copyfile(source_file, staged / filename)

        if len(entries) != len(names) or len(entries) < MIN_SKILLS:
            raise SystemExit("Catalog count/uniqueness validation failed")
        entries.sort(key=lambda entry: entry["name"])
        CATALOG.write_text(json.dumps({
            "schema_version": 1,
            "upstream_repository": "hummbl-io/agent-skills",
            "upstream_commit": upstream_sha,
            "skill_count": len(entries),
            "full_source_bundle": "assets/agent_skills/community_bundle.zip",
            "entries": entries,
        }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        with zipfile.ZipFile(BUNDLE, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for path in sorted(staged.rglob("*")):
                if path.is_file():
                    archive.write(path, path.relative_to(staged).as_posix())

        # Emit the exact commit used for provenance and CI logs.
        print(f"Vendored {len(entries)} skills from hummbl-io/agent-skills@{upstream_sha}")
        print(f"Catalog: {CATALOG.relative_to(ROOT)}")
        print(f"Full offline source bundle: {BUNDLE.relative_to(ROOT)} ({BUNDLE.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
