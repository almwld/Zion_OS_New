# Zion Super Agent Skills and Offline Knowledge

Zion currently bundles **24 skills**:
- **15 upstream workflow skills** from [obra/superpowers](https://github.com/obra/superpowers), preserving the upstream MIT license and attribution.
- **9 Zion-native skills** for local runtime discovery, Linux package inventory, PTY diagnostics, Flutter/CI repair, local-model planning, Android storage inventory, evidence-driven recovery, defensive network inventory, and safe Git recovery.

## Offline indexes

- `knowledge_index.json` contains **32 searchable operational knowledge entries** covering Kali/rootfs discovery, package managers, Android permissions, storage, PRoot, PTY, Flutter, GitHub Actions, local GGUF inference, recovery, cancellation, and release verification.
- Both indexes include English and Arabic search terms so Arabic tasks can retrieve relevant local guidance.
- `AgentSkillLibrary` and `AgentKnowledgeIndex` rank entries locally; the orchestrator injects only bounded relevant context to leave room for GGUF generation.
- The knowledge index is reference material. Live PTY output, exit codes, registered tool schemas, and actual runtime state remain authoritative.

## Runtime and trust model

- The local model remains the sole author of execution plans and recovery proposals. Invalid model output is reported rather than replaced with a guessed heuristic plan.
- Skill Markdown and knowledge records are inert context; they are never executed and cannot grant tool permissions, approve protected actions, or bypass Android root authorization.
- Upstream catalog listings are discovery sources, not proof that every listed skill is licensed or compatible for copying. Review individual source, license, provenance, and content before adding third-party skills.

## Zion-native skills

- `local-runtime-discovery.md`
- `linux-package-inventory.md`
- `pty-evidence-debugging.md`
- `flutter-ci-repair.md`
- `local-model-planning.md`
- `android-storage-inventory.md`
- `evidence-driven-recovery.md`
- `defensive-network-inventory.md`
- `git-safe-recovery.md`

## Attribution

Upstream project: https://github.com/obra/superpowers  
License for the upstream skills: MIT; see `LICENSE`. Zion-native skill documents are original Zion documentation.
