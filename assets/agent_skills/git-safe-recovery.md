---
name: git-safe-recovery
description: Recover repository work while preserving user changes and auditability.
---
# Git Safe Recovery
1. Inspect branch, status, diff, and recent history before changing files.
2. Preserve unrelated changes and avoid cleanup commands that discard work.
3. Prefer a narrow patch and regression test over broad rewrites.
4. Separate unrelated fixes into distinct commits with descriptive messages.
5. Verify the final diff and current commit before reporting or opening a PR.
Do not use reset --hard, clean -fd, or force-push as an automatic first response.