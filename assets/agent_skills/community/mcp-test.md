---
name: mcp-test
description: Test MCP server implementations with tool discovery, schema validation, invocation testing, and error handling verification
version: 0.1.0
execution-mode: advisory
argument-hint: "<server_config> [--action discover|validate|invoke|stress]"
category: dev-tools
status: candidate
---
# MCP Test

Test Model Context Protocol (MCP) server implementations end-to-end. Covers tool discovery, JSON Schema validation of tool definitions, invocation testing with sample inputs, error handling verification, and basic stress testing. Ensures MCP servers conform to the protocol spec and handle edge cases gracefully.

## When to Use
- After building a new MCP server to verify it works correctly
- Before deploying an MCP server update to catch regressions
- When debugging tool invocation failures from Claude Code or other clients
- Validating that error responses conform to the MCP protocol

## Execution
1. Parse `$ARGUMENTS` for server config (path to config or server command) and action (default: `discover`).
2. For `discover` action:
   - Connect to the MCP server using stdio or HTTP transport.
   - List all available tools and resources.
   - Display tool names, descriptions, and input schemas.
3. For `validate` action:
   - Fetch all tool definitions from the server.
   - Validate each tool's input schema is valid JSON Schema.
   - Check for required fields: name, description, inputSchema.
   - Verify parameter types, required fields, and descriptions are present.
4. For `invoke` action:
   - For each tool, generate a sample valid input from the schema.
   - Invoke the tool and verify the response format.
   - Test with invalid inputs to verify error handling.
   - Test with missing required fields to verify validation.
5. For `stress` action:
   - Send concurrent requests to test server stability.
   - Measure response times and check for timeouts.
   - Verify server handles connection drops gracefully.
6. Report results with pass/fail per tool and overall server health.

## Output Format
```
MCP Test | server | action

## Server Info
- Transport: {stdio|http}
- Tools: N
- Resources: N

## Tool Discovery
| Tool | Description | Params | Status |
|------|------------|--------|--------|
| {name} | {desc} | {N params} | {PASS|FAIL} |

## Validation Results
| Tool | Schema Valid | Required Fields | Types | Status |
|------|-------------|----------------|-------|--------|
| {name} | {yes/no} | {yes/no} | {yes/no} | {PASS|FAIL} |

## Invocation Results
| Tool | Valid Input | Invalid Input | Error Format | Status |
|------|-----------|--------------|-------------|--------|
| {name} | {PASS|FAIL} | {PASS|FAIL} | {PASS|FAIL} | {PASS|FAIL} |

## Issues Found
- {issue description with tool name and details}

Next action: {suggestion or "No further action needed"}
```

## Skill Chains
- **Routing**: See `harness-routing.md` for SUT-type routing. This skill covers MCP servers only.
| After this skill... | Consider... |
|--------------------|-------------|
| Building a new MCP server | `[mcp-builder]` to scaffold or fix issues |
| Testing API endpoints | `[api-test]` for HTTP API testing |
| Validating against contracts | `[contract-test]` for schema conformance |
