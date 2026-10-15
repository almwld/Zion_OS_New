---
name: readability
description: Score content readability using Flesch-Kincaid and Gunning Fog metrics
version: 0.1.0
execution-mode: advisory
argument-hint: "<file_or_text> [--target-grade 8|10|12|college]"
category: data-science
status: candidate
---
# Readability

Score content readability using Flesch-Kincaid, Gunning Fog, and sentence complexity metrics. Suggest simplifications to hit a target reading level. Works on docs, blog posts, README files, and user-facing copy.

## When to Use
- Writing documentation for a broad audience
- Reviewing blog posts or marketing copy before publishing
- Ensuring error messages and UI text are clear
- Adapting technical content for non-technical readers

## Execution
1. Parse `$ARGUMENTS` for target content (required) and `--target-grade` (default: `10`)
2. Read the content from file path or use provided text
3. Compute metrics:
   - **Flesch-Kincaid Grade Level**: 0.39(words/sentences) + 11.8(syllables/words) - 15.59
   - **Gunning Fog Index**: 0.4[(words/sentences) + 100(complex_words/words)]
   - **Average sentence length** (words per sentence)
   - **Complex word ratio** (words with 3+ syllables, excluding common suffixes)
   - **Passive voice percentage**
4. Compare computed grade against `--target-grade`
5. Identify problem sentences: too long (>25 words), too complex (3+ clauses), passive voice, jargon-heavy
6. For each problem sentence, suggest a simplified rewrite
7. Compute overall readability verdict: ON_TARGET / TOO_COMPLEX / TOO_SIMPLE

## Output Format
```
Readability | {source} | target: grade {target}

Scores:
- Flesch-Kincaid Grade: {score}
- Gunning Fog Index: {score}
- Avg Sentence Length: {N} words
- Complex Word Ratio: {N}%
- Passive Voice: {N}%

Verdict: {ON_TARGET|TOO_COMPLEX|TOO_SIMPLE}

Problem Sentences ({N}):
1. Line {N}: "{sentence}" (grade {score})
   Suggestion: "{simplified}"

Summary: {overall assessment}

Next action: {recommendation}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Content simplified | `[content-review]` for final check |
| Writing blog post | `[blog-draft]` was the source |
| User-facing copy | `[ux-audit]` for full UX review |
