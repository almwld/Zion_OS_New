---
name: changelog-post
description: Turn a git changelog into a polished "What's New" blog post or social announcement
version: 0.1.0
execution-mode: advisory
argument-hint: "[--since TAG] [--format blog|social|email]"
category: dev-tools
status: candidate
---
# Changelog Post

Transform raw git changelog entries into polished, audience-friendly content. Generates a "What's New" blog post, social media announcement, or email update from conventional commits.

## When to Use
- You just tagged a release and want to announce it publicly
- You need to turn technical commits into user-facing release notes
- You want a social-ready summary of recent changes
- You need an email update for stakeholders about what shipped

## Execution
1. Parse `$ARGUMENTS` for `--since` tag/ref and output format (blog/social/email)
2. Run `git log --oneline` since the specified tag to collect commits
3. Group commits by type (feat, fix, refactor, docs, chore, test)
4. Filter out internal-only changes (chore, refactor) for external audiences
5. Rewrite commit messages into user-friendly language
6. Generate output in the requested format:
   - Blog: full post with intro, sections, code highlights
   - Social: thread-ready posts (see `[thread-write]` format)
   - Email: newsletter-style with highlights and links
7. Add version number, date, and contributor credits

## Output Format
```
Changelog Post | <version> (<format>)

## Header
Version: <version>
Date: <date>
Commits: <N> (since <tag>)

## Content
<formatted content based on --format>

## Contributors
- <name> (<N> commits)

## Raw Changelog (reference)
- feat: <description>
- fix: <description>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Post ready for social | `[social-post]` to draft platform announcements |
| Post ready for newsletter | `[newsletter-submit]` to submit |
| Need to email stakeholders | `[send-email]` to deliver |
