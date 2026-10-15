---
name: ops-gameboard
description: Label, categorize, and produce an actionable gameboard view of open issues, PRs, and branch state across GitHub and Gitea repos. Creates label taxonomy, applies labels to issues, and ingests spectrum-wargame findings into prioritized issue pipelines — use when triaging a messy backlog, doing a periodic cleanup ritual, or needing a cross-repo/cross-platform ops view.
version: 1.1.0
execution-mode: side_effecting
argument-hint: "[<repo-name>|--fleet] [--dry-run] [--ingest-wargame <report.md> <repo>]"
status: tested
category: fleet-ops
providers:
  required: [python]
---
# ops-gameboard

Label, categorize, and produce an actionable gameboard view of open issues, PRs, and branch state across GitHub and Gitea repos.

## When to use

- After a burst of issue creation and you've lost track of what's actionable
- When inheriting a repo with a messy backlog
- As a periodic cleanup ritual (weekly/monthly)
- Before a planning session — to see the full board at a glance
- When the operator says "triage issues", "organize the board", "what's actionable", "clean up the backlog"
- When you need a cross-repo or cross-platform (GitHub + Gitea) fleet view
- After running a `spectrum-wargame` or security exercise to ingest findings into trackable GitHub/Gitea issues (`--ingest-wargame`)

## What it does

1. **Ensures label taxonomy** — creates the standard cluster/status/priority/type labels if they don't exist in the target repo (GitHub or Gitea)
2. **Labels all open issues** — reads each issue's title and body, applies cluster + status + type/priority labels using parallel subagents for scale
3. **Produces a gameboard summary** — counts by cluster, status, and priority; surfaces what's actionable vs blocked vs stale
4. **Cross-surfaces** — includes PR triage, stale branches, and CI health alongside issues for a complete ops picture
5. **Multi-platform** — works on GitHub (`gh`) and Gitea (`tea`) with the same taxonomy
6. **Ingests wargame findings** — parses `[SW-*]` structured findings from `spectrum-wargame` and automatically provisions prioritized, clustered remediation issues (`--ingest-wargame`)

## Label taxonomy

### Cluster labels (prefixed `cluster/`)
Domain-specific groupings. Standard set:
- `cluster/krineia` — Krineia specification, daemon, and receipt verifier
- `cluster/governance-kernel` — Core governance kernel, ADRs, and constitutional admission
- `cluster/ebpf-enforcement` — Ring-0 syscall mediation and cgroup containment
- `cluster/multi-agent-audit` — Fleet audit trails, witness mesh, and telemetry
- `cluster/executive-os` — Executive OS commercial experiment
- `cluster/emailops` — EmailOps program
- `cluster/scheduled-task-cp` — Scheduled Task Control Plane
- `cluster/issue-lifecycle` — Issue lifecycle, IssueOps, AI Issue Factory
- `cluster/ownward` — Ownward continuity, protected-person mode
- `cluster/monitoring-situation` — Monitoring the Situation research
- `cluster/runner-infra` — Self-hosted runner infrastructure
- `cluster/bus-bridge` — Bus bridge, watchdog, protocol
- `cluster/network-governance` — Network preflight, web research protocol
- `cluster/peptide-check` — Peptide Check verification
- `cluster/signal-cli` — Signal CLI, mobile comms
- `cluster/slack-mobile` — Slack mobile command
- `cluster/routing-doctrine` — Repo presentation, routing standards
- `cluster/dan-partner-dossier` — Dan dossier privacy

Custom clusters: the skill discovers existing `cluster/*` labels and preserves them. New clusters can be added per-repo.

### Status labels (prefixed `status/`, exactly ONE per issue)
- `status/needs-operator` — Blocked on operator/human decision
- `status/ready-for-execution` — Fully scoped, clear deliverable, ready to execute
- `status/research-backlog` — Idea-stage, exploratory, not yet prioritized
- `status/stale` — May be obsolete or superseded, needs verification

### Priority labels (prefixed `priority/`)
- `priority/P0` — Critical/blocker
- `priority/P1` — High
- `priority/P2` — Medium
- `priority/P3` — Low

### Type labels (prefixed `type:`)
- `type:ops` — Operational/infrastructure work
- `type:research` — Research, exploration, greenfield intake
- `type:governance` — Governance framework, doctrine, policy
- `type:infra` — Infrastructure, CI, runners
- `type:feature` — New feature or capability
- `type:bug` — Something is broken
- `type:docs` — Documentation
- `tech-debt` — Technical debt, refactoring

### Other labels
- `human-review-required` — Requires human review
- `scheduling-needed` — Awaiting scheduling slot
- `dispatch:candidate` — Candidate for agent dispatch

## Platforms

The skill supports two platforms with the same taxonomy. Detect which platform a repo is on, or accept it as a parameter.

### GitHub (`gh`)
- Issues: `gh issue list -R <org/repo> --state open --limit 200 --json ...`
- PRs: `gh pr list -R <org/repo> --state open --limit 100 --json ...`
- Labels: `gh label create ... -R <org/repo>`
- Apply labels: `gh issue edit <n> -R <org/repo> --add-label "l1,l2"`
- Branches: `gh api repos/<org/repo>/branches --jq ...`
- CI: `gh run list -R <org/repo> --branch main --limit 1 --json conclusion`

### Gitea (`tea`)
Gitea uses the `tea` CLI for most operations and the Gitea API for the rest. The Gitea instance runs on agent-node and is reachable via Tailscale IP `http://[REDACTED_NODE_IP]:3030` (or `$GITEA_HOST`). It is NOT reachable via `gitea.hummbl.io` (no DNS A record) or MagicDNS hostname (MagicDNS may be disabled).

**Availability check (run first — Gitea may be down or unconfigured):**
```bash
# Check if tea is installed AND Gitea is reachable AND token is set
command -v tea >/dev/null 2>&1 && TEA_OK=1 || TEA_OK=0
GITEA="${GITEA_HOST:-http://[REDACTED_NODE_IP]:3030}"
if [ -n "$GITEA_TOKEN" ] && curl -s --max-time 2 "$GITEA/api/v1/version" -H "Authorization: token $GITEA_TOKEN" >/dev/null 2>&1; then
  GITEA_OK=1
else
  GITEA_OK=0
fi
# If GITEA_OK=0, skip Gitea surfaces and note "Gitea unavailable" in the gameboard
```

If Gitea is unavailable (DNS fails, no token, `tea` not installed), skip all Gitea surfaces and print "Gitea: unavailable (no tea CLI / no token / host unreachable)" in the gameboard summary. Do NOT error out — GitHub-only repos still produce a valid gameboard.

- Issues: `tea issues list --repo <org/repo> --state open` (or `tea issue list`)
- PRs: `tea pulls list --repo <org/repo> --state open` (or `tea pr list`)
- Labels: `tea labels create --repo <org/repo> --name "status/needs-operator" --description "..." --color "#B60205"`
- Apply labels: `tea issue edit <n> --repo <org/repo> --labels "l1,l2"` (or via API: `curl -X POST "$GITEA_HOST/api/v1/repos/<org/repo>/issues/<n>/labels" -H "Authorization: token $GITEA_TOKEN" -d '{"labels":[1,2]}'`)
- Branches: `tea branches list --repo <org/repo>` (or API: `curl "$GITEA_HOST/api/v1/repos/<org/repo>/branches"`)
- CI: Gitea Actions runs — `curl "$GITEA_HOST/api/v1/repos/<org/repo>/actions/runs?limit=1" -H "Authorization: token $GITEA_TOKEN"`

**Gitea label IDs**: Gitea's API uses numeric label IDs, not names. To apply labels via API, first resolve names to IDs:
```bash
curl -s "$GITEA_HOST/api/v1/repos/<org/repo>/labels" -H "Authorization: token $GITEA_TOKEN" | jq -r '.[] | "\(.id) \(.name)"'
```
Then apply: `curl -X POST "$GITEA_HOST/api/v1/repos/<org/repo>/issues/<n>/labels" -H "Authorization: token $GITEA_TOKEN" -H "Content-Type: application/json" -d '{"labels":[<id1>,<id2>]}'`

**Gitea `tea` CLI label apply** (simpler if `tea` supports it):
```bash
tea issue edit <n> --repo <org/repo> --add-labels "status/ready-for-execution,cluster/bus-bridge"
```
Note: `tea` CLI version varies — check `tea issue edit --help` for available flags. Fall back to API if needed.

## Execution steps

### Step 1: Detect platform

```bash
# GitHub repo check
gh repo view <org/repo> --json name 2>/dev/null && PLATFORM=github

# Gitea repo check
tea repo view <org/repo> 2>/dev/null && PLATFORM=gitea
# or: curl -s "$GITEA_HOST/api/v1/repos/<org/repo>" -H "Authorization: token $GITEA_TOKEN" | jq -r .full_name
```

### Step 2: Ensure label taxonomy

Run `ensure-labels` (below) to create any missing standard labels in the target repo. Discover and preserve existing `cluster/*` labels. Use the appropriate platform command (gh or tea/curl).

### Step 3: Get all open issues

**GitHub:**
```bash
gh issue list -R <org/repo> --state open --limit 200 --json number,title,labels --jq '.[] | "#\(.number)|\([.labels[].name]|join(","))|\(.title[0:70])"'
```

**Gitea:**
```bash
tea issues list --repo <org/repo> --state open --output json 2>/dev/null || \
curl -s "$GITEA_HOST/api/v1/repos/<org/repo>/issues?state=open&type=issues&limit=200" -H "Authorization: token $GITEA_TOKEN" | jq -r '.[] | "#\(.number)|\([.labels[].name]|join(","))|\(.title[0:70])"'
```

### Step 4: Label issues in parallel batches

Split issues into batches of ~40. Dispatch background general-purpose sub-agents to read and label each issue. Each subagent:
- Reads issue title + body (first 500 chars)
- Applies 1-2 cluster labels that fit
- Applies exactly ONE status label
- Adds type/priority labels if missing and clearly applicable
- Does NOT remove existing labels
- GitHub: `gh issue edit <number> -R <org/repo> --add-label "label1,label2"`
- Gitea: `tea issue edit <number> --repo <org/repo> --add-labels "label1,label2"` (or API fallback)

### Step 5: Triage PRs (cross-surface)

Include open PRs in the gameboard for a complete ops view:

**GitHub:**
```bash
gh pr list -R <org/repo> --state open --limit 100 --json number,title,mergeStateStatus,statusCheckRollup,headRefName,isDraft --jq '.[] | "#\(.number)|\(.mergeStateStatus)|\(.isDraft)|\(.headRefName)|\(.title[0:50])"'
```

**Gitea:**
```bash
curl -s "$GITEA_HOST/api/v1/repos/<org/repo>/pulls?state=open&limit=100" -H "Authorization: token $GITEA_TOKEN" | jq -r '.[] | "#\(.number)|\(.mergeable)|\(.head.ref)|\(.title[0:50])"'
```

Categorize PRs by `mergeStateStatus`:
- **CLEAN** → `inbox-awaiting-review` — CI green, mergeable
- **UNSTABLE** → `inbox-awaiting-review` — CI green but unstable (e.g. queued checks)
- **BLOCKED** → `inbox-blocked** — failing checks or conflicts
- **DIRTY** → `inbox-blocked` — merge conflicts
- **UNKNOWN** → `inbox-blocked` — status not yet computed; re-check after a minute
- **BEHIND** → `inbox-blocked` — needs rebase
- **HAS_HOOKS** → `inbox-awaiting-review` — mergeable with hooks
- Draft PRs (`isDraft: true`) → `inbox-draft-disposition` — promote/keep/convert/close decision
- Dependabot PRs (author is `dependabot[bot]`) with CI green → `inbox-dependabot-safe`

### Step 6: Check stale branches

Branches without recent activity or without a corresponding PR are noise. The GitHub branches API returns only `commit.sha` and `commit.url` — NOT the committer date. You must fetch each commit's details via its SHA to get the date.

**GitHub (two-step — list branches, then fetch each commit date):**
```bash
# Step 1: get branch names + SHAs
gh api "repos/<org/repo>/branches?per_page=100" --jq '.[] | .name + " " + .commit.sha' 2>/dev/null > /tmp/branches.txt

# Step 2: fetch each commit's date (rate-limited — batch with sleep if > 30 branches)
while read name sha; do
  date=$(gh api "repos/<org/repo>/commits/$sha" --jq '.commit.committer.date[0:10]' 2>/dev/null)
  echo "$name $date"
done < /tmp/branches.txt
```

For large branch counts (> 30), use `gh api repos/<org/repo>/commits?sha=<branch>&per_page=1` per branch with a 0.5s sleep to avoid rate limits, or use the GraphQL API to batch-fetch.

**Gitea:**
```bash
curl -s "$GITEA_HOST/api/v1/repos/<org/repo>/branches" -H "Authorization: token $GITEA_TOKEN" | jq -r '.[] | .name + " " + .commit.timestamp[0:10]'
```

Flag branches older than 30 days with no open PR as stale. Cross-reference against open PR head branches before flagging.

### Step 7: CI health

**GitHub:**
```bash
# Handles: no runs (empty array), queued (empty conclusion string), completed
gh run list -R <org/repo> --branch main --limit 1 --json conclusion,status --jq 'if length == 0 then "no-ci" else .[0] | .status + "/" + (if (.conclusion // "") == "" then "pending" else .conclusion end) end'
```

**Gitea:**
```bash
curl -s "$GITEA_HOST/api/v1/repos/<org/repo>/actions/runs?limit=1" -H "Authorization: token $GITEA_TOKEN" | \
  jq -r 'if (.workflowRuns | length) == 0 then "no-ci" else .workflowRuns[0] | .status + "/" + (if (.conclusion // "") == "" then "pending" else .conclusion end) end'
```

### Step 8: Produce gameboard summary

After all subagents complete, query the labeled issues and produce:

```
## Ops Gameboard: <org/repo> — <date> (platform: github|gitea)

### CI Health
- main: success/failure/pending

### Issues — By Status (N total)
- ready-for-execution: X
- needs-operator: X
- research-backlog: X
- stale: X

### Issues — By Cluster
- cluster/foo: X issues (Y ready, Z needs-operator)
- cluster/bar: X issues
...

### Pull Requests (N open)
- awaiting-review: X
- blocked: X
- drafts: X
- dependabot-safe: X

### Stale Branches (N found)
- branch-name (last commit: 2026-06-15) — no open PR

### Actionable now (status/ready-for-execution)
- #NNN — title [cluster/foo, priority/P1]
- ...

### Blocked on operator (status/needs-operator)
- #NNN — title [cluster/bar, priority/P0]
- ...

### Stale candidates (status/stale)
- #NNN — title — recommend closing
- ...
```

## ensure-labels script

Create standard labels if they don't exist. Run per-repo. Detect platform first.

### GitHub

```bash
# Status labels
gh label create "status/needs-operator" -R <org/repo> --description "Blocked on operator decision" --color B60205 2>/dev/null
gh label create "status/ready-for-execution" -R <org/repo> --description "Fully scoped and ready to execute" --color 0E8A16 2>/dev/null
gh label create "status/research-backlog" -R <org/repo> --description "Idea-stage research — not yet prioritized" --color a371f7 2>/dev/null
gh label create "status/stale" -R <org/repo> --description "May be obsolete — needs verification" --color FBCA04 2>/dev/null

# Standard cluster labels (create only those relevant to the repo)
gh label create "cluster/krineia" -R <org/repo> --description "Krineia specification, daemon, and receipt verifier" --color 5319E7 2>/dev/null
gh label create "cluster/governance-kernel" -R <org/repo> --description "Core governance kernel, ADRs, and constitutional admission" --color 1D76DB 2>/dev/null
gh label create "cluster/ebpf-enforcement" -R <org/repo> --description "Ring-0 syscall mediation and cgroup containment" --color D93F0B 2>/dev/null
gh label create "cluster/multi-agent-audit" -R <org/repo> --description "Fleet audit trails, witness mesh, and telemetry" --color 006B75 2>/dev/null
# ... see cluster list above for others

# Priority labels (if missing)
gh label create "priority/P0" -R <org/repo> --description "Critical/blocker" --color B60205 2>/dev/null
gh label create "priority/P1" -R <org/repo> --description "High priority" --color B60205 2>/dev/null
gh label create "priority/P2" -R <org/repo> --description "Medium priority" --color D93F0B 2>/dev/null
gh label create "priority/P3" -R <org/repo> --description "Low priority" --color 0E8A16 2>/dev/null
```

### Gitea

```bash
GITEA="${GITEA_HOST:-http://[REDACTED_NODE_IP]:3030}"
AUTH="Authorization: token $GITEA_TOKEN"

# Status and Governance Cluster labels (Gitea uses hex with #)
for label in \
  "status/needs-operator:Blocked on operator decision:B60205" \
  "status/ready-for-execution:Fully scoped and ready to execute:0E8A16" \
  "status/research-backlog:Idea-stage research not yet prioritized:a371f7" \
  "status/stale:May be obsolete needs verification:FBCA04" \
  "priority/P0:Critical blocker:B60205" \
  "priority/P1:High priority:B60205" \
  "priority/P2:Medium priority:D93F0B" \
  "priority/P3:Low priority:0E8A16" \
  "cluster/krineia:Krineia daemon and receipt verifier:5319E7" \
  "cluster/governance-kernel:Core governance kernel and ADRs:1D76DB" \
  "cluster/ebpf-enforcement:Ring-0 syscall mediation and cgroup containment:D93F0B" \
  "cluster/multi-agent-audit:Fleet audit trails and witness mesh:006B75"; do
  IFS=: read -r name desc color <<< "$label"
  curl -s --max-time 2 -X POST "$GITEA/api/v1/repos/<org/repo>/labels" \
    -H "$AUTH" -H "Content-Type: application/json" \
    -d "{\"name\":\"$name\",\"description\":\"$desc\",\"color\":\"#$color\"}" 2>/dev/null
done

# Discover existing cluster labels
curl -s "$GITEA/api/v1/repos/<org/repo>/labels" -H "$AUTH" | jq -r '.[] | select(.name | startswith("cluster/")) | .name'
```

## Gameboard query

After labeling, generate the summary. Detect platform first.

### GitHub

```bash
# Count by status
for label in "status/needs-operator" "status/ready-for-execution" "status/research-backlog" "status/stale"; do
  count=$(gh issue list -R <org/repo> --state open --label "$label" --limit 200 --json number --jq 'length')
  echo "$label: $count"
done

# Count by cluster
for label in $(gh label list -R <org/repo> --limit 100 --json name --jq '.[] | select(.name | startswith("cluster/")) | .name'); do
  count=$(gh issue list -R <org/repo> --state open --label "$label" --limit 200 --json number --jq 'length')
  echo "$label: $count"
done

# Actionable list
gh issue list -R <org/repo> --state open --label "status/ready-for-execution" --limit 100 --json number,title,labels --jq '.[] | "#\(.number) — \(.title[0:60]) [\([.labels[].name] | map(select(. | startswith("cluster/") or startswith("priority/"))) | join(", "))]"'
```

### Gitea

```bash
GITEA="${GITEA_HOST:-http://[REDACTED_NODE_IP]:3030}"
AUTH="Authorization: token $GITEA_TOKEN"

# Count by status
for label in "status/needs-operator" "status/ready-for-execution" "status/research-backlog" "status/stale"; do
  count=$(curl -s "$GITEA/api/v1/repos/<org/repo>/issues?state=open&type=issues&labels=$label&limit=200" -H "$AUTH" | jq 'length')
  echo "$label: $count"
done

# Count by cluster
for label in $(curl -s "$GITEA/api/v1/repos/<org/repo>/labels" -H "$AUTH" | jq -r '.[] | select(.name | startswith("cluster/")) | .name'); do
  count=$(curl -s "$GITEA/api/v1/repos/<org/repo>/issues?state=open&type=issues&labels=$label&limit=200" -H "$AUTH" | jq 'length')
  echo "$label: $count"
done

# Actionable list
curl -s "$GITEA/api/v1/repos/<org/repo>/issues?state=open&type=issues&labels=status/ready-for-execution&limit=100" -H "$AUTH" | \
  jq -r '.[] | "#\(.number) — \(.title[0:60]) [\([.labels[].name] | map(select(. | startswith("cluster/") or startswith("priority/"))) | join(", "))]"'
```

## Fleet mode

Run the gameboard across multiple repos at once. Produces a combined summary.

### GitHub fleet

```bash
# All repos in an org
repos=$(gh repo list <org> --limit 100 --json nameWithOwner --jq '.[].nameWithOwner')

# Or a curated list
repos="hummbl-io-org/hummbl-governance hummbl-io-org/hummbl-bus hummbl-io-org/hummbl-dashboard"
```

For each repo:
1. Ensure labels (fast — just creates missing ones)
2. Get issue/PR/branch/CI counts (parallel queries)
3. Skip labeling if issue count < 5 (not worth subagent overhead — just categorize in the summary)

### Gitea fleet

```bash
repos=$(curl -s "$GITEA/api/v1/orgs/<org>/repos?limit=100" -H "$AUTH" | jq -r '.[].full_name')
```

### Mixed fleet (GitHub + Gitea)

```bash
# Combine both repo lists
github_repos=$(gh repo list <org> --limit 100 --json nameWithOwner --jq '.[].nameWithOwner')
gitea_repos=$(curl -s "$GITEA/api/v1/orgs/<org>/repos?limit=100" -H "$AUTH" | jq -r '.[].full_name')
all_repos="$github_repos $gitea_repos"
```

### Fleet gameboard output

```
## Fleet Ops Gameboard — <date>

### CI Health (N repos)
- passing: X
- failing: X
- no CI: X

### Issues across fleet (N total)
- ready-for-execution: X
- needs-operator: X
- research-backlog: X
- stale: X

### PRs across fleet (N open)
- awaiting-review: X
- blocked: X
- drafts: X

### Per-repo breakdown
| Repo | Issues | PRs | CI | Stale branches |
|------|--------|-----|----|----------------|
| hummbl-bus | 12 | 0 | pass | 1 |
| hummbl-governance | 3 | 0 | pass | 0 |
| ...

### Top actionable across fleet
- hummbl-bus#NNN — title [cluster/foo, P1]
- hummbl-governance#NNN — title [P2]
- ...
```

## Repeatable across repos

This skill works on any GitHub or Gitea repo. The cluster labels are domain-specific but the status/priority/type taxonomy is universal. For a new repo:
1. Detect platform (gh or tea/curl)
2. Run ensure-labels (creates status + priority labels)
3. Discover or define cluster labels relevant to that repo
4. Label issues in parallel batches (skip if < 5 issues)
5. Triage PRs, check stale branches, check CI
6. Produce gameboard

For fleet mode: run steps 1-6 per repo, then aggregate.

## Wargame Ingestion (`--ingest-wargame`)

Ingest adversarial security findings from `spectrum-wargame` or `wargame` markdown reports directly into GitHub or Gitea issues. This closes the loop between multi-color wargame audits and actionable engineering execution.

### Usage
```bash
# Ingest wargame report into GitHub repo
ops-gameboard --ingest-wargame docs/wargame/krineia_v3_wargame_report.md hummbl-io/krineia

# Ingest with dry-run preview (no issues created)
ops-gameboard --ingest-wargame docs/wargame/krineia_v3_wargame_report.md hummbl-io/krineia --dry-run
```

### Parsing Discipline & Mapping Rules
1. **Finding Signature**:
   The parser scans for finding headers matching:
   `[SW-<COLOR>-<ID>] <SEVERITY> — <Title> | Evidence: <path:line>`
   (or legacy `[R<round>-<ID>]` syntax).

2. **Priority & Status Mapping**:
   - `CRITICAL` findings:
     - Label: `priority/P0`
     - Status: `status/ready-for-execution` (or `status/needs-operator` if architectural decision or API breaking change)
   - `HIGH` findings:
     - Label: `priority/P1`
     - Status: `status/ready-for-execution`
   - `MEDIUM` findings:
     - Label: `priority/P2`
     - Status: `status/ready-for-execution`
   - `LOW` / `INFORMATIONAL` findings:
     - Label: `priority/P3`
     - Status: `status/research-backlog`

3. **Cluster Inference Heuristic**:
   - Matches keywords `ebpf`, `lsm`, `syscall`, `cgroup`, `seccomp` $\rightarrow$ `cluster/ebpf-enforcement`
   - Matches keywords `krineia`, `verify_chain`, `receipt`, `merkle`, `mmr` $\rightarrow$ `cluster/krineia`
   - Matches keywords `constitution`, `adr`, `invariant`, `governance`, `admission` $\rightarrow$ `cluster/governance-kernel`
   - Matches keywords `bus`, `witness`, `telemetry`, `rekor`, `audit`, `mesh` $\rightarrow$ `cluster/multi-agent-audit`
   - Falls back to existing repo clusters or general `type:security`

4. **Issue Creation Automation**:
   - **GitHub**:
     ```bash
     gh issue create -R <org/repo> \
       --title "[SW-RED-01] eBPF map TOCTOU race condition" \
       --body "### Finding Description\n...\n\n### Evidence\nverify_chain.py:142\n\n### Source\nSpectrum Wargame (Red Team)" \
       --label "priority/P0,status/ready-for-execution,cluster/ebpf-enforcement,type:bug"
     ```
   - **Gitea**:
     ```bash
     curl -s --max-time 2 -X POST "$GITEA/api/v1/repos/<org/repo>/issues" \
       -H "$AUTH" -H "Content-Type: application/json" \
       -d '{"title":"...","body":"...","labels":[<resolved_label_ids>]}'
     ```

5. **Dry-Run Enforcement**:
   When `--dry-run` is passed, the parser outputs the complete list of candidate issues, their inferred priorities, statuses, and clusters without executing `gh` or `curl` mutations.

## Skill chaining and pairing

The ops-gameboard is a **planning surface** — it tells you what's actionable. Pair it with execution skills to actually do the work. The gameboard produces the board; chained skills move pieces.

### Chain: wargame → gameboard → execution

```
spectrum-wargame (adversarial multi-color exercise)
  → ops-gameboard --ingest-wargame (parse [SW-*] findings into issues)
  → coderabbit review (pre-PR code audit)
  → verify_chain.py (fail-closed cryptographic receipt verification)
  → ci-monitor (watch actions after merge)
```

### Chain: gameboard → execution

```
ops-gameboard (label + categorize)
  → fleet-status (check CI health across repos)
  → regression-check (trace dependents before executing)
  → dep-check (verify zero third-party deps after changes)
  → security-scan (bandit + semgrep on changed code)
  → pr-summary (generate PR title + body from diff)
  → ci-monitor (watch CI after PR creation)
```

### Chain: gameboard → governance

```
ops-gameboard (identify governance issues)
  → hummbl-business-review (quarterly/board review of issue clusters)
  → hummbl-metrics-dashboard (track issue throughput, stale rate)
  → governance-report (periodic governance health report)
  → gap-analysis (compare controls against framework requirements)
  → remediation-plan (prioritized remediation from gap analysis)
  → threat-model (STRIDE model for security-tagged issues)
```

### Chain: gameboard → git/PR workflow

```
ops-gameboard (identify ready-for-execution issues)
  → coderabbit review (local code review before PR)
  → gk ai commit (AI-generated commit message)
  → gk ai changelog (changelog between branches)
  → gk pr list (cross-provider PR view)
  → pr-summary (generate PR title + body)
  → ci-monitor (watch CI)
  → repo-sync (check fleet-wide sync state after merge)
```

### CodeRabbit CLI (`coderabbit`)

CodeRabbit CLI (v0.7.2) provides local code review and agent skills. Pair with ops-gameboard when executing `status/ready-for-execution` issues.

**Prerequisites**: Run `coderabbit auth status` first. The Free plan works for local reviews (`coderabbit review`) but connect time is slow (~30s). No seat assignment required for CLI reviews. If reviews time out, use `pr-summary` skill as fallback.

- `coderabbit review` — review local changes before creating a PR. Run after implementing an issue fix, before `gh pr create`. Works on Free plan but slow (~30s connect).
- `coderabbit review --agent` — emit structured findings for agents. Use when you want machine-parseable review output to decide if a PR is ready.
- `coderabbit skills` — install/update CodeRabbit agent skills. These are review-quality skills that complement ops-gameboard's triage skills.
- `coderabbit stats` — review statistics. Use in fleet mode to track review coverage across repos.
- `coderabbit doctor` — check installation and review readiness. Run once during fleet setup.

**Chain pattern**: `ops-gameboard` identifies issue → implement fix → `coderabbit review` → `pr-summary` → `gh pr create` → `ci-monitor`

**CodeRabbit + gameboard fleet mode**: After running the gameboard across a fleet, use `coderabbit stats` per-repo to add a "review coverage" column to the per-repo breakdown table.

### GitKraken CLI (`gk`)

GitKraken CLI provides AI-powered git workflows. Pair with ops-gameboard for the git/PR execution layer.

**Prerequisites**: Run `gk auth` and `gk provider` setup before first use. Verify with `gk whoami`. Current setup: Pro subscription, authenticated as hummbl-io.

**Important**: `gk issue list` and `gk pr list` require BOTH `--org` and `--repo` flags — not just `--repo`. Example: `gk issue list --org hummbl-io-org --repo hummbl-bus`.

- `gk issue list --org <org> --repo <repo>` — cross-provider issue view. Use as an alternative to `gh issue list` / `tea issues list` when working across GitHub and Gitea in fleet mode.
- `gk issue assign --org <org> --repo <repo>` — assign issues. Use after gameboard triage to assign `status/ready-for-execution` issues to agents.
- `gk pr list --org <org> --repo <repo>` — cross-provider PR view. Use in the PR triage step (Step 5) for mixed GitHub/Gitea fleets.
- `gk ai commit` — AI-generated commit message. Use after implementing an issue fix.
- `gk ai changelog` — changelog between commits/branches. Use when merging a cluster of issues into a release.
- `gk ai explain` — explain commits or branches. Use when triaging `status/stale` issues to understand what was done.
- `gk ai resolve` — AI conflict resolution. Use when rebasing stale PRs identified by the gameboard.
- `gk ai pr` — AI-powered PR management. Use for PR description generation as an alternative to `pr-summary` skill.
- `gk graph` — commit graph visualization. Use when investigating stale branches or complex branch topologies.
- `gk mcp` — start local MCP server. Use when you want another MCP client to interact with GitKraken's git/issue/PR capabilities.

**Chain pattern**: `ops-gameboard` identifies stale PR → `gk ai explain` to understand the branch → `gk ai resolve` to fix conflicts → `coderabbit review` → merge

**GitKraken + gameboard fleet mode**: `gk issue list` and `gk pr list` work across providers, making them the unified query layer for mixed GitHub+Gitea fleets. Use `gk` commands instead of separate `gh`/`tea` calls when the fleet spans both platforms.

### Skill pairing matrix

| Gameboard output | Paired skill | What it does |
|-----------------|-------------|--------------|
| `status/ready-for-execution` issues | `coderabbit review` | Review fix before PR |
| `status/ready-for-execution` issues | `pr-summary` | Generate PR title + body |
| `status/needs-operator` issues | `hummbl-business-review` | Surface in quarterly review |
| `status/stale` issues | `gk ai explain` | Understand what was done |
| `status/stale` PRs | `gk ai resolve` | Fix merge conflicts |
| `cluster/runner-infra` issues | `fleet-status` | Check runner health |
| `cluster/bus-bridge` issues | `ci-monitor` | Watch bus CI |
| `cluster/issue-lifecycle` issues | `governance-report` | Report on issue throughput |
| Security-tagged issues | `threat-model` | STRIDE model the issue |
| Security-tagged issues | `security-scan` | Bandit + semgrep scan |
| Wargame findings (`[SW-*]`) | `ops-gameboard --ingest-wargame` | Parse & create trackable GitHub/Gitea issues |
| `cluster/krineia` issues | `verify_chain.py` | Fail-closed cryptographic receipt verification |
| `cluster/governance-kernel` issues | `hummbl-governance` | Audit ADR & constitutional invariants |
| `cluster/ebpf-enforcement` issues | `security-scan` | Verify kernel & cgroup security posture |
| Post-merge verification | `regression-check` | Trace dependents |
| Post-merge verification | `dep-check` | Verify zero third-party deps |
| Fleet-wide CI | `repo-sync` | Check sync state across repos |
| Fleet-wide CI | `ci-monitor` | Watch GitHub Actions |
| Changelog generation | `gk ai changelog` | AI changelog between branches |
| Commit messages | `gk ai commit` | AI commit message |

### Recommended routing

When the operator says:
- "triage issues" / "organize the board" → `ops-gameboard` alone
- "what's actionable" → `ops-gameboard` → present `status/ready-for-execution` list
- "ingest wargame" / "process wargame findings" → `ops-gameboard --ingest-wargame <report.md> <repo>`
- "execute issue #NNN" → `ops-gameboard` (context) → implement → `coderabbit review` → `pr-summary` → `ci-monitor`
- "fleet health" → `ops-gameboard` (fleet mode) → `fleet-status` → `repo-sync` → `ci-monitor`
- "governance review" → `ops-gameboard` (governance clusters) → `hummbl-business-review` → `governance-report`
- "clean up stale issues" → `ops-gameboard` (status/stale) → close with comment → `governance-report`
- "review my changes" → `coderabbit review` → `pr-summary`
- "resolve conflicts" → `gk ai resolve` → `coderabbit review` → merge

## Constraints

- Only ADD labels, never remove existing ones
- Apply exactly ONE status label per issue
- Don't duplicate existing type/priority labels
- Use `2>/dev/null` on GitHub label creation to suppress "already exists" errors
- Use `2>/dev/null` on Gitea API calls and check response for "already exists" message
- Subagent batches of ~40 issues for parallelism without rate limits
- Always use `--add-label` (GitHub) or API POST (Gitea) — never replace labels
- Gitea API uses numeric label IDs — resolve names to IDs before applying via API
- For fleet mode, skip repos with < 5 open issues (not worth subagent overhead)
- Gitea `tea` CLI flag names vary by version — fall back to API if `tea` doesn't support a flag
- When pairing with `coderabbit`, run review BEFORE PR creation — not after
- When pairing with `gk`, use `gk` commands for cross-provider fleets instead of separate `gh`/`tea`
- `gk` requires authentication — run `gk auth` and `gk provider` setup before first use

## Mandatory

- Authentication must be verified before any label-taxonomy creation or issue labeling: `gh auth status` (GitHub) and/or `tea login list` (Gitea) — do not attempt label mutations against an unauthenticated or wrong-account session.
- For `gk`-paired workflows, `gk auth` and `gk provider` setup must be confirmed first (per Constraints above).
- Label taxonomy (`cluster/*`, `status/*`, `priority/*`, `type/*`) must exist in the target repo, or be created in this run, before any issue is labeled — never apply a label that doesn't exist in the repo's label set.

## Authority

- **T1 (TRUSTED)**: May run (label taxonomy + issue labeling; additive-only per Constraints)
- **T2 (Active/High)**: May run (label taxonomy + issue labeling; additive-only per Constraints)
- **T3 (Medium)**: May run with operator awareness (mutates shared issue trackers visible to the whole fleet)
- **T4 (Probationary)**: BLOCKED — labeling mistakes are visible fleet-wide and additive-only discipline is easy to violate under-experience
- **Operator**: Override any restriction
