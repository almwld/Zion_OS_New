---
name: paper-chat
description: Interactive CLI to talk to a PDF using long-context models, with automatic Cognitive Ledger integration.
version: 1.0.0
execution-mode: side_effecting
argument-hint: "<path/to/paper.pdf>"
providers:
  required: [python]
  pip: [PyMuPDF]
---
# Paper-Chat

A custom HUMMBL alternative to "Talk to Paper" features found in tools like Bohrium. This skill runs entirely locally in your terminal, sending the full text of a PDF to a long-context model (avoiding RAG chunking loss). When the chat session concludes, it automatically synthesizes the insights and pushes them to the Cognitive Ledger.

## Setup

```bash
python -m venv ~/.agents/skills/paper-chat/.venv
~/.agents/skills/paper-chat/.venv/bin/pip install -r ~/.agents/skills/paper-chat/requirements.txt
```

## Usage

```bash
~/.agents/skills/paper-chat/.venv/bin/python ~/.agents/skills/paper-chat/paper_chat.py path/to/paper.pdf
```


## Features
- **Full Context**: Extracts the entire PDF using PyMuPDF and loads it into the LLM context window.
- **Interactive Chat**: A persistent terminal loop that retains conversation history.
- **Ledger Integration**: On exit, it offers to summarize the core findings of the chat and persist them to _state/cognition/ledger.jsonl.