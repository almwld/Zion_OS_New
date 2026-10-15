---
name: catalog-write
description: Orchestrate catalog-style research writeups — individual pieces first, index last, git-tracked from the start, with explicit cross-references. Auto-propose when a research session produces 10+ distinct concepts that each warrant individual writeups.
version: 0.1.1
status: tested
canonical_status: not_yet_global_canon
execution-mode: side_effecting
argument-hint: <topic> [--source <corpus-path>] [--count <N>] [--scaffold]
category: fleet-ops
---
# catalog-write

Orchestrates catalog-style research writeup projects: a corpus of individual
principle/concept writeups, a parent essay, and an index file — all
git-tracked from the first commit, with explicit cross-references between
related pieces.

## When to use

### Explicit invocation
- `[catalog-write] <topic>` — start a new catalog project
- `[catalog-write] --scaffold` — copy the scaffold directory to a target path

### Auto-propose (agent-initiated)
When a research session produces **10+ distinct concepts** that each warrant
individual writeups (not just bullet points in a single doc), the agent
should propose catalog mode:

> "This session has surfaced N distinct concepts that each warrant individual
> writeups. I recommend switching to catalog mode: individual files per
> concept, a parent essay, and an index. Shall I proceed with
> `[catalog-write]`?"

The operator must approve before catalog mode begins. Do not auto-start.

## Workflow

### Phase 1: Scope (Clarify)
Ask 2-3 clarifying questions:
- **Source corpus**: What research material feeds the catalog? (existing
  notes, session transcripts, web research, a book/paper)
- **Concept count**: How many distinct concepts? (estimate; can grow/shrink)
- **Target home**: Where do the files land? Default:
  `docs/research/<topic-slug>/` in the current repo. Must be git-tracked
  from the first commit.

### Phase 2: Scaffold (Copy structure)
```bash
cp -r skills/catalog-write/scaffold/ docs/research/<topic-slug>/
```
Renames placeholder files:
- `00-index.md.tpl` → `00-index.md`
- `NN-concept.md.tpl` → `01-<first-concept-slug>.md`, `02-<second>.md`, ...
- `parent-essay.md.tpl` → `parent-<topic-slug>.md`

### Phase 3: Write individuals first (NOT the index)
Write each concept file individually. Each file follows the scaffold
structure:
1. **The concept** (1-2 paragraphs — what it is, source lineage)
2. **The rule** (blockquoted — the actionable principle in 2-3 sentences)
3. **The mapping** (how it maps to the target domain — engineering, etc.)
4. **The tension** (where it conflicts with default/minimalist approaches)
5. **Related** (explicit cross-references to other files in the catalog)

**Do NOT write the index or parent essay yet.** Write all individual pieces
first. The index is written last because it depends on knowing the final
concept list, reading order, and cross-reference graph.

### Phase 4: Cross-references
After all individual files are written, add `## Related` sections to each
file. Build the cross-reference graph by identifying concept chains:
- Which concepts refine or extend each other?
- Which concepts are paired (twin principles)?
- Which concepts form a sequence (A enables B enables C)?

Each file should reference 2-5 related files. Use relative markdown links:
```
- [Concept Name](./NN-concept-slug.md)
```

### Phase 5: Index (last)
Write `00-index.md`:
- Table of contents with all files in reading order
- Reading order suggestions (chronological, by concept chain, by difficulty)
- Through-line: the single thesis that connects all concepts
- Brief description of each concept (1-2 sentences, not full writeups)

### Phase 6: Parent essay
Write the parent essay (`parent-<topic-slug>.md`):
- Frames the problem the catalog addresses
- Compares approaches (e.g., GPP vs SPP, ultra vs full)
- References the catalog directory and index, not individual files
- Stands alone as a readable essay

### Phase 7: Git track from the start
The target directory MUST be inside a git-tracked repo from the first commit.
**Do not write files to `~/docs/` or other untracked locations first.**

Commit pattern:
1. First commit: scaffold + first batch of individual files
2. Subsequent commits: remaining individual files
3. Final commit: cross-references + index + parent essay

Branch naming: `docs/<agent>/<topic-slug>` (e.g.,
`docs/devin/sct-principles-for-engineering`).

## Anti-patterns (learned from AAR 20260809-0450Z)

- **Writing a brief intermediate catalog in the parent doc, then superseding
  it with individual writeups.** The brief entries become redundant and
  require a cleanup rewrite. If you need approval before writing individuals,
  present the catalog in conversation, not in the file.
- **Writing the index before the individuals.** The index depends on the
  final concept list and cross-reference graph — write it last.
- **Writing to `~/docs/` without git tracking.** Research output with no git
  tracking is a data loss risk. Use `docs/research/<topic>/` in a tracked
  repo.
- **Inline-only cross-references.** Body-text references are buried in prose.
  Always add an explicit `## Related` section at the end of each file.
- **Uniform compression on all files.** Some concepts are simple (short
  file); others are complex (long file). Don't force equal length.

## Scaffold structure

```
scaffold/
  00-index.md.tpl          # Index template with TOC + reading order
  NN-concept.md.tpl        # Individual concept writeup template
  parent-essay.md.tpl      # Parent essay template
```

See `scaffold/` directory for the copyable templates.

## Output

A catalog directory containing:
- `00-index.md` — catalog index with TOC, reading order, through-line
- `01-<slug>.md` through `NN-<slug>.md` — individual concept writeups
- `parent-<topic-slug>.md` — parent essay framing the catalog

All files git-tracked, all with explicit `## Related` cross-references.

## Skill Chains

### Mandatory

- Obtain operator approval before starting catalog mode, use a git-tracked
  target repository, write individual concept files before the index or parent
  essay, and add explicit cross-references before finalizing the catalog.

## Authority

- **All agents:** May propose catalog mode. They may scaffold or write catalog
  files only after operator approval and only in a git-tracked target
  repository.
- **Operator:** May approve a scoped catalog project and its target repository.

## Triggers

- `[catalog-write] <topic>` — explicit start
- `[catalog-write] --scaffold <target-path>` — copy scaffold only
- Auto-propose when 10+ distinct concepts emerge from a research session
