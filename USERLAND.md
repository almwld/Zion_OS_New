# Zion OS Userland Runtime

## Purpose

Zion's terminal uses the native PTY in `android/app/src/main/cpp/zion_pty.c` and installs the Termux-compatible bootstrap into the app-private directory:

- Prefix: `$FILES/usr` (normally `/data/data/com.zion.os/files/usr`)
- Shell candidates: `usr/bin/bash.real`, `usr/bin/bash`, then other configured shells and Android `/system/bin/sh`
- Home: `$FILES/home`
- Runtime libraries: `usr/lib` and `usr/lib64`

## Current startup flow

1. Dart requests `ensureBootstrap` through the PTY MethodChannel.
2. `MainActivity` runs `TermuxBootstrapInstaller.ensureInstalled()` on the terminal executor.
3. The installer reads the embedded ZIP stream from `libtermux-bootstrap.so` (or the official JNI accessor), extracts to an isolated staging directory, checks archive paths and size limits, recreates the bootstrap's declared symlinks, validates required files, then promotes staging to `files/usr`.
4. The native PTY prepares HOME, PREFIX, PATH, and LD_LIBRARY_PATH and tries the selected shell. For a private-prefix ELF, it attempts the Android dynamic linker before falling back to `/system/bin/sh`.

The installer deliberately preserves a non-empty incomplete prefix rather than deleting user data. A failed install is reported to the terminal; it must not be treated as a successful Bash launch.

## Important distinctions

- A successful `linker64 ... bash --version` proves that this Bash ELF can be loaded with that command and environment. It does **not** prove that Bash can spawn external programs from the prefix.
- `LD_LIBRARY_PATH` resolves shared-library dependencies; it does not make an executable permitted by Android's SELinux policy.
- `memfd_create`/ `fexecve` is not a guaranteed SELinux workaround. Kernel policy may deny executable memfds, and interpreter/library requirements still apply. Do not label this as a bypass or depend on it as the production execution path.
- The installer currently extracts the bootstrap; the 477-library directory described in device notes is not automatically bundled or copied by this installer. Files found only under shared storage are not a reproducible APK dependency.
- A count of files or a version marker alone is not an integrity check. Validate required files and the exact runtime behavior.

## Release acceptance

Do not call Userland complete until a built APK has been installed and the following commands have been run inside the same interactive Zion PTY session:

```sh
printf 'BASH_VERSION=%s\n' "$BASH_VERSION"
bash --version
command -v ls
ls /
grep --version
python3 --version
printf 'ZION_USERLAND_ACCEPTANCE_OK\n'
```

Record the device Android version, ABI, APK commit SHA, each command's exit status, and relevant logcat errors. The required acceptance is that Bash starts automatically and external commands work without `Permission denied`; a shell fallback to `/system/bin/sh` is a failure for this acceptance test.

## Change policy

- Keep bootstrap extraction idempotent and staged.
- Never recursively delete a populated active prefix to repair it automatically.
- Keep the terminal UI responsive by running extraction and PTY startup away from the main thread.
- Bundle all required runtime inputs in the APK or verify them against a committed manifest. Do not rely on `/sdcard/lib-fix-all` for production.
- Run CI checks for source contracts, then do an actual Android-device acceptance test before declaring the runtime fixed.
