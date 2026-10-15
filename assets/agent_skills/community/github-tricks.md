---
name: github-tricks
description: GitHub URL tricks of the trade -- domain swaps (gitingest, gitdiagram, deepwiki, gitmcp), native URL suffixes (.diff/.patch/.atom/.keys), permalinks, and the public-vs-private boundary. [Maps to P1.]
version: 0.1.0
status: tested
execution-mode: advisory
argument-hint: "[github-url-or-owner/repo] [target] [--fetch]"
category: dev-workflow
providers:
  required: [python]
---

# GitHub Tricks

Transform any `github.com/owner/repo` URL into a useful surface. Two tiers:

- **native** -- stays on github.com / raw.githubusercontent.com. Safe for private repos.
- **third-party** -- the repo path (and usually contents) leaves GitHub. **Public repos only.**

## Usage

```bash
python <skill-dir>/scripts/ghx.py <url-or-owner/repo> <target> [--fetch]
python <skill-dir>/scripts/ghx.py --list        # all targets with tiers
python <skill-dir>/scripts/ghx.py --self-test   # assert-based sanity check
```

`ghx` parses the input URL, so a `/pull/N` URL feeds `diff`/`patch`, a `/blob/` URL feeds `raw`/`blame`, etc. `--fetch` performs a read-only GET and prints the body (useful for `.diff`, `.patch`, `.atom`, `.keys`, `raw`).

## Decision table -- reach for these first

| Situation | Command / URL form |
|---|---|
| Review a PR without cloning | `ghx <pr-url> diff --fetch` (or append `.diff`) |
| Replay a PR's commits locally | `ghx <pr-url> patch` + `git am` |
| Read a diff without reindent noise | append `?w=1` to the `/files` URL |
| "What changed upstream in January" | `ghx <url> compare 'main@{2026-01-01}...main@{2026-02-01}'` (server-side date resolution, no reflog) |
| Cite code in a bus post / issue / PR | **SHA permalink, never a branch URL** (press `y` on the page; branches rot) |
| Ingest a public repo for LLM context | `ghx <url> ingest` (or `uithub`; gitingest skips files >50KB) |
| Repo Q&A without cloning | `ghx <url> mcp` (live MCP server) or `deepwiki` (generated wiki + MCP) |
| Architecture overview of unfamiliar repo | `ghx <url> diagram` (LLM reads file tree, not imports) |
| Monitor one file for changes | `/commits/<branch>/<path>.atom` -- RSS per file |
| Always-newest release asset | `/releases/latest/download/<asset>` |
| Someone's public SSH keys | `github.com/<user>.keys` (also `.gpg`, `.png?size=N`) |
| Fetch any PR ref, even closed | `git fetch origin pull/<N>/head:pr-<N>` |
| Clone a repo's wiki | `git clone https://github.com/<o>/<r>.wiki.git` |
| Index of every swap tool | `ghx <url> forgithub` |

## Target reference (`ghx --list`)

- **native**: `dev` `blob` `blame` `raw` `diff` `patch` `commit-diff` `compare` `feed` `releases-feed` `tarball` `latest-asset` `wiki-clone` `keys` `gpg`
- **third-party**: `1s` `ingest` `uithub` `mcp` `diagram` `deepwiki` `repowiki` `podcast` `reverse` `gg` `stackblitz` `prnew` `bolt` `forgithub` `stars` `tracker` `cache` `threads`

## Boundary rules

- Third-party targets send the repo path -- and often full contents -- off GitHub. **Public repos only.** Never point them at private hummbl-io repos or a client repo without operator sign-off.
- `talktogithub.com` is dead/ad-redirected. Do not use.
- Private-repo ingest path: `gitingest` CLI with a PAT (`pip install gitingest`). Never paste a PAT into a third-party web form clone.
- `gitmcp.io/docs` is a generic endpoint that floats across repos -- always scope to the repo (`gitmcp.io/<owner>/<repo>`).

## Gotchas that bite agents

- `A...B` (three dots) diffs from the merge base -- what a PR shows. `A..B` diffs current tips and changes as the base moves. State which you used in bug reports.
- `raw.githubusercontent.com/<o>/<r>/<branch>/<path>` caches ~5 min. Pin a SHA for immutable reads (`ghx` warns when `raw` gets a non-SHA ref).
- `#L<n>` line anchors do nothing on rendered Markdown without `?plain=1` (`ghx` adds it for `blob`).
- File finder (`t` / `/find/`) hides `.git`, `.hg`, `.svn`, `.sass-cache`, `build`, `dot_git`, `log`, `tmp`, `vendor` -- a file that exists can look missing.
- Blame skips commits in `.git-blame-ignore-revs`; append `~` to the SHA to see past it.
- `@{date}` braces must be `%7B`/`%7D` in scripts -- `ghx compare` encodes them.
- Prefilled-form URLs (`/issues/new?title=...`, `?quick_pull=1&template=...`, `/releases/new?tag=...`) 404 entirely if one parameter exceeds your permissions -- not partial fill.
- `.gpg` never 404s -- accounts with no key return an empty armored block. Check the body, not the status code.
- Archive URLs redirect to `codeload.github.com` -- strict firewalls block it.
- The wiki is a separate repo -- not included in clones or `.tar.gz` archives. Back it up separately.
- Keyboard on github.com: `.` opens github.dev, `t` file finder, `y` permalink rewrite, `b` blame, `l` label filter (Alt+click excludes), `r` quote reply, `?` full list. Alt+click a diff caret collapses every diff in the PR.
- Search: `is:issue is:open -linked:pr` (unclaimed work), `symbol:<name>` (definitions only; needs login), `archived:false`.

## Output Format

```
ghx | <input> -> <target>
<stdout>: <transformed url>
<stderr>: tier warnings (third-party, branch-ref raw)
--fetch: response body appended to stdout
```

## Skill Chains

### Advisory

- After `[github-tricks]` → `[review-pr]` if a diff/patch was pulled for review
- After `[github-tricks]` → `[deep-research]` or `[web-research]` when ingesting repos for a research lane
- After `[github-tricks]` → `[skill-export]` when porting a digest or trick set to another runtime
- After `[github-tricks]` → `[git-forensics]` when compare/blame output feeds a forensic lane

## Authority

- **T1/T2**: May run. Advisory only; `--fetch` is a read-only GET.
- **T3/T4**: May run. Third-party targets remain public-repo-only regardless of tier.
- **Operator**: override.
