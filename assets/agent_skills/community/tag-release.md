---
name: tag-release
description: Create SemVer git tag with release notes and contract baseline validation.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<version> [--baseline fm-contracts-vX.Y]"
category: backend-infra
status: candidate
---
# Tag Release

Create a versioned release tag with validation against frozen contract baselines.

## When to Use
- Cutting a new release of hummbl-governance or your-package
- After a sprint milestone
- Before PyPI publish

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=tag-release] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. **Version format**: Validate SemVer (X.Y.Z)
2. **Contract check**: Verify current schemas match frozen baseline tag
3. **Breaking change scan**: If major bump, confirm breaking changes documented
4. **Generate notes**: `[changelog]` from last tag to HEAD
5. **Create tag**: `git tag -a v<version> -m "<release notes summary>"`
6. **Push tag**: `git push origin v<version>`

## Output Format

```
Tag Release | v<version>
========================
Baseline: fm-contracts-v0.1 -- VALID
Breaking changes: none / <list>
Commits since last tag: N
Tag: v<version> created and pushed
```

## Skill Chains

### Mandatory (MUST pass before tag)

- **`[ship-check]`** MUST pass — full pre-ship checklist
- **`[changelog]`** MUST be generated from last tag to HEAD

### Advisory

- **After tag**: `[pypi-publish]`, `[release-notes]`, `[release-announce]`
- **Breaking changes**: `[contract-review]` first (mandatory if major bump)

## Authority

- **T1 (TRUSTED)**: May tag without pre-approval
- **T2 (Active/High)**: May tag with `[ship-check]` passed
- **T3 (Medium)**: MUST get operator approval AND `[ship-check]` passed
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
- **Operator**: Override any restriction — tag-release is irreversible once pushed
