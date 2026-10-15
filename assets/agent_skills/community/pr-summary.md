---
name: pr-summary
description: Generate PR title + body from branch diff and create the PR.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--draft | --dry-run]"
category: dev-tools
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Branch**: Run `git branch --show-current`
- **Commits ahead of main**: Run `git log --oneline main..HEAD 2>/dev/null | head -15 || echo "none"`
- **Changed files**: Run `git diff --name-only main..HEAD 2>/dev/null | head -15 || echo "none"`

# PR Summary Command

Generate a pull request title and body from the current branch's diff against main, then create the PR.

## Usage

```bash
[pr-summary]            # Create PR with generated title + body
[pr-summary] --draft    # Create as draft PR
[pr-summary] --dry-run  # Show title + body without creating PR
```

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=pr-summary] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Gather context
- Current branch name (must not be `main`)
- All commits since divergence from main: `git log --oneline main..HEAD`
- Full diff: `git diff main..HEAD`
- Analyze all changed files, not just the latest commit

### 2. Generate PR content
- **Title**: Under 70 characters, conventional commit style from branch name
- **Body**: Use this format:

```markdown
## Summary
<1-3 bullet points describing the change>

## Test plan
- [ ] <testing steps>

🤖 Generated with AI assistance
```

### 3. Create PR (unless --dry-run)
```bash
gh pr create --title "the title" --body "$(cat <<'EOF'
<body content>
EOF
)"
```

Add `--draft` flag if requested.

### 4. Push first if needed
If the branch has no upstream, run `git push -u origin <branch>` before creating the PR.

## Constraints

- Never create a PR from the `main` branch.
- Analyze ALL commits in the branch, not just the latest.
- Do not fabricate diff content -- always read the actual changes.
- Report the PR URL when done.

## Skill Chains

### Mandatory (MUST pass before PR creation)

- **`[test-run]`** MUST be green — no PR on red local run
- **`[security-scan]`** MUST be clean — zero HIGH/CRITICAL findings

### Advisory

- **Before PR**: `[ship-check]` (full pre-ship checklist)
- **After PR**: `[ci-wait]` (watch CI), `[review-pr]` (structured review)

## Authority

- **T1 (TRUSTED)**: May create PR with all mandatory chains passed
- **T2 (Active/High)**: May create PR with all mandatory chains passed
- **T3 (Medium)**: MUST get operator approval AND all mandatory chains passed
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
- **Operator**: Override any restriction
