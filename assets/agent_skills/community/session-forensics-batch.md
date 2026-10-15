---
name: session-forensics-batch
description: >-
  Summarize all agent sessions in a time window (default 48h) with message
  counts, tool calls, errors, file ops, token usage, and duration. Produces
  a compact table for triage and identifies flagged sessions for deep
  forensic audit. Supports all 12 agent providers via session-forensics.
  Use when the user says "audit recent sessions", "summarize all sessions",
  "what happened across sessions", "batch forensics", or wants a fleet-wide
  session overview before deep-diving into individual sessions.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--hours <N>] [--agent <name>]"
category: fleet-ops
status: candidate
---

# Session Forensics Batch

Summarize all agent sessions in a time window for rapid triage. Identifies
high-activity, error-heavy, and anomalous sessions for deep forensic audit.

## When to Use

- Before deep-diving into individual sessions — get the fleet-wide picture first
- When the user asks "what happened across all sessions" or "audit recent sessions"
- As a triage step before running `session-forensics` on specific sessions
- After a burst of agent activity to identify which sessions warrant review

## Execution

### 1. List sessions in the time window

```bash
APPDATA="$HOME/.local/share" python ~/.agents/skills/session-forensics/scripts/session_forensics.py --list --agent devin
```

Filter by mtime for the time window (default 48h):

```bash
find ~/.local/share/devin/cli/transcripts/ -name "*.json" -mmin -2880 -printf "%T+ %f\n" | sort
```

### 2. Extract summary metrics for each session

For each transcript, parse the ATIF-v1.7 format:
- `schema_version`, `session_id`, `agent`, `steps`, `final_metrics`
- Each step has: `step_id`, `timestamp`, `source` (system/user/agent), `message`, `tool_calls`, `observation`, `metrics`
- `tool_calls` is a list of `{tool_call_id, function_name, arguments}`
- `observation.results` contains tool output with `content` and exit codes
- `final_metrics` has `total_prompt_tokens`, `total_completion_tokens`, `total_cached_tokens`, `total_steps`

### 3. Produce summary table

For each session extract:
- **Session ID** (filename stem)
- **Start time** (first step timestamp)
- **Duration** (last - first timestamp)
- **Steps** (len(steps))
- **Tool calls** (count of tool_calls across all steps)
- **Shell cmds** (exec tool calls)
- **File ops** (write + edit tool calls)
- **Errors** (non-zero exit codes in observation results + tracebacks)
- **Tokens** (prompt + completion from final_metrics, in thousands)
- **Size** (file size in KB)
- **Title** (first user message, truncated to 50 chars)

### 4. Flag sessions for deep audit

Flag sessions that meet any criteria:
- Errors > 3 (real errors only — exclude conversation-summary messages)
- Destructive operations (see classification below)
- File ops > 40 (high modification volume)
- Duration > 5h (long sessions may have drift)
- Tool calls > 150 (high activity)

#### Destructive operation classification

Not all flagged patterns are equal. Classify by risk:

**Dangerous (always flag):**
- `git push --force` or `git push -f` (without `--force-with-lease`)
- `git reset --hard` on shared repos (`~/.agents`, `/work/active/*`)
- `git checkout -- .` on shared repos (discards uncommitted tracked-file edits)
- `git stash drop` (unrecoverable)
- `rm -rf` outside `/tmp/` or temp dirs

**Safe destructive (log but don't alarm):**
- `git push --force-with-lease` (fails if remote has unexpected commits)
- `--no-verify` on agent-node (WDAC policy blocks pre-commit hooks — AGENTS.md sanctioned)
- `rm -rf /tmp/*` (routine temp cleanup)
- `git stash drop` of a rebase auto-stash (created by `git rebase`, safe to drop)

**Not destructive (do not flag):**
- `git push` without `--force` or `-f` flag (normal push)
- `git push --force-with-lease` (safe variant)
- Bus post message text containing "rm" or "reset" (not a shell command)

**Important:** Only scan `exec`/`bash`/`shell` tool call arguments for
destructive patterns. Do NOT scan bus post message text, file contents,
or conversation messages — these produce false positives. (Origin:
2026-09-05 forensic audit — 31 of 36 flagged destructive ops were false
positives from bus post text and non-force pushes.)

**Error false-positive guard:** Exclude messages with `source: message`
and `role: user` that contain conversation-summary markers
("Conversation to summarize:", "=== MESSAGE 0 -", "<summary>").
These are narrative summaries, not errors. (Origin: 2026-09-05 forensic
audit — 18 of 18 "errors" in ionian-addition were conversation summaries.)

### 5. Report aggregate stats

- Total sessions, total tool calls, total shell cmds, total file ops, total errors, total tokens
- Cache hit rate (cached_tokens / prompt_tokens)

## Output Format

```
Session Forensics Batch | <N> sessions | last <H>h
══════════════════════════════════════════════════════════════════════
Session ID              Start     Dur   Steps  Tools  Sh  Files  Err  TokK  KB  Title
─────────────────────────────────────────────────────────────────────────────────────
<session-id>            <HH:MM>   <Xh>  <NN>   <NN>   <N>  <NN>   <N>  <NN>  <N>  <title>
...

Aggregate: <N> tool calls, <N> shell cmds, <N> file ops, <N> errors, <N>K tokens

--- Flagged sessions (<N>) ---
  <session-id>: <reason>
```

## Cross-References

- Deep audit: `session-forensics` on individual flagged sessions
- Cross-session patterns: `cross-session-learnings`
- Act on recommendations: `forensic-recommendations`

## Auto-Generate Manifests for Flagged Sessions

After identifying flagged sessions, auto-generate forensic manifests for
durable audit artifacts. Manifests survive session cleanup and provide
a permanent record of what happened.

```bash
mkdir -p /tmp/forensic-manifests
for sid in $FLAGGED_SESSIONS; do
  APPDATA="$HOME/.local/share" python ~/.agents/skills/session-forensics/scripts/session_forensics.py \
    --manifest --manifest-out /tmp/forensic-manifests/$sid-manifest.md "$sid" 2>/dev/null
done
echo "Generated $(ls /tmp/forensic-manifests/*.md 2>/dev/null | wc -l) manifest(s) in /tmp/forensic-manifests/"
```

Manifests include: session metadata, tool frequency, file operations,
shell commands, errors, timeline, token usage, governance classification,
and forensic self-check. They are governance-compliant audit artifacts
that can be archived or attached to bus posts. (Origin: 2026-09-05
forensic audit — manifests were available but not used, losing durable
audit evidence for the 6 flagged sessions.)

## Cross-Session Destructive-Op Correlation

After running deep audits on flagged sessions, correlate destructive
operations across sessions to identify patterns that individual session
audits miss. Individually, a `git reset --hard` looks like an isolated
incident; correlated across sessions, it may reveal a systemic pattern
of agents using a repo as scratch space and then nuking it.

```bash
# Collect all destructive ops from flagged sessions, grouped by repo
for sid in $FLAGGED_SESSIONS; do
  APPDATA="$HOME/.local/share" python ~/.agents/skills/session-forensics/scripts/session_forensics.py \
    --json "$sid" 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
tcs = d.get('tool_calls', [])
for tc in tcs:
    if not isinstance(tc, dict): continue
    fn = tc.get('function_name','') or tc.get('tool','')
    args = tc.get('arguments',{}) or tc.get('args',{})
    if isinstance(args, str):
        try: args = json.loads(args)
        except: args = {}
    cmd = args.get('command','') if isinstance(args, dict) else ''
    if isinstance(cmd, str) and any(p in cmd for p in ['reset --hard','checkout -- .','push --force','rm -rf']):
        # Extract repo path from cd commands
        import re
        cd_match = re.search(r'cd\s+(\S+)', cmd)
        repo = cd_match.group(1) if cd_match else 'unknown'
        print(f'$sid\t{repo}\t{cmd[:80]}')
" 2>/dev/null
done | sort -t$'\t' -k2 | awk -F'\t' '
  { repos[$2]++; sessions[$2] = sessions[$2] " " $1 }
  END {
    print "Cross-session destructive-op patterns:"
    for (repo in repos) {
      printf "  %s: %d ops across sessions [%s]\n", repo, repos[repo], sessions[repo]
    }
  }'
```

**Classification:**
- Same repo, multiple sessions, within 24h → **pattern** (agents treating
  repo as scratch space — add guardrails)
- Same repo, multiple sessions, >24h apart → **coincidence** (likely
  independent recoveries)
- `/tmp/*` only → **routine cleanup** (no concern)
- `~/.agents` or `/work/active/*` → **investigate** (shared repo, risk of
  concurrent-agent work loss)

(Origin: 2026-09-05 forensic audit — `shared-humor` and
`ambitious-cilantro` both ran destructive git ops on `~/.agents` within
24h. Individually they looked like isolated incidents; correlated they
revealed a pattern of agents nuking `~/.agents` to recover from bad
rebases, risking other agents' uncommitted work.)
