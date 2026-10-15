---
name: demo-record
description: Record terminal demos with asciinema — scripted, reproducible, shareable
version: 1.0.0
execution-mode: side_effecting
argument-hint: "<demo-name> [--script <SCRIPT_PATH>] [--cols 120] [--rows 35]"
category: hummbl-research
status: candidate
---
# Demo Record | `$ARGUMENTS`

Record terminal sessions for proof packs, presentations, and documentation using asciinema. Supports scripted and interactive modes.

## Context Gathering

Before executing this skill, gather the following context:
- Run `which asciinema 2>/dev/null && asciinema --version || echo "asciinema not installed"`
- Run `which svg-term 2>/dev/null || which svg-term-cli 2>/dev/null || echo "svg-term not installed"`
- Run `ls -1 PROJECTS/your-org-profile/demos/ 2>/dev/null | head -5`

## Procedure

Parse `$ARGUMENTS` for demo name (required), optional script path, and terminal dimensions.

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=demo-record] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### Step 1 — Verify Prerequisites

```bash
# Check asciinema
if ! which asciinema >/dev/null 2>&1; then
    echo "FAIL: asciinema not installed"
    echo "  Fix: brew install asciinema"
    echo "  Alt: pip install asciinema"
    exit 1
fi
echo "PASS: asciinema $(asciinema --version 2>&1 | head -1)"

# Check svg-term for SVG export (optional)
if which svg-term >/dev/null 2>&1; then
    echo "PASS: svg-term available"
elif which npx >/dev/null 2>&1; then
    echo "INFO: svg-term not installed, can use: npx svg-term-cli"
else
    echo "INFO: svg-term not available -- SVG export will be skipped"
fi

# Check agg for GIF export (optional)
if which agg >/dev/null 2>&1; then
    echo "PASS: agg available (GIF export)"
else
    echo "INFO: agg not available -- install: brew install asciinema/tap/agg"
fi

# Create output directory
DEMO_DIR="${DEMO_DIR:-PROJECTS/your-org-profile/demos}"
mkdir -p "$DEMO_DIR"
echo "PASS: Output directory: $DEMO_DIR"
```

### Step 2 — Write Demo Script (scripted mode)

If `--script` is provided, use that file. Otherwise, generate a script template:

```bash
DEMO_NAME="${1:-my-demo}"
SCRIPT_PATH="${DEMO_DIR}/${DEMO_NAME}-script.sh"

# Generate template for a scripted demo
cat > "$SCRIPT_PATH" << 'SCRIPT_INNER'
#!/bin/bash
# Demo script -- edit commands below, then record with:
#   asciinema rec demo.cast --command "bash this-script.sh"

# Show project structure
echo "$ tree -L 1 src/"
tree -L 1 src/ 2>/dev/null || ls -1 src/
sleep 1

# Run health check
echo ""
echo "$ python3 -m hummbl_governance.services.health"
python3 -m hummbl_governance.services.health 2>&1 | head -20
sleep 1

# Run tests
echo ""
echo "$ python3 -m pytest tests/test_acceptance.py -v --tb=short"
python3 -m pytest tests/test_acceptance.py -v --tb=short 2>&1 | tail -15
sleep 1

echo ""
echo "Done!"
SCRIPT_INNER

chmod +x "$SCRIPT_PATH"
echo "PASS: Script template written to $SCRIPT_PATH"
echo "  Edit this script, then record with --script flag"
```

### Step 3 — Record

Two modes: interactive (user types live) or scripted (runs a script).

```bash
DEMO_NAME="${1:-my-demo}"
DEMO_DIR="${DEMO_DIR:-PROJECTS/your-org-profile/demos}"
CAST_FILE="$DEMO_DIR/${DEMO_NAME}.cast"
COLS="${COLS:-120}"
ROWS="${ROWS:-35}"

# Scripted recording (preferred for reproducibility)
if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
    asciinema rec "$CAST_FILE" \
        --cols "$COLS" \
        --rows "$ROWS" \
        --title "$DEMO_NAME" \
        --idle-time-limit 3 \
        --command "bash $SCRIPT_PATH"
    echo "Recorded (scripted): $CAST_FILE"
else
    # Interactive recording -- user types commands live
    asciinema rec "$CAST_FILE" \
        --cols "$COLS" \
        --rows "$ROWS" \
        --title "$DEMO_NAME" \
        --idle-time-limit 3
    echo "Recorded (interactive): $CAST_FILE"
fi
```

### Step 4 — Review

```bash
CAST_FILE="$DEMO_DIR/${DEMO_NAME}.cast"

# Show recording metadata
python3 -c "
import json, os
path = '$CAST_FILE'
with open(path) as f:
    header = json.loads(f.readline())
    events = sum(1 for _ in f)
size_kb = os.path.getsize(path) / 1024
print(f'File:     {path}')
print(f'Size:     {size_kb:.1f} KB')
print(f'Terminal: {header.get(\"width\", \"?\")}\x{header.get(\"height\", \"?\")}')
print(f'Events:   {events}')
print(f'Title:    {header.get(\"title\", \"untitled\")}')
"

# Play back locally (user reviews)
echo "Play back with: asciinema play $CAST_FILE"
echo "Play at 2x:     asciinema play -s 2 $CAST_FILE"
```

### Step 5 — Export Formats

```bash
CAST_FILE="$DEMO_DIR/${DEMO_NAME}.cast"

# SVG export
if which svg-term >/dev/null 2>&1; then
    svg-term --in "$CAST_FILE" --out "$DEMO_DIR/${DEMO_NAME}.svg" --window --no-cursor --padding 10
    echo "PASS: SVG -> $DEMO_DIR/${DEMO_NAME}.svg"
elif which npx >/dev/null 2>&1; then
    npx svg-term-cli --in "$CAST_FILE" --out "$DEMO_DIR/${DEMO_NAME}.svg" --window --no-cursor --padding 10
    echo "PASS: SVG (via npx) -> $DEMO_DIR/${DEMO_NAME}.svg"
else
    echo "SKIP: SVG export -- install: npm install -g svg-term-cli"
fi

# GIF export
if which agg >/dev/null 2>&1; then
    agg "$CAST_FILE" "$DEMO_DIR/${DEMO_NAME}.gif" --font-size 14
    echo "PASS: GIF -> $DEMO_DIR/${DEMO_NAME}.gif"
else
    echo "SKIP: GIF export -- install: brew install asciinema/tap/agg"
fi
```

### Step 6 — Upload and Embed

```bash
CAST_FILE="$DEMO_DIR/${DEMO_NAME}.cast"

echo "Upload:  asciinema upload $CAST_FILE"
echo ""
echo "Embed in README (after upload):"
echo '  [![asciicast](https://asciinema.org/a/RECORDING_ID.svg)](https://asciinema.org/a/RECORDING_ID)'
echo ""
echo "Embed SVG directly:"
echo "  ![demo](demos/${DEMO_NAME}.svg)"
```

## Output Format

```
Demo Record | <demo-name> | <date>
==================================

Prerequisites:
  asciinema: [PASS] v<version>
  svg-term:  [PASS|SKIP]
  agg:       [PASS|SKIP]

Recording:
  Cast file: <path>.cast
  Size:      X.X KB
  Terminal:  <cols>x<rows>
  Events:    N

Exports:
  SVG: <path>.svg [DONE|SKIPPED]
  GIF: <path>.gif [DONE|SKIPPED]

Upload:
  Command: asciinema upload <path>.cast
  Status:  [UPLOADED <url> | NOT UPLOADED]

Next action: <edit script and re-record | upload | embed in README>
```

## Skill Chains

### Mandatory

None — recording a terminal session generates output files only; no destructive or irreversible operations.

### Advisory

- Before: `[health]` (verify services before recording), `[env-setup]` (ensure clean env)
- After: `[proof-pack]` (include recording in application bundle), `[readme-gen]` (embed in README)

## Authority

- **T1 (TRUSTED)**: May run (record, export, upload demos)
- **T2 (Active/High)**: May run (record, export, upload demos)
- **T3 (Medium)**: May run (record, export, upload demos)
- **T4 (Probationary)**: May run (file generation only — no system state changes)
- **Operator**: Override any restriction
