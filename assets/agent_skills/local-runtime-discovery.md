---
name: local-runtime-discovery
description: Discover and validate local Zion, Kali, and Linux rootfs environments.
---
# Local Runtime Discovery
1. Inspect only known, accessible roots first: Zion's app files, its configured distro directory, and shared storage.
2. Check candidate paths for bin/sh, bin/bash, executable bits, and package-manager metadata; a directory name is not proof of a runnable distro.
3. Record the exact absolute path and select the matching registered runtime.
4. Run a harmless identity/version check and capture exit code plus combined PTY output.
5. If launch fails, preserve the rootfs and diagnose the first concrete loader, mount, or permission error.
Never report a runtime as available until a real command succeeds.