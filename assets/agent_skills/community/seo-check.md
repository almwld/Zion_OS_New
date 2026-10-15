---
name: seo-check
description: Audit page or README for SEO/GEO/AEO signals including meta, headings, schema, llms.txt
version: 0.1.0
execution-mode: advisory
argument-hint: "<file_or_url> [--geo] [--aeo] [--full]"
category: fleet-ops
status: candidate
---
# seo-check | SEO/GEO/AEO Audit

## When to Use
- Before publishing or updating a README
- Optimizing repo discoverability on GitHub and search engines
- Preparing content for AI-engine optimization (AEO/GEO)
- Verifying llms.txt presence and quality
- Pre-submission check before newsletter or awesome-list PR

## Execution

### 1. Load Content
- If file path: read directly (README.md, index.html)
- If URL: fetch and parse HTML/markdown
- Identify content type: README, landing page, documentation, blog post

### 2. SEO Signals Check

| Signal           | Check                                          | Weight |
|------------------|-------------------------------------------------|--------|
| Title/H1         | Present, under 60 chars, includes primary keyword | HIGH   |
| Meta description  | Present, 150-160 chars, includes keyword         | HIGH   |
| Heading hierarchy | H1 > H2 > H3, no skipped levels                 | MEDIUM |
| Keyword density   | Primary keyword in first 100 words               | MEDIUM |
| Internal links    | Links to related content/docs                    | LOW    |
| Image alt text    | All images have descriptive alt text             | LOW    |
| URL structure     | Clean, keyword-rich, no special chars            | LOW    |

### 3. GEO Signals Check (if --geo)
Generative Engine Optimization for AI-cited results:
- **Structured data**: FAQ sections, definition lists, tables
- **Authoritative claims**: citations, links to sources
- **Concise answers**: first paragraph answers "what is this?"
- **Entity clarity**: project name, author, category clearly stated
- **Freshness signals**: dates, version numbers, recent updates

### 4. AEO Signals Check (if --aeo)
AI Engine Optimization for LLM training data:
- **llms.txt**: present at repo root or site root
- **Machine-readable structure**: consistent markdown formatting
- **Unambiguous definitions**: clear "X is Y" statements
- **Example-rich**: code examples, usage patterns
- **FAQ section**: question-answer pairs for retrieval

### 5. Score Calculation
Score each signal 0-2 (missing, partial, complete).
Aggregate by category: SEO, GEO, AEO.
Letter grade: A (>85%), B (70-85%), C (55-70%), D (<55%).

## Output Format

```
seo-check | <target>

## Overall Score: B+ (78/100)
- SEO: 82/100 (A)
- GEO: 75/100 (B)
- AEO: 68/100 (C+)

## SEO Findings
| Signal           | Score | Detail                              |
|------------------|-------|-------------------------------------|
| Title/H1         | 2/2   | "your-package" -- clear, concise |
| Meta description  | 0/2   | MISSING                             |
| Heading hierarchy | 2/2   | Clean H1>H2>H3                     |
| Keyword density   | 1/2   | "governance" in para 2, should be para 1 |

## GEO Findings
| Signal           | Score | Detail                              |
|------------------|-------|-------------------------------------|
| FAQ section       | 0/2   | MISSING -- add FAQ for AI retrieval |
| Structured data   | 2/2   | Tables, lists, code blocks present  |

## AEO Findings
| Signal           | Score | Detail                              |
|------------------|-------|-------------------------------------|
| llms.txt          | 0/2   | MISSING at repo root                |
| Examples          | 2/2   | 3 code examples in README          |

## Priority Fixes
1. Add meta description (HIGH -- SEO)
2. Add FAQ section (HIGH -- GEO/AEO)
3. Add llms.txt (MEDIUM -- AEO)
4. Move primary keyword to first paragraph (LOW -- SEO)
```

## Skill Chains
- After fixes -> `[seo-check]` again to verify improvement
- Before submission -> `[newsletter-submit]` with passing score
- For social amplification -> `[social-post]`
