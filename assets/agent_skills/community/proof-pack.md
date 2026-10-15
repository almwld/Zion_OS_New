---
name: proof-pack
description: Bundle resume, case study, demo recording, and evidence into a job application submission pack
version: 1.0.0
execution-mode: advisory
argument-hint: "<target-company> [--role platform-engineer|ai-safety|sre]"
category: sales-marketing
status: candidate
---
# Proof Pack

Generate a complete job application submission pack. Inventories all artifacts, identifies gaps, calculates completeness, and generates an index for the target company and role.

## Arguments
- `<target-company>` — Company name (e.g., anthropic, modal, grafana)
- `--role <type>` — Role type: platform-engineer, ai-safety, sre, ai-platform (default: platform-engineer)
- `--check` — Inventory only, do not generate new files

## Procedure

### 1. Inventory Existing Artifacts

Scan the proof pack source directories:

```bash
PROFILE="$PROJECT_ROOT/profile"  # Adjust to your profile/resume directory

# Resume materials
ls -la "$PROFILE"/resume/ 2>/dev/null
ls -la "$PROFILE"[RESUME_BULLETS].md 2>/dev/null

# Cover letters
ls -la "$PROFILE"/cover-letters/ 2>/dev/null
ls -la "$PROFILE"[COVER_LETTERS].md 2>/dev/null

# Case studies
ls -la "$PROFILE"/case-studies/ 2>/dev/null
ls -la "$PROFILE"/promotion/ 2>/dev/null

# Demo recordings
ls -la "$PROFILE"/demos/ 2>/dev/null
ls -la "$PROFILE"/recordings/ 2>/dev/null

# One-pager
ls -la "$PROFILE"[one-pager]* 2>/dev/null
ls -la "$PROFILE"/promotion/ONE_PAGER*.md 2>/dev/null

# Job hunt tracker
ls -la "$PROFILE"/job-hunt/tracker.csv 2>/dev/null
```

### 2. Check Each Required Artifact

For the target role, verify presence and freshness:

| Artifact | Required | Path Pattern | Status |
|----------|----------|-------------|--------|
| Resume (PDF) | YES | `resume/*.pdf` or `resume.pdf` | FOUND/MISSING |
| Resume bullets (tailored) | YES | `RESUME_BULLETS.md` | FOUND/MISSING |
| Cover letter (generic) | YES | `cover-letters/generic.md` or `COVER_LETTERS.md` | FOUND/MISSING |
| Cover letter (company-specific) | RECOMMENDED | `cover-letters/<company>.md` | FOUND/MISSING |
| Case study (governance) | YES | `case-studies/governance*.md` | FOUND/MISSING |
| Case study (swarm/orchestration) | RECOMMENDED | `case-studies/swarm*.md` | FOUND/MISSING |
| Demo recording | RECOMMENDED | `demos/*.mp4` or `recordings/` | FOUND/MISSING |
| One-pager PDF | RECOMMENDED | `one-pager*.pdf` | FOUND/MISSING |
| GitHub profile | CHECK | Verify GitHub org has pinned repos | CHECK |
| Portfolio links | CHECK | `promotion/PORTFOLIO_LINKS.md` | FOUND/MISSING |

### 3. Role-Specific Requirements

**Platform Engineer**: Infrastructure case study, CI/CD evidence, multi-machine orchestration
**AI Safety**: Governance framework evidence, guardrail implementations, NIST/ISO mapping
**SRE**: Monitoring dashboards, incident response, health probes, circuit breakers
**AI Platform**: Model orchestration, agent coordination, cost governance

For each role, flag which case studies and evidence are most relevant.

### 4. Freshness Check

```bash
# Check file modification dates
for f in $(find "$PROFILE" -name "*.md" -o -name "*.pdf" -o -name "*.mp4"); do
  stat -f "%Sm %N" -t "%Y-%m-%d" "$f"
done
```

Flag any artifact older than 30 days as STALE.

### 5. Completeness Score

Calculate:
- Required artifacts found / total required = **Core %**
- Recommended artifacts found / total recommended = **Extended %**
- Composite = (Core * 0.7) + (Extended * 0.3) = **Total %**

### 6. Generate Index

Create `$PROFILE/proof-packs/<company>-<role>/INDEX.md`:

```markdown
# Proof Pack: <Company> — <Role>
Generated: <date>

## Artifacts
| # | Artifact | Status | Path | Last Updated |
|---|----------|--------|------|-------------|
| 1 | Resume PDF | FOUND | resume/reuben-bowlby-2026.pdf | 2026-03-25 |
| 2 | Cover Letter | MISSING | — | — |
| ...

## Completeness
- Core: <N>/<total> (<X>%)
- Extended: <N>/<total> (<X>%)
- Composite: <X>%

## Gaps to Fill
1. <artifact> — <action to create it>
2. <artifact> — <action to create it>

## Submission Checklist
- [ ] Customize cover letter for <company>
- [ ] Verify resume PDF is current
- [ ] Check GitHub pinned repos are A-grade
- [ ] Record demo if missing
- [ ] Submit via <platform>
```

## Output Format

```
Proof Pack | <company> | <role>

Artifact Inventory:
  [x] Resume PDF              resume/your-name-2026.pdf           (date)
  [x] Resume bullets          RESUME_BULLETS.md                   (date)
  [x] Cover letter (generic)  COVER_LETTERS.md                    (date)
  [ ] Cover letter (company)  MISSING — needs drafting
  [x] Case study              case-studies/example.md             (date)
  [ ] Demo recording          MISSING — not yet recorded
  [ ] One-pager PDF           MISSING — not yet created

Completeness:
  Core:     4/5 (80%)
  Extended: 2/5 (40%)
  Composite: 68%

Gaps (priority order):
  1. Company-specific cover letter — draft with `[proposal-write]` patterns
  2. One-pager PDF — generate with `[docgen]`
  3. Demo recording — record with `[demo-record]`

Index written to: $PROFILE/proof-packs/<company>/INDEX.md

Next action: Draft cover letter for <company>, then complete remaining gaps
```

## Notes

- Never commit proof packs to public repos (contains personal info)
- Resume PDF should be in a private profile directory
- Some companies require candidates to draft first, AI refines -- check application instructions
- Track submission in your job tracker via `[job-hunt]`

## Skill Chains

| After completing... | Consider... |
|---|---|
| Gaps identified | `[docgen]` (generate PDFs), `[demo-record]` (record demo) |
| Pack complete | `[job-hunt]` (track submission), `[send-email]` (submit) |
| Multiple companies | Run per company to customize, share core artifacts |
| Post-submission | `[follow-up]` (7-day check), `[job-hunt]` (update tracker) |
