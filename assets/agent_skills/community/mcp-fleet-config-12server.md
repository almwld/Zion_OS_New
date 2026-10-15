---
name: mcp-fleet-config-12server
description: >
  Configures and validates the 12-server MCP fleet standard for HUMMBL agents.
  Manages both local (stdio) and remote (HTTP/SSE) MCP servers across cognitive-ledger,
  coordination-bus, hummbl-graph, basen, base120, wolfram, github, filesystem, memory,
  sequential-thinking, fetch, and linear. Validates dual-config alignment (.gemini/config
  and .gemini/antigravity-cli) and performs health checks.
version: 0.1.0
execution-mode: advisory
tags:
  - mcp
  - config
  - fleet
  - agent
  - stdio
  - http
  - sse
  - server
category: fleet-ops
status: candidate
providers:
  required: [python]
  pip: [pyyaml]
---

# MCP Fleet Config (12-Server Standard)

Configures, validates, and maintains the **12-server MCP fleet standard** for HUMMBL agents.
Manages both local (stdio) and remote (HTTP/SSE) MCP servers, validates dual-config alignment,
and performs automated health checks.

## When to Use

- Initializing MCP configuration for a new agent session
- Synchronizing dual configs (.gemini/config + .gemini/antigravity-cli)
- Adding/removing MCP servers from fleet standard
- Running health checks on all 12 servers
- Auditing MCP configuration compliance

## 12-Server Fleet Standard

| # | Server | Type | Purpose | Transport |
|---|--------|------|---------|-----------|
| 1 | **cognitive-ledger** | Local (stdio) | CLP v1.0 ledger operations | stdio |
| 2 | **coordination-bus** | Local (stdio) | TSV bus read/write, verification | stdio |
| 3 | **hummbl-graph-mcp** | Local (stdio) | GraphRAG-lite (BM25 + GraphRAG) | stdio |
| 4 | **basen-mcp** | Local (stdio) | Base-N encoding/decoding (Base6→BASE120) | stdio |
| 5 | **hummbl-base120** | Remote (HTTP) | Base120 mental model library (public) | HTTP/SSE |
| 6 | **wolfram** | Remote (HTTP) | Wolfram Alpha computational knowledge | HTTP/SSE |
| 7 | **github** | Remote (HTTP) | GitHub API via MCP | HTTP/SSE |
| 8 | **filesystem** | Local (stdio) | File operations under $HOME | stdio |
| 9 | **memory** | Remote (HTTP) | Persistent memory across sessions | HTTP/SSE |
| 10 | **sequential-thinking** | Remote (HTTP) | Structured reasoning decomposition | HTTP/SSE |
| 11 | **fetch** | Remote (HTTP) | HTTP fetch via MCP | HTTP/SSE |
| 11 | **linear** | Remote (HTTP) | Linear GraphQL via MCP | HTTP/SSE |

## Configuration Schema

```json
{
  "mcpServers": {
    "cognitive-ledger": {
      "command": "python",
      "args": ["-m", "hummbl_governance.cognition.mcp_server"],
      "env": {
        "PYTHONPATH": "/path/to/hummbl-governance",
        "CLP_STATE_DIR": "/path/to/clp_state"
      }
    },
    "coordination-bus": {
      "command": "python",
      "args": ["-m", "hummbl_governance.bus.mcp_server"],
      "env": {
        "PYTHONPATH": "/path/to/hummbl-governance",
        "BUS_FILE": "/path/to/messages.tsv"
      }
    },
    "hummbl-graph-mcp": {
      "command": "python",
      "args": ["-m", "hummbl_governance.mcp.graph_server"],
      "env": {
        "PYTHONPATH": "/path/to/hummbl-governance",
        "HUMMBL_GRAPHS_DIR": "/path/to/graphs"
      }
    },
    "basen-mcp": {
      "command": "python",
      "args": ["-m", "hummbl_governance.mcp.basen_server"],
      "env": { "PYTHONPATH": "/path/to/hummbl-governance" }
    },
    "hummbl-base120": {
      "url": "https://mcp-public.hummbl.io/mcp"
    },
    "wolfram": {
      "command": "npx",
      "args": ["-y", "mcp-remote@latest", "https://agenttools.wolfram.com/mcp"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/reuben"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch"]
    },
    "linear": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-linear"]
    }
  }
}
```

## Dual-Config Alignment

Maintains synchronization between:
- `.gemini/config/mcp_config.json` (Gemini CLI)
- `.gemini/antigravity-cli/mcp_config.json` (Antigravity Desktop)

**Validation rules**:
- Both files must exist
- Both must have identical `mcpServers` keys (order irrelevant)
- All local (stdio) servers must have valid `command` + `args`
- All remote servers must have valid `url` or `command`+`args` for npx remotes
- Environment variable paths must be absolute and exist

## Execution Procedure

### Initialize Fleet Config
1. **Detect agent roots**: `.gemini/config` and `.gemini/antigravity-cli`
2. **Generate standard config** with 12 servers
3. **Resolve paths**: PYTHONPATH → hummbl-governance repo root, CLP_STATE_DIR, BUS_FILE, HUMMBL_GRAPHS_DIR
3. **Write both configs** atomically
4. **Verify alignment** with dual-config check

### Validate Config
```python
def validate_mcp_config(config_path):
    with open(config_path) as f:
        config = json.load(f)
    
    servers = config.get("mcpServers", {})
    required = {"cognitive-ledger", "coordination-bus", "hummbl-graph-mcp", "basen-mcp",
                "hummbl-base120", "wolfram", "github", "filesystem", "memory",
                "sequential-thinking", "fetch", "linear"}
    
    # Check all 12 present
    missing = required - set(servers.keys())
    if missing:
        return False, f"Missing servers: {missing}"
    
    # Validate each server
    for name, spec in servers.items():
        if "command" in spec:
            if not spec.get("args"):
                return False, f"{name}: command missing args"
        elif "url" in spec:
            if not spec["url"].startswith(("http://", "https://")):
                return False, f"{name}: invalid url"
        else:
            return False, f"{name}: must have command or url"
    
    return True, "Valid"
```

### Health Check (All 12 Servers)
```bash
# For stdio servers: test MCP initialize handshake
for server in cognitive-ledger coordination-bus hummbl-graph-mcp basen-mcp; do
  echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"health-check","version":"1.0"}}}' | \
  python -m hummbl_governance.mcp.$server 2>&1 | head -5
done

# For HTTP/SSE servers: test endpoint
for url in https://mcp-public.hummbl.io/mcp https://agenttools.wolfram.com/mcp; do
  curl -s -o /dev/null -w "%{http_code}" "$url" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"health-check","version":"1.0"}}}'
done
```

## Dual-Config Sync Procedure

1. **Read both configs**
2. **Diff** server lists and specifications
3. **If mismatch**: Prompt for resolution (prefer `.gemini/config` as canonical)
4. **Write both** with identical content
5. **Re-validate** both

## Output Locations

- **Canonical**: `.gemini/config/mcp_config.json`
- **Mirror**: `.gemini/antigravity-cli/mcp_config.json`

## AIP Scope Compliance

- Config writes are `AGENT_LOCAL_CONFIG` mutations (permitted)
- No credential values in config (only paths and public URLs)
- Filesystem server restricted to `$HOME` scope

## Related Skills

- `omni-meta-aggregator-discovery` — specifies MCP interfaces in Gate -1.4
- `session-forensics-manifest` — records config mutations in forensic manifest

## Evidence Sources

- Reference configs: `.gemini/config/mcp_config.json`, `.gemini/antigravity-cli/mcp_config.json` (identical, 12 servers)
- Phase -1 spec: `hummbl_governance/docs/research/2026-08-16_omni_meta_aggregator_huaomp_mtsmu_discovery.md` (Gate -1.4)
- Forensic manifest: `forensic_telemetry.json` → `state_mutations` (2 CREATE_OVERWRITE entries)