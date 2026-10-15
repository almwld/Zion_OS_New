---
name: linux-package-inventory
description: Inventory installed Linux packages and tools without modifying the environment.
---
# Linux Package Inventory
1. Confirm which runtime is active before querying packages.
2. Prefer package database listings and command lookup (dpkg, apt list, command -v, which).
3. Associate each tool with its path, version when available, and runtime.
4. Distinguish "not installed" from "not on PATH", inaccessible rootfs, and package database errors.
5. Do not install, upgrade, or remove packages during inventory-only tasks.
Return a compact table of tool, availability, path/version, and evidence.