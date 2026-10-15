---
name: cli-design
description: Design CLI interfaces with consistent flags, help text, and subcommands
version: 0.1.0
execution-mode: advisory
argument-hint: "<command_name> [--style posix|git|click]"
category: dev-tools
status: candidate
---
# CLI Design

Design CLI interfaces with consistent flags, help text, subcommands, and examples following established conventions. Produces a specification that can be directly implemented with argparse, click, or similar.

## When to Use
- Designing a new command-line tool or subcommand
- Reviewing an existing CLI for consistency and usability
- Adding flags or subcommands to an existing tool
- Ensuring CLI follows platform conventions

## Execution
1. Parse `$ARGUMENTS` for `<command_name>` (required) and `--style` (default: `posix`)
2. Style conventions:
   - **posix**: GNU-style long flags (`--verbose`), short aliases (`-v`), `--help`/`--version` mandatory
   - **git**: subcommand-based (`cmd verb noun`), global flags before subcommand
   - **click**: Python click decorators, automatic help generation, type validation
3. If designing new CLI:
   a. Define the command's purpose and primary use cases
   b. Design subcommand tree (if applicable)
   c. For each command/subcommand:
      - Required positional arguments (minimal)
      - Optional flags with sensible defaults
      - Short aliases for common flags
      - Help text for every flag (what it does, default value)
      - Example invocations
   d. Define output behavior: stdout for data, stderr for logs, exit codes
   e. Define error behavior: helpful messages, non-zero exit codes
4. If reviewing existing CLI:
   a. Check for consistency (flag naming, help text style, output format)
   b. Check for missing help text or examples
   c. Check for confusing flag names or ambiguous defaults
   d. Compare against style conventions
5. Generate implementation skeleton (argparse or click)

## Output Format
```
CLI Design | {command_name} | style: {style}

Usage: {command} [FLAGS] {SUBCOMMAND} [ARGS]

Subcommands:
  {verb}    {description}

Global Flags:
  -v, --verbose    Increase output verbosity
  -q, --quiet      Suppress non-error output
  --format {fmt}   Output format (default: text)

{subcommand} Flags:
  {flag}    {description} (default: {value})

Examples:
  $ {command} {example1}
  $ {command} {example2}

Exit Codes:
  0  Success
  1  General error
  2  Invalid arguments

Next action: {recommendation}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| CLI designed | `[api-design]` for corresponding API |
| Implementation ready | `[commit]` after building |
| Need error standards | `[error-message]` for error text quality |
