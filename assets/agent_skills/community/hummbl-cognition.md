---
name: hummbl-cognition
description: Cognitive Ledger Protocol (CLP) and Open Brain server for HUMMBL agent reasoning
version: 0.1.0
execution-mode: advisory
argument-hint: "[post_entry | read_entries | OpenBrainRetriever | SharedState]"
category: governance-compliance
status: candidate
---
# HUMMBL Cognition

Cognitive Ledger Protocol (CLP) and Open Brain server for HUMMBL agent reasoning. Provides vendor-agnostic shared memory for multi-agent AI through three layers: shared state (mutable snapshot), shared memory (append-only ledger), and shared intent (human-authored goals).

## When to Use

- Posting and reading ledger entries (lessons, observations, decisions) across agents
- Managing shared agent state (who's doing what, status updates)
- Building startup/boot context for agent sessions from bus history
- Retrieving relevant knowledge via BM25 indexing (Open Brain retriever)
- Migrating knowledge from bus history, git logs, or memory markdown files
- Validating ledger entry integrity and schema compliance

## Usage

```bash
[hummbl-cognition] post_entry(agent="devin", entry_type="lesson", content="...")
[hummbl-cognition] read_entries(limit=10, entry_type="lesson")
[hummbl-cognition] python -m hummbl_cognition post --agent devin --type lesson --content "..."
[hummbl-cognition] python -m hummbl_cognition query --type lesson --limit 5
```

## Python API

```python
from hummbl_cognition import (
    # Core models
    LedgerEntry,
    LedgerEntryType,
    LedgerScope,
    SharedState,
    # Ledger operations
    post_entry,
    read_entries,
    validate_integrity,
    # State management
    read_state,
    write_state,
    claim_file,
    release_file,
    update_agent_status,
    ConcurrencyError,
    # Verified writing
    create_verified_entry,
    post_verified_entry,
    resolve_entry_identity,
    # Startup context
    build_boot_context,
    build_startup_context,
    read_recent_bus_inbox,
    write_startup_context,
    # Migration
    import_from_memory_md,
    import_from_bus_history,
    import_from_git_log,
    # Validation
    validate,
    validate_entry_dict,
    validate_state_dict,
    validate_file,
    ValidationError,
    # Retrieval
    BM25Index,
    OpenBrainRetriever,
)
```

## Key Concepts

- **Three-layer architecture**: Shared State (`state.json` — mutable snapshot), Shared Memory (`ledger.jsonl` — append-only log), Shared Intent (`intent.md` — human goals).
- **Ledger entries**: Typed entries (`LedgerEntryType`) with scope (`LedgerScope`) — lessons, observations, decisions, reflections.
- **Concurrency control**: `claim_file()` / `release_file()` with `ConcurrencyError` for safe multi-agent state updates.
- **Verified writing**: `create_verified_entry()` and `post_verified_entry()` with identity resolution for tamper-evident logging.
- **Open Brain retriever**: `BM25Index` + `OpenBrainRetriever` for semantic search over the ledger.
- **Migration tools**: Import knowledge from bus history, git logs, or markdown memory files.
- **Schema validation**: Built-in JSON Schema validator for entries and state.

## Install

```bash
cd /work/active/oss/packages/python/hummbl-cognition/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-cognition/`
- **License**: Apache 2.0
- **Dependencies**: `hummbl-bus>=0.1.0` (runtime); `hummbl-governance>=1.2.2` (optional `[governance]` extra)
