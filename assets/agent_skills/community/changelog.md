---
name: changelog
description: Generate changelog between two refs using conventional commits.
version: 0.1.0
execution-mode: advisory
argument-hint: "<from-ref> [<to-ref>]"
category: dev-tools
status: candidate
---
# Changelog Command

Generate a Keep-a-Changelog formatted changelog between two git refs.

## Usage

```bash
[changelog] v0.2.0              # From v0.2.0 to HEAD
[changelog] v0.2.0 v0.3.0      # Between two tags
[changelog] abc1234             # From a specific commit to HEAD
```

## Execution

### 1. Get commits
```bash
git log --oneline --no-merges <from>..<to>
```
Default `<to>` is HEAD if not provided.

### 2. Categorize by conventional commit prefix

| Prefix | Category |
|--------|----------|
| `feat:` | Added |
| `fix:` | Fixed |
| `refactor:` | Changed |
| `perf:` | Changed |
| `docs:` | Documentation |
| `test:` | Testing |
| `chore:` | Maintenance |
| `security:` / `vuln:` | Security |
| `BREAKING CHANGE` | Breaking |
| *(other)* | Other |

### 3. Extract PR links
```bash
git log --oneline <from>..<to> | grep -o "#[0-9]*"
```

## Output Format

```
# Changelog: <from> → <to>
Generated: <YYYY-MM-DD>
Commits: N

## Breaking Changes
- <description> (#PR)

## Added
- <description> (#PR)

## Changed
- <description> (#PR)

## Fixed
- <description> (#PR)

## Security
- <description> (#PR)

## Maintenance
- <description> (#PR)
```

## Constraints

- Only include categories that have entries (omit empty sections).
- Do not fabricate commits -- always read from `git log`.
- If no conventional commit prefix, categorize as "Other".
- Include PR numbers where available.
