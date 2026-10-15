---
name: hummbl-bif
description: Batch Ingestion Framework - systematic methodology for technical knowledge acquisition using AI assistants
version: 1.0.1
execution-mode: advisory
argument-hint: "[bif start <domain> | bif status | bif template <phase> <batch> | bif validate <file>]"
category: governance-compliance
status: candidate
---
# HUMMBL BIF

Batch Ingestion Framework — systematic methodology for technical knowledge acquisition using AI assistants. Provides a 4-phase, 15-batch ingestion process with domain templates, session management, and validation. Exposes both a CLI (`bif`) and MCP server tools.

## When to Use

- Starting a structured knowledge ingestion session for a technical domain
- Getting phase/batch prompt templates for systematic knowledge capture
- Validating batch markdown output against framework quality checks
- Tracking ingestion session progress across phases and batches
- Listing available domain templates

## Usage

```bash
[hummbl-bif] bif start Anthropic --batches 10
[hummbl-bif] bif status
[hummbl-bif] bif status <session_id>
[hummbl-bif] bif template 1 3
[hummbl-bif] bif validate path/to/batch.md
[hummbl-bif] bif templates
```

## Python API

```python
from mcp_server import (
    tool_bif_start_session,
    tool_bif_session_status,
    tool_bif_get_template,
    tool_bif_validate_batch,
    tool_bif_list_templates,
)

from bif_cli import (
    main,           # CLI entry point
    build_parser,   # argparse parser
)
```

## Key Concepts

- **4-phase methodology**: Phase 1 (FOUNDATION — domain orientation), Phase 2 (ARCHITECTURE — internals & design), Phase 3 (ECOSYSTEM — integrations & tooling), Phase 4 (PRACTICE — patterns & pitfalls). Each phase has multiple batches.
- **15-batch structure**: Each batch has a specific capture objective, priority, and file naming convention.
- **Session management**: Sessions track progress across phases. `BIF_SESSIONS_DIR` env var overrides the default temp directory for test isolation.
- **MCP server**: `mcp_server.py` exposes 5 tool functions via stdio JSON-RPC for integration with AI assistants.
- **CLI wrapper**: `bif_cli.py` wraps the MCP tool functions as argparse subcommands.
- **Validation**: `tool_bif_validate_batch()` checks batch markdown for required sections, completeness, and quality — returns pass/fail per check with gap descriptions.
- **Domain templates**: Pluggable templates in `templates/` directory — each defines batches tailored to a specific domain.

## Install

```bash
cd /work/active/oss/packages/python/hummbl-bif/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-bif/`
- **License**: Apache 2.0
- **Dependencies**: stdlib only
