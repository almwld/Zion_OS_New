---
name: pypi-publish
description: Publish Python package to PyPI with version bump, changelog, and git tag.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<package-dir> [--bump major|minor|patch] [--dry-run]"
category: dev-tools
status: candidate
---
# PyPI Publish

Standardized publish workflow for Python packages.

## When to Use
- Releasing a new version of your package
- Publishing any new Python package
- After merging significant features

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=pypi-publish] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. **Pre-checks**:
   - Clean git tree (no uncommitted changes)
   - All tests passing (`python -m pytest`)
   - No third-party runtime deps (`[dep-check]`)
   - On main branch
2. **Version bump**: Update `pyproject.toml` version field
3. **Changelog**: Generate via `[changelog]` for the version
4. **Build**: `python -m build`
5. **Test upload**: `twine upload --repository testpypi dist/*` (if --dry-run)
6. **Upload**: `twine upload dist/*`
7. **Tag**: `git tag v<version>` and push
8. **Verify**: `pip install <package>==<version>` in clean venv

## Output Format

```
PyPI Publish | <package> v<version>
====================================
Pre-checks: PASS
Build: OK (sdist + wheel)
Upload: SUCCESS
Tag: v<version> pushed
Verify: pip install OK
```

## Skill Chains

### Mandatory (MUST pass before publish)

- **`[dep-check]`** MUST pass — zero third-party runtime deps verified
- **`[test-run]`** MUST be green — all tests passing
- **`[security-scan]`** MUST be clean — zero HIGH/CRITICAL findings

### Advisory

- **After publish**: `[release-notes]`, `[send-email]` (with `[content-review]` passed)
- **Version tag**: `[tag-release]`

## Authority

- **T1 (TRUSTED)**: May publish with all mandatory chains passed
- **T2 (Active/High)**: MUST get operator approval AND all mandatory chains passed
- **T3 (Medium)**: MUST get operator approval AND all mandatory chains passed
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
- **Operator**: Override any restriction — PyPI publish is irreversible

## Operator Approval Gate

PyPI publish is irreversible (cannot unpublish a version). The operator MUST
explicitly approve before `twine upload` runs, even if all mandatory chains pass.
The only exception is `--dry-run` mode (test PyPI upload).
