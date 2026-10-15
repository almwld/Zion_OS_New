---
name: pty-evidence-debugging
description: Diagnose shell commands using actual PTY output, exit codes, and timeout state.
---
# PTY Evidence Debugging
1. Execute through the registered Zion PTY tool, not a simulated command runner.
2. Capture runtime, command, duration, combined output, and exit code.
3. Treat nonzero exit codes as failure even if output looks plausible.
4. For a timeout, interrupt first and wait for prompt recovery; restart the PTY only if the session remains stuck.
5. Ask the local model for a distinct repair based on the observed error, then execute and verify it.
Do not fabricate separate stdout/stderr when the PTY merges streams.