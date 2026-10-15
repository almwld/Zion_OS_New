---
name: social-post
description: Draft platform-specific social posts from content with character limits and conventions
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<topic_or_url> [--platform linkedin|twitter|mastodon|all] [--tone professional|casual]"
category: sales-marketing
status: candidate
---
# social-post | Platform-Specific Social Drafting

## When to Use
- After shipping a feature, release, or blog post
- Amplifying newsletter acceptance or conference talk
- Sharing project milestones (test count, PyPI publish, partner app)
- Building consistent presence across platforms

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=social-post] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Parse Content Source
- `$ARGUMENTS`: topic description, URL, or file path
- If URL: fetch and extract key points
- If file: read and summarize
- `--tone`: professional (default for LinkedIn), casual (default for Twitter/Mastodon)

### 2. Supadata Content Fetch
For posts that reference external content, enrich with Supadata:

```bash
export SUPADATA_API_KEY="$(cat ~/supadata\ api.txt | grep sd_)"
# Fetch the article/source you're amplifying
python3 ~/bin/supadata.py scrape "<article-url>"
# Get video metadata for shareable hooks (title, description, engagement stats)
python3 ~/bin/supadata.py metadata "https://youtube.com/watch?v=..."
# Scrape trending topics or competitor posts for hook inspiration
python3 ~/bin/supadata.py scrape "https://news.ycombinator.com"
```

### 3. Platform Constraints

| Platform  | Char Limit | Hashtags | Links   | Media   | Tone Default   |
|-----------|-----------|----------|---------|---------|----------------|
| LinkedIn  | 3,000     | 3-5      | In body | Images  | Professional   |
| X/Twitter | 280       | 2-3      | Counts  | Images  | Casual/punchy  |
| Mastodon  | 500       | 3-5      | No cost | Images  | Technical      |

### 3. Draft Posts

**LinkedIn template:**
```
[Hook line - problem or insight]

[2-3 sentences expanding on the value]

[Key metric or proof point]

[Call to action: link, comment prompt, or share request]

[3-5 hashtags]
```

**X/Twitter template:**
```
[Hook - 1 sentence, under 200 chars to leave room]

[link]

[2-3 hashtags]
```

**Mastodon template:**
```
[Technical hook]

[2-3 sentences with more detail than Twitter]

[link]

[hashtags - Mastodon culture favors CamelCase tags]
```

### 4. Hashtag Research
Suggest relevant hashtags per platform:
- Always include: #Python, #OpenSource (if applicable)
- Topic-specific: #AIGovernance, #MLOps, #DevTools
- Trending: check if any current events align

### 5. Quality Checks
- Character count within limits
- No broken URLs
- Tone matches platform norms
- No confidential information leaked
- CTA is clear and actionable

## Output Format

```
social-post | <topic>

## LinkedIn (2,847 / 3,000 chars)
---
[Full post text here]
---

## X/Twitter (267 / 280 chars)
---
[Full post text here]
---

## Mastodon (412 / 500 chars)
---
[Full post text here]
---

## Posting Checklist
- [ ] Review and personalize each draft
- [ ] Add image/screenshot if available
- [ ] Schedule or post during peak hours (Tue-Thu 9-11am)
- [ ] Cross-link between platforms if posting to all
```

## Skill Chains

### Mandatory

- `[content-review]` MUST pass before posting to any external platform (LinkedIn, X/Twitter, Mastodon). Drafts may be generated without it, but no external posting without a passed content review.

### Advisory

- Before posting → `[seo-check]` on linked content
- After posting → track engagement in `_state/marketing/social.tsv`
- Need content first → `[case-study]` or `[newsletter-submit]`

## Authority

- **T1 (TRUSTED)**: Full run — draft and post (with `[content-review]` pass)
- **T2 (Active/High)**: Draft and post with `[content-review]` pass
- **T3 (Medium)**: Draft only; posting requires operator approval + `[content-review]` pass
- **T4 (Probationary)**: BLOCKED — may not draft or post social content
- **Operator**: Override any restriction
