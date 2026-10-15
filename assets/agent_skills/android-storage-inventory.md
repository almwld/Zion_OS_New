---
name: android-storage-inventory
description: Discover local filesystems and rootfs archives with bounded Android storage scans.
---
# Android Storage Inventory
1. Start with readable top-level directories under shared storage and report inaccessible locations explicitly.
2. Use bounded depth and targeted extensions/names; avoid recursively dumping every file or file content.
3. Identify archives separately from extracted rootfs trees and inspect archive listings before extraction.
4. Verify expected shell and package metadata after extraction or restore.
5. Do not upload, delete, or overwrite discovered user data during inventory.
Explain the difference between shared storage, the app sandbox, PRoot userspace, and device root.