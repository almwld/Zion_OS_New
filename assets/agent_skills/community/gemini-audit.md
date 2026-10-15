---
name: gemini-audit
description: Audit Gemini-authored artifacts using adopt/adapt/avoid triage. Produces a structured verdict per file with evidence.
version: 0.1.0
execution-mode: advisory
argument-hint: "<branch | file-path | stash-ref> [--scope bif|rif|cognition|all]"
category: governance-compliance
status: candidate
---
# [gemini-audit]

Adopt/adapt/avoid triage for Gemini-authored work. Produces a verdict table per artifact with evidence, severity, and action. Reference playbook: `hummbl_governance/playbooks/GEMINI_AUDIT.md`.

## Context Gathering

Before executing this skill, gather the following context:
- **Branch**: Run `git branch --show-current 2>/dev/null`
- **Gemini branches**: Run `git branch --list "feat/gemini/*" 2>/dev/null | head -10`
- **Stash list**: Run `git stash list 2>/dev/null | head -10`
- **AIP streak**: Run `grep -m1 "AIP streak\|AIP clean-session" ~/.agents/rules/gemini-guardrails.md 2>/dev/null`

## Arguments

- `$ARGUMENTS` — branch name (e.g. `feat/gemini/bif-bridge`), file path, stash ref (`stash@{0}`), or `--all` to audit all Gemini branches
- `--scope` — filter to a subsystem: `bif`, `rif`, `cognition`, `all` (default: `all`)

If no argument is provided, default to the most recent Gemini stash or the current branch if it matches `feat/gemini/*`.

## Pre-flight (run ONCE before triage)

### 0a. Phantom-WIP detection (origin/main comparison)
Before treating any `git diff HEAD` output as "real WIP to extract", compare the working-tree state against `origin/main` — a feature branch may simply be behind main, making the "diff" a phantom (content already shipped).

```bash
git fetch origin main --quiet
for f in $(git diff --name-only HEAD 2>/dev/null); do
  local_md5=$(md5 -q "$f" 2>/dev/null || echo "absent")
  main_md5=$(git show origin/main:"$f" 2>/dev/null | md5 -q || echo "absent")
  if [ "$local_md5" = "$main_md5" ]; then
    echo "PHANTOM  $f  (branch is behind origin/main; file already shipped)"
  else
    echo "REAL_WIP $f"
  fi
done
```

- `PHANTOM` files: **do not extract**. Branch just needs `git pull --rebase origin main`.
- `REAL_WIP` files only: proceed to per-file triage.

**Rationale**: On 2026-04-16 (salvage of `feat/gemini/crce-theory-stack`), 4 of 5 "Claude WIP code files" turned out to be identical to `origin/main` — the branch was 12 commits behind main. Wasted one worktree creation before the phantom was detected.

### 0b. PR-duplication pre-flight (prevent duplicate extraction PRs)
Before creating a new branch/PR to extract WIP touching a file, search for in-flight PRs already modifying that file:

```bash
# Filename-based check (pick the most distinctive file in your scope)
gh pr list --state open --search "<filename>"

# OR scan all open PRs for filename overlap
for pr in $(gh pr list --state open --json number --jq '.[].number'); do
  gh pr view "$pr" --json files --jq ".files[].path" | grep -Fq "<target-file>" && echo "  ↑ PR #$pr touches this"
done
```

If a match exists: **do not extract**. Defer to the existing PR or coordinate a bundled commit there. If not: proceed.

**Rationale**: On 2026-04-16, PR #456 was opened to extract `adversary.py` from Gemini crce WIP. PR #435 (`feat/claude/trace-paper-probes`) was already open with the identical A2/A4/A5 enum additions plus a factorial runner (strict superset, 456 adds vs 116). PR #456 had to be closed as superseded. Memory: `feedback_pr_duplication_preflight.md`.

## Checks (run for each artifact)

### 1. Stdlib Compliance
```bash
# For any .py file in services/ or integrations/:
grep -rn "^import\|^from" <file> | grep -v "^from __future__\|stdlib" | head -20
# Then verify against: python3 -c "import sys; print(sys.stdlib_module_names)"
```
Flag: any non-stdlib import in `services/` or `integrations/`.

### 2. Test Coverage
```bash
# Check if tests exist for the artifact
ls hummbl_governance/tests/test_$(basename $file .py)*.py 2>/dev/null
# Count tests
grep -c "^def test_\|^    def test_" <test_file> 2>/dev/null || echo "0"
```
Flag: no tests, or logic is unverifiable without tests.

### 3. Path Correctness
```bash
# Verify files are in approved directories
# Docs must be in hummbl_governance/docs/research/ (not root docs/research/)
git diff --name-only HEAD~1..HEAD 2>/dev/null | grep -v "^hummbl_governance/docs/research/\|^hummbl_governance/tests/\|^hummbl_governance/services/\|^hummbl_governance/integrations/"
```
Flag: any file written to wrong directory (root `docs/`, blocked scope).

### 4. LOC Count
```bash
# Count committed tracked lines changed
git diff --stat HEAD~1..HEAD 2>/dev/null | tail -1
# Or for a branch:
git diff main...<branch> --stat 2>/dev/null | tail -1
# Also surface untracked artifacts separately; diff stats omit them
git status --short --untracked-files=all 2>/dev/null | grep '^??' || true
```
Thresholds: <500 LOC = green, 500–2000 = yellow (adapt candidate), >2000 = red (avoid).

### 5. Scope Adherence
```bash
# Check for blocked-scope files
git diff --name-only HEAD~1..HEAD 2>/dev/null | grep -E "^services/|^integrations/|^\.github/|^\.claude/|^security/"
```
Flag: any file in `services/`, `integrations/`, `.github/`, `.claude/`, `security/`, `contracts/` without explicit human approval.

### 6. Sourced Claims (style vs content — verify before rejecting)
Review research docs for unsourced statistics:
```bash
grep -n "[0-9]\+%" <file> | grep -v "\[ESTIMATE\|http\|arXiv\|doi\|cite" | head -20
```
Flag: bare numbers/percentages without URL, arXiv ID, or `[ESTIMATE: basis]` tag.

**CRITICAL — fabrication style ≠ fabrication content.** Gemini often writes in a confident, specific tone whether the underlying facts are real or invented. "Style signals" (specific percentages to tenths, named company quotes, CVE IDs, specific rankings) LOOK fabricated but may cite real sources that were simply omitted.

Before issuing an **AVOID** verdict on any public-claim statistic, entity, or citation — **web-verify first**:

```bash
# For statistics: search for the primary report
# For CVE IDs: WebFetch https://nvd.nist.gov/vuln/detail/<CVE-ID> (200 = real, 404 = fabricated)
# For named partnerships: search "<company> <partner> announcement"
# For product rankings: search "<company> <award> <year>" and verify ranking
# For company/product existence: WebFetch homepage or search by name
```

Verdict rule:
- Claim verified → **ADOPT** with URL inserted
- Claim contradicted (e.g., 404 on CVE, no announcement found after 2+ queries) → **AVOID** with strike rationale
- Claim unverifiable either way → **ADAPT** — paraphrase to remove false attribution, or add `[UNVERIFIED — requires primary source]` inline flag

**Rationale**: On 2026-04-16 (Apr 14 Gemini research docs salvage), an initial style-based Opus audit rated 2 of 4 docs as AVOID based on fabrication-looking specifics. Web verification flipped both to SALVAGE — Project Glasswing, CVE-2026-39885, CVE-2026-26118, Credo AI #6 Fast Company, Credo $41.3M funding, IANS 92%/86% stats were all REAL. Only 3 of 8 flagged claims in one doc actually needed paraphrase; 5 were simply missing URLs. Cost of skipping web-verification: destroying verified content and under-shipping the salvage. Memory: `feedback_gemini_stash_review.md`, AAR 2026-04-16 gemini-crce-wip-salvage.

### 7. IDP/Bus Protocol
```bash
# Check for raw echo/printf to bus
grep -n "echo.*messages.tsv\|printf.*messages.tsv\|tee.*messages.tsv" <file> 2>/dev/null
# Check bus sender identity
grep -n "from.*gemini" <file> 2>/dev/null | grep -v '"gemini"'
```
Flag: non-bus-writer bus writes, parenthetical sender variants.

### 8. Phantom Work Detection
```bash
# Compare commit message claims against actual diff
git log --format="%s%n%b" -1 HEAD 2>/dev/null
git diff --stat HEAD~1..HEAD 2>/dev/null
git status --short --untracked-files=all 2>/dev/null | grep '^??' || true
```
Flag: commit message claims a feature/file that does not appear in the diff.

### 9. Canonicality Claims
Scan docs for unqualified canonicality assertions:
```bash
grep -n "canonical\|LIVE\|shipped\|production\|deployed" <doc_file> | grep -v "\[STATUS:\|TRACKED\|VERIFIED" | head -20
```
Flag: repo-state claims without source-class label (`TRACKED`, `UNTRACKED`, `_STATE`, `EXTERNAL`, `TRANSCRIPT`, `INFERENCE`).

### 10. Orphan .pyc Detection
```bash
# Scan for .pyc files with no matching .py source (deleted source = orphaned bytecode)
find . -name "*.pyc" -path "*/__pycache__/*" | while IFS= read -r pyc; do
  base="${pyc##*/__pycache__/}"
  src_name="${base%%.cpython-*.pyc}.py"
  dir="${pyc%__pycache__/*}"
  src="${dir}${src_name}"
  [ ! -f "$src" ] && echo "ORPHAN: $pyc  (no matching $src)"
done
```
Flag: any `.pyc` without a matching `.py` source — indicates deleted source with orphaned bytecode (e.g., `rif_v7_core.cpython-314.pyc`). These can contain Gemini-authored logic that bypasses normal code review. Verdict for orphan `.pyc`: **AVOID** unless source is recovered and passes all other checks.

## Decision Framework

| Check | ADOPT | ADAPT | AVOID |
|-------|-------|-------|-------|
| Stdlib compliance | All stdlib | Fixable import | Non-stdlib in services/integrations |
| Test coverage | Tests pass, logic verified | Tests missing but addable | No tests + unverifiable logic |
| Path correctness | All paths correct | Wrong dir → fixable | Blocked scope without approval |
| LOC count | < 500 LOC | 500–2000 LOC | > 2000 LOC |
| Scope adherence | Within approved scope | Minor creep → trim | Blocked files touched |
| Sourced claims | All claims sourced | Fixable citations | Fabricated statistics |
| IDP/bus protocol | Correct | Correctable | Security violation |
| Phantom work | Diff matches claims | Overclaims → correct | Diff does not match claims |
| Canonicality | Source labels present | Add labels | Presents roadmap as reality |
| Orphan .pyc | No orphans | N/A | Orphan found (deleted source) |

**Overall verdict**: most-restrictive rule wins. One AVOID check = AVOID verdict.

## Output Format

```
[gemini-audit] | <branch-or-ref> | <date>

## Artifact Summary
- Branch/ref: <name>
- Files changed: N
- LOC delta: +N / -N
- Scope: <subsystem>

## Verdict Table
| File | Stdlib | Tests | Paths | LOC | Scope | Claims | Protocol | Phantom | Orphan .pyc | Verdict |
|------|--------|-------|-------|-----|-------|--------|----------|---------|-------------|---------|
| foo.py | PASS | PASS | PASS | 120 | PASS | N/A | PASS | PASS | PASS | **ADOPT** |
| bar.md | N/A | N/A | FAIL | 45 | PASS | FAIL | N/A | PASS | N/A | **ADAPT** |

## Overall Verdict: ADOPT | ADAPT | AVOID

## Findings
| File | Check | Severity | Finding | Action |
|------|-------|----------|---------|--------|
| bar.md | Path | HIGH | Written to root docs/ not hummbl_governance/docs/research/ | Move file |
| bar.md | Claims | MEDIUM | 3 bare statistics without sources | Add [ESTIMATE] tags or URL |

## AIP Impact
- Clean-session criteria met: YES / NO
- AIP streak delta: +0 / +1 / RESET (reason if reset)

## Recommended Actions
1. <action 1>
2. <action 2>

## Next Actions
- If ADOPT: cherry-pick or merge directly
- If ADAPT: see Findings table for required fixes; re-run [gemini-audit] after fixes
- If AVOID: post BLOCKED to bus, reject PR, document in AIP history
```

## Post-Audit Actions

### ADOPT
- Cherry-pick or merge the branch/stash
- Post STATUS to bus: `gemini-audit ADOPT: <branch> — <summary>`
- AIP streak: +1 toward clean-session criteria (if all 5 criteria met)

### ADAPT
- Fix findings in a `feat/claude/review-<task>` branch (never commit directly to `feat/gemini/*`)
- Re-run `[gemini-audit]` after fixes
- Post STATUS to bus with correction summary
- AIP streak: not incremented (Gemini's work required correction)

### AVOID
- Do NOT merge or cherry-pick
- Post BLOCKED to bus: `gemini-audit AVOID: <branch> — <reason>`
- Document in AIP history (`gemini-guardrails.md` violation log)
- AIP streak: RESET to 0

## AIP Clean-Session Gate

For a session to count toward the AIP clean streak (3/3 required for scope expansion), ALL must pass:
1. Zero path errors (files in `hummbl_governance/docs/research/`, not root `docs/research/`)
2. Zero unsourced statistics (every number has a link or `[ESTIMATE: basis]` flag)
3. Zero canonicality errors (`_state`, untracked files, transcripts not presented as canonical)
4. Docs/research-only deliverables by default (no code without explicit approval)
5. Closeout packet with artifact paths, exact sources, open questions, tests-run status

Current AIP streak is shown in Live Context above.

## Reference

- Full criteria and historical incidents: `hummbl_governance/playbooks/GEMINI_AUDIT.md`
- Guardrails: `~/.agents/rules/gemini-guardrails.md`
- Stash recovery: `hummbl_governance/playbooks/STASH_RECOVERY.md`
- Feedback: `$RUNTIME_MEM/feedback_gemini_stash_review.md` (resolve via `~/.agents/scripts/resolve-memory.sh`)
