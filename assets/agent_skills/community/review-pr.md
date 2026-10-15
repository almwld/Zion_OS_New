---
name: review-pr
description: Structured PR review -- fetch diff, run mtsmu-review, check CI, post summary.
version: 0.1.0
execution-mode: advisory
argument-hint: <PR_NUMBER or PR_URL or BRANCH>
category: dev-tools
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Open PRs**: Run `gh pr list --limit 5 --json number,title,author,headRefName --jq '.[] | "#\(.number) \(.title) (\(.author.login)) [\(.headRefName)]"' 2>/dev/null || echo "(gh not available)"`

# Review PR Command

Structured code review of a pull request using MTSMU-REVIEW rigor.

## Execution

### 1. Fetch the PR
```bash
gh pr view $PR_NUMBER --json title,body,headRefName,baseRefName,additions,deletions,changedFiles
gh pr diff $PR_NUMBER
```

### 1b. Pre-Approve Author Check
Before composing the review body or proposing an approval, verify that the acting account is not attempting to self-approve:
```bash
python scripts/safe_pr_review.py --check-pre-approve --repo $REPO --pr $PR_NUMBER
# Or check directly:
ACTING_ACCOUNT=$(gh api user --jq .login 2>/dev/null)
PR_AUTHOR=$(gh pr view $PR_NUMBER --repo $REPO --jq .author.login 2>/dev/null)
if [ "$ACTING_ACCOUNT" = "$PR_AUTHOR" ]; then
    echo "self-approve-blocked: post comment instead"
fi
```
If the check returns `self-approve-blocked: post comment instead`, you MUST NOT compose or submit an `APPROVE` verdict. Post a review comment instead.

### 2. Assess scope
- Check LOC (warn at 500, block at 3000 per pr-guardrails.yml)
- Count files changed
- Identify high-risk surfaces (services/, integrations/, bus/, contracts/, .github/)

### 3. Run MTSMU-REVIEW
Apply the mtsmu-review skill against the diff:
- Prioritize bugs, regressions, unsafe assumptions, missing tests
- Check env resolution, defaults, config precedence
- Verify tests cover failure modes not just happy path

### 4. Check CI
```bash
gh pr checks $PR_NUMBER
```

### 5. Check and resolve PR conversations
```bash
OWNER="${OWNER:-hummbl-io}"
REPO="${REPO:-hummbl-governance}"
gh api repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments \
  --jq '.[] | "#\(.id) [\(.user.login)] \(.path):\(.line) \(.body[:80])"'
```
- Read every comment from other agents (especially chatgpt-codex-connector)
- Either fix the issue or reply explaining why it's not applicable
- **Unresolved conversations block merges**

### 6. Verify agent guardrails
If the PR is from a non-Claude agent (codex, gemini, kimi):
- Check scope against agent's approved scope (see guardrails rules)
- Verify no blocked files were touched
- Check LOC limits per agent

### 6. Post summary
Output findings in this format:

```
PR Review | #<number> <title>
═══════════════════════════════

Author: <author> | Branch: <branch>
Scope: +<additions> -<deletions> across <files> files

## Findings
<severity-ordered findings from mtsmu-review>

## CI Status
<pass/fail per workflow>

## Agent Compliance
<if applicable: scope check, guardrail check>

## Verdict
[APPROVE | REQUEST_CHANGES | NEEDS_DISCUSSION]
<1-sentence rationale>

> **Note**: Self-approval is prohibited. If `gh pr view --jq .author.login` matches the acting account, the pre-approve check returns `self-approve-blocked: post comment instead`. Post a comment rather than approving.
```
