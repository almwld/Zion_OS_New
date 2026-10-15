---
name: changelog-rss
description: Publish changelog as RSS/Atom feed for external subscribers
version: 1.0.0
execution-mode: advisory
argument-hint: "[--format rss|atom] [--output path] [--since tag|date]"
category: dev-tools
status: candidate
---
# Changelog RSS

Generate an Atom or RSS feed from git commit history using conventional commits. Produces valid XML consumable by feed readers, CI subscribers, and downstream integrators.

## Arguments
- `--format <rss|atom>` — Feed format (default: atom)
- `--output <path>` — Output file path (default: `feed.xml` in repo root)
- `--since <tag|date>` — Start point: a git tag or ISO date (default: last 30 days)
- `--repo <name>` — Repository display name (default: inferred from git remote)

## Procedure

### 1. Extract Commits

```bash
# Get repo metadata
REPO_NAME=$(basename -s .git $(git config --get remote.origin.url 2>/dev/null) || basename $(pwd))
REPO_URL=$(git config --get remote.origin.url 2>/dev/null | sed 's/\.git$//' | sed 's|git@github.com:|https://github.com/|')

# Extract commits since the reference point
git log --since="<since>" --format="COMMIT_SEP%n%H%n%an%n%ae%n%aI%n%s%n%b" --reverse
```

Parse each commit into: hash, author_name, author_email, date_iso, subject, body.

### 2. Categorize by Conventional Commit Type

Group commits:
- **Features** (`feat:`): New functionality
- **Fixes** (`fix:`): Bug fixes
- **Breaking** (`feat!:`, `fix!:`, `BREAKING CHANGE`): Breaking changes
- **Other** (`docs:`, `chore:`, `refactor:`, `test:`, `ci:`): Maintenance

### 3. Generate Feed XML

Use Python stdlib `xml.etree.ElementTree` to generate valid XML:

```bash
python3 -c "
import xml.etree.ElementTree as ET
import subprocess, sys, re
from datetime import datetime, timezone

repo_name = '${REPO_NAME}'
repo_url = '${REPO_URL}'
output = '${OUTPUT_PATH}'
since = '${SINCE}'

# Parse git log
result = subprocess.run(
    ['git', 'log', '--since=' + since, '--format=COMMIT_SEP%n%H%n%an%n%ae%n%aI%n%s%n%b', '--reverse'],
    capture_output=True, text=True
)

commits = []
for block in result.stdout.split('COMMIT_SEP\n'):
    block = block.strip()
    if not block:
        continue
    lines = block.split('\n', 5)
    if len(lines) < 5:
        continue
    commits.append({
        'hash': lines[0], 'author': lines[1], 'email': lines[2],
        'date': lines[3], 'subject': lines[4], 'body': lines[5] if len(lines) > 5 else ''
    })

# Build Atom feed
ns = 'http://www.w3.org/2005/Atom'
ET.register_namespace('', ns)
feed = ET.Element('{' + ns + '}feed')
ET.SubElement(feed, '{' + ns + '}title').text = f'{repo_name} Changelog'
ET.SubElement(feed, '{' + ns + '}id').text = repo_url or f'urn:{repo_name}'
link = ET.SubElement(feed, '{' + ns + '}link')
link.set('href', repo_url)
link.set('rel', 'alternate')
ET.SubElement(feed, '{' + ns + '}updated').text = datetime.now(timezone.utc).isoformat()
author_el = ET.SubElement(feed, '{' + ns + '}author')
ET.SubElement(author_el, '{' + ns + '}name').text = 'Changelog Generator'

for c in reversed(commits):
    entry = ET.SubElement(feed, '{' + ns + '}entry')
    ET.SubElement(entry, '{' + ns + '}title').text = c['subject']
    ET.SubElement(entry, '{' + ns + '}id').text = f\"{repo_url}/commit/{c['hash']}\" if repo_url else c['hash']
    ET.SubElement(entry, '{' + ns + '}updated').text = c['date']
    a = ET.SubElement(entry, '{' + ns + '}author')
    ET.SubElement(a, '{' + ns + '}name').text = c['author']
    ET.SubElement(a, '{' + ns + '}email').text = c['email']
    if c['body']:
        content = ET.SubElement(entry, '{' + ns + '}content')
        content.set('type', 'text')
        content.text = c['body'].strip()
    if repo_url:
        link = ET.SubElement(entry, '{' + ns + '}link')
        link.set('href', f\"{repo_url}/commit/{c['hash']}\")
        link.set('rel', 'alternate')

tree = ET.ElementTree(feed)
ET.indent(tree, space='  ')
tree.write(output, xml_declaration=True, encoding='unicode')
print(f'Wrote {len(commits)} entries to {output}')
"
```

### 4. Validate

```bash
python3 -c "
import xml.etree.ElementTree as ET
tree = ET.parse('${OUTPUT_PATH}')
entries = tree.findall('.//{http://www.w3.org/2005/Atom}entry')
print(f'Valid Atom feed: {len(entries)} entries')
"
```

## Output Format

```
Changelog RSS | <repo_name>

Source:    <repo_url>
Since:     <since>
Format:    Atom 1.0
Entries:   <N>

By type:
  feat:    <N>
  fix:     <N>
  docs:    <N>
  other:   <N>

Written to: <output_path>
Validation: PASS (valid Atom XML, <N> entries)

Next action: Deploy to web root or add to CI as post-release step
```

## Notes

- Atom is preferred over RSS 2.0 for richer metadata and proper date handling
- Feed is stdlib-only (xml.etree.ElementTree) -- no feedgen or lxml required
- Commit bodies become entry content; subjects become entry titles
- For public feeds, ensure the repo URL is correct (not SSH)

## Skill Chains

| After completing... | Consider... |
|---|---|
| Feed generated | Deploy to web root, add to CI |
| `[tag-release]` | Re-run `[changelog-rss]` to update feed |
| `[release-notes]` | Include feed URL in release notes |
