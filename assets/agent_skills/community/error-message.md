---
name: error-message
description: Audit and improve error messages for clarity and actionability
version: 0.1.0
execution-mode: advisory
argument-hint: "[PATH] [--action audit|improve] [--standard user|dev|api]"
category: dev-tools
status: candidate
---
# Error Message

Audit and improve error messages for clarity, actionability, and user-friendliness. Good error messages tell you what happened, why, and what to do about it. This skill finds messages that fall short.

## When to Use
- Reviewing error handling in a codebase
- After user complaints about confusing errors
- Before releasing a CLI tool or API
- Improving developer experience for internal tools

## Execution
1. Parse `$ARGUMENTS` for `PATH` (default: current repo), `--action` (default: `audit`), and `--standard` (default: `dev`)
2. Scan for error messages:
   - `raise` statements with string messages
   - `logging.error()` and `logging.warning()` calls
   - HTTP error responses (status codes + bodies)
   - CLI `sys.exit()` and `print(..., file=sys.stderr)` calls
   - User-facing error strings in UI components
3. Evaluate each message against the standard:
   - **user**: Must be jargon-free, explain what happened in plain language, suggest next steps
   - **dev**: Must include context (what operation, what input), be grep-able, suggest debugging steps
   - **api**: Must include error code, human-readable message, link to docs, and structured format
4. Score each message:
   - **Clear**: says what happened (not just "Error" or "Failed")
   - **Contextual**: includes relevant variable values or identifiers
   - **Actionable**: tells the reader what to do next
   - **Appropriate**: matches the audience (no stack traces for end users, no vague messages for devs)
5. If `--action improve`: rewrite each poor message with a suggested replacement
6. Compute overall error message quality score

## Output Format
```
Error Message Audit | {path} | standard: {standard}

Messages Scanned: {N}
Quality: {GOOD|FAIR|POOR} ({score}%)
- Clear: {percent}%
- Contextual: {percent}%
- Actionable: {percent}%

Worst Offenders:
1. {file}:{line}: "{message}"
   Issues: {not clear|no context|not actionable}
   Suggested: "{improved message}"

2. {file}:{line}: "{message}"
   ...

Next action: {recommendation}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Came from error catalog | `[error-catalog]` identified the errors |
| UX improvements needed | `[ux-audit]` for broader UX review |
| Fixes applied | `[commit]` to save improvements |
