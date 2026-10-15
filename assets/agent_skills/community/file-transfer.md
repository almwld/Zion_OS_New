---
name: file-transfer
description: Transfer files between local machine and a remote host via SCP/rsync.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[push FILE | pull FILE | sync DIRECTORY]"
category: fleet-ops
status: candidate
---
# File Transfer

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=file-transfer] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Transfer files between local machine and a configured remote host ($REMOTE_HOST).

## Operations

### push
Copy a file to remote host:
```bash
scp LOCAL_PATH $REMOTE_HOST:REMOTE_PATH
```

For directories:
```bash
scp -r LOCAL_DIR $REMOTE_HOST:REMOTE_DIR
```

### pull
Copy a file from remote host:
```bash
scp $REMOTE_HOST:REMOTE_PATH LOCAL_PATH
```

### sync
Bidirectional sync of a directory:
```bash
# Push (local -> remote)
rsync -avz --delete LOCAL_DIR/ $REMOTE_HOST:REMOTE_DIR/

# Pull (remote -> local)
rsync -avz $REMOTE_HOST:REMOTE_DIR/ LOCAL_DIR/
```

**Warning**: `--delete` removes files on the destination that don't exist on the source. Omit it for additive-only sync.

## Common Transfers

| What | Local Path | Remote Path | Direction |
|------|-----------|-------------|-----------|
| Skills | `~/.agents/skills/` | `~/.agents/skills/` | Push (use [mesh-sync]) |
| Scripts | `$PROJECT_ROOT/scripts/` | `$REMOTE_PROJECT_ROOT/scripts/` | Push |
| Logs | -- | `/tmp/*.log` | Pull |
| Research | -- | `$REMOTE_PROJECT_ROOT/docs/research/` | Pull (if remote-generated) |

## Safety
- Always verify the destination exists before pushing: `ssh $REMOTE_HOST "ls -d REMOTE_DIR"`
- For large transfers, use rsync with `--dry-run` first
- Never transfer .env files or credentials -- use Keychain or secret manager
- After transfer, verify: `ssh $REMOTE_HOST "ls -la REMOTE_PATH"`

## Skill Chains

### Mandatory

- `[fleet-ssh-config]` SHOULD verify target SSH alias before any push/pull/sync operation — ensures `$REMOTE_HOST` resolves correctly and SSH key is available.

### Advisory

- Use `rsync --dry-run` before any `sync` operation to preview changes
- `[heartbeat]` after large transfers to confirm remote host health

## Authority

- **T1 (TRUSTED)**: May run (push, pull, sync — all transfer operations)
- **T2 (Active/High)**: May run (push, pull, sync — all transfer operations)
- **T3 (Medium)**: Operator approval required for remote transfers (push/pull/sync to `$REMOTE_HOST`)
- **T4 (Probationary)**: BLOCKED — remote file transfer is prohibited (risk of data exfiltration or overwriting remote state)
- **Operator**: Override any restriction
