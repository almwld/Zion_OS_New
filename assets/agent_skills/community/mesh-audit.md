---
name: mesh-audit
description: Audit local .agents Git provenance, cleanliness, and alignment with origin/main without changing files or contacting fleet hosts.
version: 0.2.0
execution-mode: advisory
argument-hint: "[--status|--check]"
category: fleet-ops
status: candidate
---
# mesh-audit

Use this skill to determine whether the local `hummbl-io/agents` checkout is
clean and aligned with its locally available `origin/main` ref.

## Platform selection

On Linux and macOS, use the Bash commands below. On Windows, run the equivalent
Git commands in PowerShell from `$HOME\.agents`; the Bash compatibility scripts
require Git Bash and are not a native PowerShell interface.

## Commands

```bash
# Report repository, branch, HEAD, origin/main, dirty count, and ahead/behind
bash ~/.agents/scripts/mesh-audit.sh --status

# Fail unless the worktree is clean, attached, and exactly aligned
bash ~/.agents/scripts/mesh-audit.sh --check
```

These commands are read-only and do not fetch. If current remote state is
required, obtain explicit authority before running `git fetch origin`, then
repeat the audit.

### Auditing Workstation from another machine

Workstation is Windows and its SSH login shell is PowerShell, so the Bash script must
be reached through WSL with the full Windows-mounted path (WSL's `~` resolves
to the Linux home, not `~/`):

```bash
ssh -o ConnectTimeout=10 workstation "wsl bash /mnt/c/Users/Owner/.agents/scripts/mesh-audit.sh --status"
```

`ssh workstation "bash ~/.agents/scripts/mesh-audit.sh"` does not work for the same
reason. If the script uses Windows-style paths internally it may need
adaptation for WSL; test with `--status` first and check for path errors.

## Interpretation

- `dirty_entries > 0`: preserve local work and stop.
- `behind > 0`: an explicitly authorized `git pull --ff-only origin main` may
  be appropriate after verifying the worktree and branch.
- `ahead > 0`: preserve the work on a reviewed topic branch; do not overwrite
  or push directly to `main`.
- Both ahead and behind: history diverged; do not merge, rebase, reset, stash,
  or force automatically.
- Unexpected remote or detached HEAD: stop and request direction.

Filename counts are not proof of alignment. The audit uses commit provenance
because equal path listings can contain different file contents.

## Fleet scope

Run the audit locally on each active machine and compare commit hashes. GitHub
`hummbl-io/agents` is canonical. remote-node is dormant and is not audited or
synchronized until explicitly re-onboarded.

## Skill chains

### Mandatory

- Use `mesh-sync` for the reviewed topic-branch and fast-forward workflow.
- Obtain explicit repository, direction, path, and branch scope before any
  fetch, pull, commit, push, or bus post.

## Version

0.2.0 — 2026-09-05
