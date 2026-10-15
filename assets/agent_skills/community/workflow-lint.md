---
name: workflow-lint
description: Lint CI/CD workflows for anti-patterns, security issues, deprecated actions, and efficiency improvements
version: 0.1.0
execution-mode: remedial
argument-hint: "[PATH] [--fix] [--checks security|performance|deprecation|all]"
category: backend-infra
status: candidate
---
# Workflow Lint

Lint GitHub Actions workflow YAML files for common anti-patterns, security vulnerabilities, deprecated actions, and efficiency improvements. Scans `.github/workflows/` by default or a specific file. Can suggest fixes inline or generate a patch.

## When to Use
- Before merging a PR that adds or modifies CI/CD workflows
- Periodic audit of all workflows for security and efficiency
- After GitHub Actions announces action version deprecations
- When CI is slow and you want to find optimization opportunities

## Execution
1. Parse `$ARGUMENTS` for path (default: `.github/workflows/`), fix mode (default: false), and check categories (default: `all`).
2. Read all `.yml` and `.yaml` files in the target path.
3. Run checks by category:
   - **security**:
     - Actions pinned to SHA vs mutable tag (e.g., `@v4` vs `@abc123`).
     - Overly broad `permissions` (should be least-privilege).
     - Secrets used in `run` steps without masking.
     - `pull_request_target` with checkout of PR head (code injection risk).
     - Third-party actions from untrusted sources.
   - **performance**:
     - Missing cache steps for package managers (pip, npm, cargo).
     - Redundant checkout or setup steps across jobs.
     - Jobs that could run in parallel but are sequential.
     - Large matrix builds that could use `fail-fast`.
   - **deprecation**:
     - Actions using deprecated runner images.
     - `set-output` command (deprecated in favor of `$GITHUB_OUTPUT`).
     - `save-state` command (deprecated in favor of `$GITHUB_STATE`).
     - Node.js 12/16 actions (should be Node.js 20).
   - **best-practices**:
     - Missing `timeout-minutes` on jobs.
     - Missing `concurrency` groups for deployment workflows.
     - Hardcoded versions instead of using inputs or vars.
     - Missing `if: always()` on cleanup/notification steps.
4. Score each workflow: issues found by severity (HIGH, MEDIUM, LOW).
5. If `--fix` is specified, generate corrected YAML with inline comments explaining changes.

## Output Format
```
Workflow Lint | path | checks

## Summary
- Workflows scanned: N
- Issues found: N (H: N, M: N, L: N)

## Results by Workflow
### {workflow_name}.yml
| Line | Severity | Category | Issue | Fix |
|------|---------|----------|-------|-----|
| {N} | {HIGH} | {security} | {description} | {suggested fix} |

## Top Issues
1. {Most impactful issue with fix}
2. {Second most impactful}
3. {Third most impactful}

## Patch (if --fix)
{diff of suggested changes}

Next action: {suggestion or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Finding CI issues | `[ci-monitor]` to check current run status |
| Discovering security problems | `[security-scan]` for broader security review |
| Finding deprecated actions | `[dep-update]` to plan action version bumps |
