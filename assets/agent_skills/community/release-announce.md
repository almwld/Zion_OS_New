---
name: release-announce
description: Draft release announcement across channels -- GitHub release notes, blog post, social media, newsletter
version: 0.1.0
execution-mode: advisory
argument-hint: "<version> [--channels github|blog|social|email|all]"
category: backend-infra
status: candidate
---
# Release Announce

Draft a release announcement tailored for multiple distribution channels from a single version tag. Generates channel-appropriate content: technical release notes for GitHub, narrative blog post, character-limited social posts, and newsletter blurb.

## When to Use
- After tagging a new release and wanting to announce it
- When launching a new feature that deserves multi-channel publicity
- When coordinating a release across developer and non-developer audiences
- After `[tag-release]` to follow through with communications

## Execution
1. Parse `$ARGUMENTS` for version and channels (default: all)
2. Pull changelog from git log or `[release-notes]` output for the specified version
3. Identify key highlights: new features, breaking changes, notable fixes
4. For `github`: generate structured release notes with categories and migration notes
5. For `blog`: draft a narrative post with context, highlights, and call to action
6. For `social`: generate platform-specific posts (Twitter/X: 280 chars, LinkedIn: longer form)
7. For `email`: draft a newsletter-ready announcement blurb
8. Include relevant links (docs, migration guide, changelog)

## Output Format
```
Release Announce | v<version>
===============================

## GitHub Release Notes
<markdown formatted release notes>

## Blog Post Draft
Title: ...
<narrative content>

## Social Posts
### Twitter/X (280 chars)
<post>

### LinkedIn
<post>

## Newsletter Blurb
<email-ready paragraph>

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Release was just tagged | `[tag-release]` was the predecessor |
| Social posts ready to publish | `[social-post]` for platform-specific formatting |
| Newsletter ready to submit | `[newsletter-submit]` to distribute |
| Blog post needs a draft | `[blog-draft]` for full blog content (if available) |
