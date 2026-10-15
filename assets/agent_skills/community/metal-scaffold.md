---
name: metal-scaffold
description: Scaffold a new project in the hummbl-io/metal repo under the correct language directory with build file, test stub, and README
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<language> <project-name> [--description <text>]"
category: dev-tools
status: candidate
---

# [metal-scaffold]

Scaffold a new project subdirectory inside the **hummbl-io/metal** repo.
Each language has its own top-level directory; projects live inside their
language folder. No cross-language build coupling.

## When to Use

- Adding a new project, experiment, kata, or library to the metal repo
- User says "scaffold", "new metal project", "add project to metal", or
  names a language from the metal repo + a project name
- Starting a new low-level/systems programming task in C, C++, Rust,
  Assembly, Zig, Go, Nim, Fortran, or Odin

## When NOT to Use

- Initializing a new standalone repo (use `repo-scaffold`)
- Scaffolding a Python/JS/TS project (metal is for low-level languages only)
- Editing an existing metal project (just edit the files directly)

## Execution

### Inputs

- **language** (required): One of `c`, `cpp`, `rust`, `asm`, `zig`, `go`,
  `nim`, `fortran`, `odin`
- **project-name** (required): Kebab-case project name (e.g.
  `lockfree-queue`, `fast-memcpy`, `buddy-allocator`)
- **--description** (optional): One-line project description for README

### Steps

#### 0. Emit SKILL_INVOKE

Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=metal-scaffold] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```

#### 1. Resolve and Validate

1. Confirm the metal repo is cloned at `$PROJECTS_DIR/metal` (or find it
   with `find $PROJECTS_DIR -maxdepth 2 -name AGENTS.md -path "*/metal/*"`)
2. Verify `<lang>/` exists in the metal repo root
3. Verify `<lang>/<project-name>/` does NOT already exist
4. If the repo is not cloned, clone it: `gh repo clone hummbl-io/metal`

#### 2. Create Project Directory

```bash
mkdir -p $METAL_ROOT/<lang>/<project-name>
```

#### 3. Generate Language-Appropriate Files

Create the build file, a minimal source file, a test stub, and a README
for the project. Templates per language:

**C** (`c/<project>/`):
- `Makefile` — build target with `-Wall -Wextra -Werror -std=c11`
- `src/main.c` — minimal `int main(void) { return 0; }`
- `tests/test_basic.c` — minimal test with `assert`
- `README.md` — project name, description, build (`make`), run (`./bin/<project>`), test (`make test`)

**C++** (`cpp/<project>/`):
- `CMakeLists.txt` — cmake_minimum_required 3.16, C++17, project name
- `src/main.cpp` — minimal `int main() { return 0; }`
- `tests/test_basic.cpp` — minimal Google Test or Catch2 stub
- `README.md` — project name, description, build (`cmake -B build && cmake --build build`), test (`ctest --test-dir build`)

**Rust** (`rust/<project>/`):
- `Cargo.toml` — `[package]` with name, version 0.1.0, edition 2021
- `src/main.rs` — minimal `fn main() {}`
- `tests/basic.rs` — `#[test]` stub
- `README.md` — project name, description, build (`cargo build`), test (`cargo test`)

**Assembly** (`asm/<project>/`):
- `Makefile` — nasm/gas with `-f elf64` for x86_64 (default) or aarch64
- `src/main.asm` (x86_64) or `src/main.s` (AArch64) — minimal `_start` or `main`
- `README.md` — project name, description, target arch, build (`make`), run (`./bin/<project>`)

**Zig** (`zig/<project>/`):
- `build.zig` — `addExecutable` with project name
- `src/main.zig` — minimal `pub fn main() void {}`
- `tests/test_basic.zig` — `test "basic" {}` stub
- `README.md` — project name, description, build (`zig build`), test (`zig build test`)

**Go** (`go/<project>/`):
- `go.mod` — `module github.com/hummbl-io/metal/go/<project>` with go version
- `main.go` — minimal `package main; func main() {}`
- `main_test.go` — `func TestBasic(t *testing.T) {}` stub
- `README.md` — project name, description, build (`go build`), test (`go test`)

**Nim** (`nim/<project>/`):
- `<project>.nimble` — package metadata with version 0.1.0
- `src/main.nim` — minimal `echo "hello"`
- `tests/test_basic.nim` — `test "basic": check(true)` stub
- `README.md` — project name, description, build (`nimble build`), test (`nimble test`)

**Fortran** (`fortran/<project>/`):
- `Makefile` — gfortran with `-Wall -std=f2018`
- `src/main.f90` — minimal `program main; end program`
- `tests/test_basic.f90` — minimal test stub
- `README.md` — project name, description, build (`make`), run (`./bin/<project>`), test (`make test`)

**Odin** (`odin/<project>/`):
- `src/main.odin` — minimal `package main; main :: proc() {}`
- `tests/test_basic.odin` — minimal test stub
- `README.md` — project name, description, build (`odin build src`), test (`odin test tests`)

#### 4. README Template

Every project README follows this shape:

```markdown
# <project-name>

<description or "A <lang> project in the metal repo.">

## Build

<language-specific build command>

## Run

<language-specific run command>

## Test

<language-specific test command>

## License

Apache 2.0 — see [metal repo LICENSE](../../LICENSE)
```

#### 5. Post-Scaffold Verification

1. Verify all files exist: `ls -la $METAL_ROOT/<lang>/<project-name>/`
2. If a toolchain is available, attempt a dry build to verify the
   scaffold compiles (optional — do not fail if toolchain is missing)
3. Post a STATUS receipt to the bus with the created paths

### Stop Conditions

- **Language not in metal repo**: reject with the list of valid languages
- **Project directory already exists**: reject, suggest a different name
- **Metal repo not found and clone fails**: stop, report BLOCKED
- **No write access to metal repo**: stop, report BLOCKED

### Safety Boundary

- Creates files only under `<lang>/<project-name>/` — never touches
  other projects, language READMEs, `.gitkeep` files, or repo-level files
- Does not commit, push, or create PRs — that is a separate decision
- Does not install toolchains — scaffold is structural only

## Output Format

```
Metal Scaffold | <lang>/<project-name>
============================================================
Created: $METAL_ROOT/<lang>/<project-name>/

Files generated:
  <build file>        <toolchain>
  <source file>       minimal entry point
  <test file>         test stub
  README.md           project readme with build/run/test

Ready to develop:
  cd $METAL_ROOT/<lang>/<project-name>
  <build command>
------------------------------------------------------------
Next: start coding, then [build] + [tdd] to iterate, [mtsmu-review] before merge
```

## Skill Chains

### Mandatory

- Post SKILL_INVOKE before any file creation.

### Advisory

- After `[metal-scaffold]` → suggest `[build]` to verify the scaffold compiles
- After first feature → suggest `[tdd]` for test-driven iteration
- Before merge → suggest `[mtsmu-review]` for bug-first code review
- For safety-critical code → suggest `[threat-model]` for STRIDE analysis

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: Operator approval (new project creation)
- **Operator**: Override any restriction
