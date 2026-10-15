---
name: loc-report
description: Lines of code report by directory, language, and change velocity
version: 0.1.0
execution-mode: advisory
argument-hint: "[path] [--velocity] [--compare YYYY-MM-DD]"
category: backend-infra
status: candidate
---
# [loc-report]

## When to Use
- Sizing a project for estimation or audit
- Tracking codebase growth trends
- Comparing code vs test ratios
- Before architecture reviews to understand scale
- Investor/partner reporting on engineering output

## Execution

### 1. Line Count by Directory
```bash
# Python LOC (excluding blanks and comments)
find $PROJECT_ROOT/services/ -name "*.py" | xargs wc -l | sort -n | tail -20
find $PROJECT_ROOT/integrations/ -name "*.py" | xargs wc -l | sort -n | tail -10
find $PROJECT_ROOT/tests/ -name "*.py" | xargs wc -l | sort -n | tail -10
find $PROJECT_ROOT/cognition/ -name "*.py" | xargs wc -l | sort -n | tail -10
# Total
find your_project/ -name "*.py" | xargs wc -l | tail -1
```

### 2. Language Breakdown
```bash
# By file extension
find . -not -path "./.git/*" -not -path "./.venv/*" -not -path "./node_modules/*" \
  -type f \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.sh" -o -name "*.yaml" -o -name "*.json" -o -name "*.md" \) \
  | xargs wc -l 2>/dev/null | tail -1
# Use cloc if available
which cloc >/dev/null 2>&1 && cloc your_project/ --quiet || echo "cloc not installed, using wc"
```

### 3. Change Velocity (if --velocity)
```bash
# Lines changed per week (last 4 weeks)
for i in 0 1 2 3; do
  start=$((i+1)); end=$i
  echo "Week -$i: $(git diff --stat "HEAD@{$start weeks ago}" "HEAD@{$end weeks ago}" -- your_project/ 2>/dev/null | tail -1)"
done
# Most active files
git log --since="30 days ago" --name-only --pretty=format: -- your_project/ | sort | uniq -c | sort -rn | head -15
```

### 4. Historical Comparison (if --compare)
```bash
# Compare against a date
git stash list  # safety check
git log --before="$COMPARE_DATE" -1 --format="%H" | head -1
# Count at that commit vs now
```

## Output Format

```
LOC Report | <scope> | <date>
============================================

By Directory
------------
  Directory                  | Files | LOC    | % of Total
  ---------------------------|-------|--------|----------
  services/                  | 103   | 12,400 | 38%
  tests/                     | 242   |  9,800 | 30%
  cognition/                 |  19   |  3,200 | 10%
  integrations/              |  22   |  2,800 |  9%
  agents/                    |  15   |  1,900 |  6%
  dashboard/                 |  30   |  2,400 |  7%
  Total                      | 431   | 32,500 | 100%

By Language
-----------
  Python:      28,000 (86%)
  TypeScript:   2,400 (7%)
  Shell:          800 (3%)
  YAML/JSON:    1,300 (4%)

Ratios
------
  Code:Test ratio:     1:0.79 (services LOC vs test LOC)
  Avg file size:       75 lines
  Largest file:        services/scheduler.py (420 lines)

Velocity (last 4 weeks)
------------------------
  Week -0:  +1,200 / -300 = net +900
  Week -1:  +800  / -150 = net +650
  Week -2:  +2,100 / -400 = net +1,700
  Week -3:  +500  / -100 = net +400

Most Active Files (30 days)
---------------------------
  15 commits  services/scheduler.py
  12 commits  tests/test_acceptance.py
   9 commits  CLAUDE.md

Next action: <recommendation>
```

## Skill Chains
- After `[loc-report]` -> `[ci-monitor]` for quality-to-quantity correlation
- After `[loc-report] --velocity` -> `[changelog]` for what drove the changes
- After `[loc-report]` -> `[tech-debt]` if code:test ratio is poor
