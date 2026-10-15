---
name: verification-discipline
description: 'Agent operating-discipline self-checks: verification vocabulary (spot-checked vs verified byte-for-byte), destructive-op gate (non-destructive first, cite forcing constraint), artifact-existence claims require creation receipts, PowerShell Write-Host vs Write-Output in collection-returning functions, Windows reserved names (NUL/CON/PRN/AUX) require \\?\ prefix for deletion, PID-scoped kills for helper browser processes (never taskkill /f /im when operator has live browser). Run before any backup/copy verification, before any destructive op, before any artifact-existence claim, when writing PowerShell that returns hashtables/arrays, before deleting files with device-like names, and before killing helper browser processes.'
version: 1.2.0
execution-mode: advisory
argument-hint: "[verify | destructive | artifact | powershell | reserved-names | browser-kill | all]"
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---
# [verification-discipline]

> Six self-checks that prevent the most common agent process errors. Each
> originated from a real failure mode. Run the relevant check before the
> action, not after.

## When to use

- **verify** — before reporting the result of any copy, backup, sync, or
  transfer. Determines what vocabulary you may use.
- **destructive** — before proposing or running any irreversible operation
  (`diskpart clean`, format, repartition, `rm -rf`, bulk delete, force-push,
  drop/truncate, overwriting files you didn't just create).
- **artifact** — before asserting to the operator, in a handoff, or in an
  AAR that a file/artifact exists or was written.
- **powershell** — when writing a PowerShell function that returns a
  hashtable, array, or other structured object.
- **reserved-names** — before deleting or moving a file named `NUL`, `CON`,
  `PRN`, `AUX`, `COM1-9`, or `LPT1-9` on Windows.
- **browser-kill** — before killing a helper browser process (Chrome, Edge,
  Firefox) spawned by the agent for WAF bypass, scraping, or CDP work.
- **all** — run every check; use at session close or before an AAR.

---

## Check 1 — Verification vocabulary (origin: 2026-08-08 USB backup AAR)

Two distinct claims. Never conflate them.

- **"integrity spot-checked"** = file counts match, total sizes match, and a
  sample of key files were hashed. Acceptable for quick confidence, NOT for
  authorizing data destruction.
- **"verified byte-for-byte"** = a full SHA-256 manifest of **every** file,
  source vs copy, with 0 missing / 0 extra / 0 size mismatch / 0 hash
  mismatch. This is the only claim that justifies destroying the source.

**Self-check before emitting a verification verdict:**
1. What check did I actually run? Name it precisely.
2. If the words "verified," "byte-perfect," or "byte-for-byte" appear, can I
   point at a per-file hash comparison (manifest CSV or equivalent)? If not,
   downgrade to "integrity spot-checked" and say what was checked.
3. Never let a spot-check authorize a destructive op on the source.

**Red flag**: "counts and sizes match, plus a few spot-checks" described as
"byte-perfect." That phrasing cost real risk on 2026-08-08.

---

## Check 2 — Destructive-op gate (origin: 2026-08-08 USB repurpose AAR)

Before any irreversible operation:

1. **Exhaust non-destructive alternatives first.** When presenting options
   for a task that has a destructive path, the non-destructive options appear
   FIRST. Destructive options are never the lead recommendation while a
   non-destructive path exists.
2. **If destruction is still needed, cite the specific constraint that
   forces it.** "Requires `clean` because X, Y, Z rule out preserve-in-place."
   Vague convenience ("simpler," "cleaner") is not a forcing constraint.
3. **Get explicit confirmation for that specific action.** A prior approval
   for the task does not extend to the destructive step.
4. **Verify target identity immediately before the op** (e.g., re-confirm
   disk number via `Get-Disk` right before `diskpart select disk`). Disk
   numbers and paths can shift between sessions.

**Self-check before proposing/running a destructive op:**
1. Is there a non-destructive way to achieve the goal? Have I presented it?
2. If destructive is required, what exact constraint rules out non-destructive?
3. Has the operator confirmed THIS specific destructive action (not just the task)?
4. Have I re-verified the target identity this turn?

**Red flag**: leading with "wipe and reformat as a single volume" when
preserve-partition was available and the relevant runbook warned the
format-filesystem choice was unverified. That happened on 2026-08-08.

---

## Check 3 — Artifact-existence claims require creation receipts (origin: 2026-08-08 AAR)

Do not assert a file/artifact exists or was written unless BOTH:
1. You issued the write/create tool call, AND
2. You verified with a filesystem check (`Test-Path`, `ls`, `Get-Item`) in
   the same turn.

A `<ref_file>` citation, a prose claim, or a plan to write it is **not** a
receipt. Stating an artifact exists is not the same as creating it.

**Self-check before any artifact-existence claim:**
1. Did I issue the create/write call? (Not just describe it.)
2. Did I `Test-Path` it this turn?
3. If either is no, create it now or retract the claim. Never leave a
   dangling reference for another agent/operator to find.

**Applies especially to**: handoff docs, AAR evidence sections, and any
message that tells the operator "I've written X to <path>."

**Red flag**: "Full inventory written to usb-inventory.md" when the file was
never created. Caught only because the AAR skill mandates evidence
verification. Without that, the dead reference would have propagated to
other agents.

---

## Check 4 — PowerShell Write-Host vs Write-Output (origin: 2026-08-08 verifier script bug)

A PowerShell function that returns a hashtable, array, or structured object
must use `Write-Host` for progress/debug output — never `Write-Output`.

`Write-Output` adds strings to the function's return pipeline. The caller
then receives `string[] + hashtable` instead of a hashtable, and methods
like `.ContainsKey` fail with "method not found." This wastes full long
runs (e.g., a 31 GB hash cycle) when the bug surfaces only at comparison
time.

**Self-check when writing a PowerShell function that returns structured data:**
1. Does the function use `Write-Output` anywhere in its body for progress?
2. If yes, replace with `Write-Host` (goes to console, not pipeline).
3. Only the final returned object should reach the pipeline.

**Fix pattern:**
```powershell
# WRONG — pollutes the return pipeline
function Build-Manifest($root) {
  $m = @{}
  # ... loop ...
  Write-Output "hashed $i files"   # <-- becomes part of the return value
  return $m
}

# RIGHT — progress to console only
function Build-Manifest($root) {
  $m = @{}
  # ... loop ...
  Write-Host "hashed $i files"     # <-- console only, return stays clean
  return $m
}
```

---

## Check 5 — Windows reserved names require `\\?\` prefix (origin: 2026-08-09 home dir cleanup)

Windows reserves these device names: `NUL`, `CON`, `PRN`, `AUX`, `COM1`-`COM9`,
`LPT1`-`LPT9`. Files or directories with these names **cannot** be deleted,
moved, or renamed via `Remove-Item`, `Move-Item`, or `del` — the Win32 API
interprets them as device handles, not filesystem paths.

**Symptom**: `Remove-Item $env:USERPROFILE\NUL` fails with "Cannot find path"
even though `Test-Path` returns true, or the file is visible in Explorer.

**Fix**: Use the `\\?\` prefix, which bypasses Win32 path normalization and
treats the name as a literal filesystem path:

```powershell
# WRONG — Win32 interprets NUL as the null device
Remove-Item $env:USERPROFILE\NUL          # "Cannot find path"

# RIGHT — \\?\ prefix forces literal path interpretation
[System.IO.File]::Delete('\\?\$env:USERPROFILE\NUL')
# For directories:
[System.IO.Directory]::Delete('\\?\$env:USERPROFILE\CON', $true)
```

**Self-check before deleting/moving a file with a suspicious name:**
1. Is the name one of `NUL`, `CON`, `PRN`, `AUX`, `COM1-9`, `LPT1-9`?
2. If yes, use `[System.IO.File]::Delete('\\?\...')` (or `::Move`) instead of
   `Remove-Item` / `Move-Item`.
3. Verify with `Test-Path` after the operation.

**Red flag**: `Remove-Item` failing on a file that `Test-Path` confirms exists,
with an error like "Cannot find path" — this is the reserved-name signature,
not a permissions issue. Don't retry with `-Force` or elevated shells; switch
to the `\\?\` prefix.

**Origin**: 2026-08-09 home directory cleanup found a file named `NUL` at root
(created by a redirected `> NUL` that wrote to a file instead of the device on
a misconfigured shell). `Remove-Item` failed; `[System.IO.File]::Delete('\\?\$env:USERPROFILE\NUL')` succeeded.

---

## Check 6 — PID-scoped kills for helper browser processes (origin: 2026-08-10 AAR)

When an agent spawns a helper browser (Chrome, Edge, Firefox) for WAF bypass,
scraping, or CDP work, that helper shares the process name with the operator's
live browser. A blanket process-name kill (`taskkill /f /im chrome.exe`,
`Stop-Process -Name chrome`) kills **all** instances — including the operator's
open tabs.

**Rule**: When terminating a helper browser process, use PID-scoped kills
(`Stop-Process -Id <pid>`), never process-name kills, when the operator may
have a live browser of the same name.

**Pattern**: Capture the helper PID at spawn time and kill only that PID at
cleanup.

```python
# RIGHT — capture PID at spawn, kill only that PID
proc = subprocess.Popen([CHROME, "--remote-debugging-port=9223", ...])
# ... do work ...
proc.terminate()      # kills only this instance
proc.wait()
```

```powershell
# WRONG — kills every chrome.exe on the machine
taskkill /f /im chrome.exe

# RIGHT — kill only the helper PID
Stop-Process -Id $helperPid
```

**Exception**: Blanket kills are acceptable only when the operator has
explicitly confirmed no live browser of that name is running, or when the
agent spawned the only instance on the machine.

**Self-check before killing a helper browser process:**
1. Do I have the helper's PID (from `subprocess.Popen().pid` or equivalent)?
2. Is the operator likely to have a live browser of the same name?
3. If yes to both, am I using `Stop-Process -Id <pid>` (not `-Name` or `taskkill /f /im`)?

**Red flag**: Reaching for `taskkill /f /im chrome.exe` to clear a stuck
headless instance when the operator has Chrome tabs open. This killed 28
processes on 2026-08-10, including the operator's live browser session.

---

## Running the checks

For a specific check, focus on that section. For `all`, walk Checks 1-6 in
order at session close or before an AAR and record any red flags. A red flag
found AFTER the action is still worth recording — it becomes an AAR Improve
and prevents the next session from repeating it.

These checks are advisory: they do not block tool calls. Their force comes
from being loaded and from the operator/AAR holding the agent to them.
