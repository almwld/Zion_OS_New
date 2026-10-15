# Zion Super Agent Skills

This directory vendors six workflow skills from [obra/superpowers](https://github.com/obra/superpowers), an MIT-licensed open-source agent skills framework. The original Markdown skill files are retained with their frontmatter. The upstream MIT license is included as `LICENSE`.

## Included skills

- `systematic-debugging.md` — evidence-based root-cause analysis.
- `test-driven-development.md` — test-first feature and bug-fix workflow.
- `verification-before-completion.md` — fresh verification before success claims.
- `writing-plans.md` — actionable multi-step plans.
- `brainstorming.md` — structured design exploration.
- `executing-plans.md` — incremental execution and evidence-based recovery.

## Runtime integration

Zion's local-model planner ranks these files by task relevance and injects only a bounded excerpt into its prompt. Skills are guidance, not executable plugins: the loader does not run code from skill files, and a skill cannot grant tool permissions or bypass the runtime policy.

## Attribution

Upstream project: https://github.com/obra/superpowers  
License: MIT; see `LICENSE`.  
The skill text remains upstream-authored and is included with attribution and the required license notice.
