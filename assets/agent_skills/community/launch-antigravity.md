---
name: launch-antigravity
description: Skill to launch the Antigravity desktop application on Windows host.
version: 0.1.0
execution-mode: advisory
argument-hint:
category: skills-meta
status: candidate
---
# Launch Antigravity Desktop App

This skill provides a convenient way to start the Antigravity desktop application.
It abstracts the underlying command needed to locate and execute the Antigravity executable,
ensuring the correct environment variables and guardrails are applied.

## When to Use
- When you need to open the Antigravity UI quickly from any agent context.
- When automating workflows that require user interaction via Antigravity.

## Execution Steps
1. Resolve the Antigravity installation directory. By default, it lives under:
   `$env:USERPROFILE\bin\Antigravity.exe`.
2. Verify that the executable exists.
3. Run the executable using a non-interactive shell (PowerShell) with the required guardrails:
   ```powershell
   & "$env:USERPROFILE\bin\Antigravity.exe" --no-interactive-shell
   ```
   The `--no-interactive-shell` flag disables `tools.shell.enableInteractiveShell`
   to avoid crashes in headless sessions.
4. Return a success/failure status.

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Antigravity launched | `[bus]` to post a STATUS message |

The skill is advisory; it will suggest the command and ask for confirmation before execution.
