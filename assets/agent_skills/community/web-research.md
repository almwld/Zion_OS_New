---
name: web-research
description: Structured web research -- search, fetch, evaluate sources, synthesize findings.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"QUESTION\" [--depth quick|medium|deep]"
category: hummbl-research
status: candidate
---
# Web Research Command

Structured web research with source evaluation and uncertainty tracking.

## Execution

### 1. Frame the question
State the exact question. Identify what kind of answer is needed:
- **Factual**: Version number, release date, API endpoint
- **Comparative**: Product A vs Product B
- **Landscape**: What exists in category X?
- **Technical**: How does X work under the hood?

### 2. Search strategy
- **Quick** (1-2 searches): Direct factual lookups
- **Medium** (3-5 searches): Comparative or technical questions
- **Deep** (5+ searches, multiple agents): Landscape surveys or complex technical analysis

### 3. Source evaluation
Rate each source on the MTSMU source ladder:
1. Official docs / primary source
2. Source code / tests
3. Primary datasets
4. Secondary summaries (blog posts, articles)
5. Forum answers
6. Memory without verification

### 4. Synthesize
Produce findings with:
- **Evidence**: What sources directly support
- **Inference**: What you concluded beyond the sources (labeled clearly)
- **Uncertainty**: What remains unknown or contradictory
- **Confidence**: 0-100% for key claims

### 5. Persist (if valuable)
If findings are worth keeping:
- Save to `docs/research/` for project-relevant research
- Post to CLP ledger as `discovery` entry for cross-session value
- Update MEMORY.md if it changes our understanding of a tool/project

## Output Format
```
Web Research | "<question>"
════════════════════════════════

## Findings
<synthesized answer>

## Sources
1. <url> -- <what it supports> (reliability: high/medium/low)
2. ...

## Uncertainty
<what's still unknown or contradictory>

## Confidence: <X>%
```

## Tips
- For GitHub repos: check stars, last commit date, license, contributor count
- For products: check pricing page, changelog, and HN/Reddit threads
- For technical claims: prefer source code over marketing copy
- Always check temporal stability: when was this information last verified?
