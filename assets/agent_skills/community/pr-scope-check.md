---
name: pr-scope-check
description: Verify a PR's body accurately enumerates the files actually changed. Catches body-undercount before reviewer wastes time on forensic accounting.
version: 0.1.0
execution-mode: advisory
argument-hint: "<PR_NUMBER> [<repo>] [<host>]"
category: dev-tools
status: candidate
---
# PR Scope Check

Compare the **list of files in the PR diff** against **the list of files announced/described in the PR body**. Surfaces body-undercount as a P2 finding before reviewer starts substantive review.

## When to use

- Before drafting a Stage-3 review on any PR with the word "Wave", "Batch", "Sprint", "Phase" in title
- Before approving any PR with more than 5 files in the diff
- After any sibling-agent announces a PR ("here's PR #N for review") — verify the announcement matches reality
- Whenever the PR body lists specific files / scopes (counter-check claim vs. reality)

Codified failure mode: `rules/skill-quality.md` § PR body must accurately enumerate touched paths.

## Usage

```bash
[pr-scope-check] <PR_NUMBER>                    # default repo from $REPO_API_URL or current Gitea/GitHub origin
[pr-scope-check] <PR_NUMBER> hummbl-io/apex-nexus  # explicit repo
[pr-scope-check] 2 hummbl-io/apex-nexus workstation      # Workstation-hosted Gitea
```

Host defaults:
- `github` — uses `gh api repos/<owner>/<repo>/pulls/<n>/files`
- `workstation` (default for `HUMMBL/*` repos) — uses `https://workstation.tail093e19.ts.net/api/v1/repos/<owner>/<repo>/pulls/<n>/files` with `$GITEA_TOKEN`
- `gitea-other` — explicit base URL via `$GITEA_BASE_URL`

Tool routing (per `runbooks/tea-gitea-operations.md`): prefer `tea` for interactive PR inspection; use HTTPS API for scripted/CI evidence paths.

## Execution

### 0. Quick PR overview (interactive triage — Gitea)

```bash
tea pulls list --repo hummbl-io/hummbl-governance --limit 20
```
Fallback: curl API (below) if `tea` hangs or output is ambiguous. Use API for specific-PR body/metadata capture in this skill.

### 1. Fetch the file list (canonical source of truth — machine evidence)

**Gitea (Workstation)**:
```bash
curl -s -H "Authorization: token $GITEA_TOKEN" \
  "https://workstation.tail093e19.ts.net/api/v1/repos/<owner>/<repo>/pulls/<n>/files?limit=50" \
  -o /tmp/pr-files.json
```

**GitHub**:
```bash
gh api repos/<owner>/<repo>/pulls/<n>/files --paginate > /tmp/pr-files.json
```

### 2. Fetch the PR body (machine evidence)

```bash
# Gitea
curl -s -H "Authorization: token $GITEA_TOKEN" \
  "https://workstation.tail093e19.ts.net/api/v1/repos/<owner>/<repo>/pulls/<n>" \
  -o /tmp/pr-meta.json
# GitHub
gh pr view <n> --json title,body > /tmp/pr-meta.json
```

### 3. Compare

```bash
$HOME/bin/python.cmd << 'PYEOF'
import json, re
files = json.load(open('/tmp/pr-files.json'))
meta = json.load(open('/tmp/pr-meta.json'))
body = meta.get('body', '')

# Canonical file list from API
api_paths = sorted(f['filename'] for f in files)

# Extract paths mentioned in body (any token that contains a / and a . or looks like a path)
body_paths = sorted(set(re.findall(r'`([\w\-./]+\.[\w]+)`|"([\w\-./]+\.[\w]+)"', body)))
body_paths = sorted({a or b for a, b in body_paths})

unannounced = [p for p in api_paths if p not in body and not any(p.startswith(prefix) for prefix in body_paths if prefix in p)]
unannounced_strict = [p for p in api_paths if p not in body]

# Categorize by top-level dir
from collections import defaultdict
by_dir = defaultdict(list)
for p in api_paths:
    parts = p.split('/', 1)
    by_dir[parts[0] if len(parts) > 1 else '(root)'].append(p)

print(f'\n=== PR scope check ===')
print(f'API reports {len(api_paths)} files touched across {len(by_dir)} top-level dirs:')
for d, paths in sorted(by_dir.items()):
    print(f'  {d}/ : {len(paths)} files')
print()
if unannounced_strict:
    print(f'UNANNOUNCED in body (literal-string match): {len(unannounced_strict)} files')
    for p in unannounced_strict[:20]:
        print(f'  - {p}')
    print()
    # Severity heuristic
    risky = [p for p in unannounced_strict if any(p.startswith(s) for s in ['rules/', 'hooks/', 'contracts/', 'security/', 'agents/', 'services/', '.github/', 'integrations/'])]
    if risky:
        print(f'P2 RISK: {len(risky)} unannounced file(s) touch sensitive scope (rules/hooks/contracts/security/agents/services/.github/integrations):')
        for p in risky:
            print(f'  - {p}')
    else:
        print('P3 NIT: unannounced files are in low-risk scopes (e.g. docs/, _internal/); body update suggested but not blocking.')
else:
    print('PASS: every file in the diff is named somewhere in the PR body.')
PYEOF
```

### 4. Emit output in standard format

```
PR Scope Check | PR #<n> <repo>
═══════════════════════════════════════════════════════════════════

Total files: <N>
Top-level dirs: <list>

Announced in body: <M>
Unannounced: <K>
  Severity: <P2 / P3 / PASS>

Recommendation:
- <PASS>: Body matches diff. Proceed to substantive review.
- <P3>: Unannounced files are low-risk. Note in review comment as nit.
- <P2>: Unannounced files include sensitive scope. Request body update (or `## Additional changes` disclosure) before merge.
```

## Output Format

Always include:
- File count and top-level dir summary
- List of unannounced files (up to 20; truncate beyond)
- Severity verdict (PASS / P3 / P2)
- One-sentence recommendation

## Chain

After running `[pr-scope-check]`:
- PASS → `[review-pr] <n>` (proceed to substantive review)
- P3 → `[review-pr] <n>` (note as nit in review comment)
- P2 → BLOCK on PR with comment "body undercount: X unannounced files"; request author update body before substantive Stage-3 proceeds; OR if operator-authorized, apply a PATCH to PR body via `gh api` / `gh pr edit` before merge

## Anti-patterns

- Don't run on PRs with <3 files — overhead exceeds the value
- Don't run on Dependabot / renovate-bot PRs — those are scoped by template, not human-authored
- Don't fail-loud on body absence: if body is empty, report "no body to compare; suggest body be added" but don't classify as P2 (P3 nit)

## Origin

AAR_2026-05-14 apex-nexus-pr2-wave5-peer-review-and-followup Recommendation #2 [MED]. PR #2 announced "15 ARCANA lens agents" but diff was 25 files (15 agents + 6 rules + 4 skills). Forensic accounting required ~10 minutes of API-vs-body diff inspection that this skill automates into ~30 seconds.

Companion to `rules/skill-quality.md` § PR body must accurately enumerate touched paths.

## Base120 Context

- Primary: **DE12** (Constraint Isolation — separate "what was announced" from "what was committed")
- Related: **RE17** (Versioning & Diff — actual diff IS the truth), **IN17** (Counterfactual Negation — what's NOT in the body that should be)
