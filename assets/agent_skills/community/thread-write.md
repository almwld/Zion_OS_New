---
name: thread-write
description: Write threaded content for X/Twitter or LinkedIn carousels with hook, body, CTA structure
version: 0.1.0
execution-mode: advisory
argument-hint: "<topic> [--platform x|linkedin] [--length 5|10|15]"
category: sales-marketing
status: candidate
---
# Thread Write

Write threaded social media content optimized for X/Twitter threads or LinkedIn carousel posts. Structures content with a hook, numbered body posts, and a closing CTA. Respects platform character limits and conventions.

## When to Use
- You want to turn a blog post or insight into a social media thread
- You need a LinkedIn carousel script with slide-by-slide content
- You want to share a technical walkthrough as a thread
- You need engagement-optimized social content with hook and CTA

## Execution
1. Parse `$ARGUMENTS` for topic, platform (x or linkedin), and thread length (default 5 posts)
2. Research topic from available context (docs, blog drafts, project data)
3. Write the hook post (attention-grabbing, question or bold claim)
4. Write body posts with one idea per post, numbered for clarity
5. Apply platform constraints:
   - X/Twitter: 280 chars per post, use line breaks strategically
   - LinkedIn: 3000 chars per post, use carousel slide format
6. Write closing CTA (follow, share, link, comment prompt)
7. Add hashtag suggestions (3-5 relevant, not spammy)

## Output Format
```
Thread Write | <topic> (<platform>, <N> posts)

## Thread

### 1/N (HOOK)
<hook post text>

### 2/N
<body post>

### 3/N
<body post>

### N/N (CTA)
<closing CTA post>

## Metadata
- Platform: <x|linkedin>
- Total posts: <N>
- Avg chars/post: <N>
- Hashtags: <list>
- Best posting time: <suggestion>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Thread from social post | `[social-post]` for the initial announcement |
| Thread needs review | `[content-review]` for accuracy and tone |
