# Zion Super Agent Skills

Zion bundles the 15 workflow skills from [obra/superpowers](https://github.com/obra/superpowers), an MIT-licensed open-source agent skills framework. The upstream Markdown skill files and required MIT license are preserved.

## Runtime

- `AgentSkillLibrary` ranks skills by task relevance and injects only a bounded excerpt into the local-model planning prompt.
- The planner remains the source of the execution plan; skills provide procedural context and do not replace model-authored plans.
- Skill Markdown is inert guidance. It is never executed as code and cannot grant tool permissions, approve a protected action, or bypass Android root authorization.
- The bundled set is 15 skills, not 1,000. The broader 1,000+ and 2,600+ skill catalogs researched for future license-reviewed imports are documented in `UPSTREAM_CATALOG.md`.

## Included skill files

- `brainstorming.md`
- `diagnosing-superpowers.md`
- `dispatching-parallel-agents.md`
- `executing-plans.md`
- `finishing-a-development-branch.md`
- `receiving-code-review.md`
- `requesting-code-review.md`
- `subagent-driven-development.md`
- `systematic-debugging.md`
- `test-driven-development.md`
- `using-git-worktrees.md`
- `using-superpowers.md`
- `verification-before-completion.md`
- `writing-plans.md`
- `writing-skills.md`

## Attribution

Upstream project: https://github.com/obra/superpowers  
License: MIT; see `LICENSE`.  
The skills are loaded dynamically by relevance, rather than concatenated wholesale into every model prompt.
