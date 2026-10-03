# Architecture Audit

A-01: Terminal behavior is spread across several feature, screen and legacy surfaces. The authoritative native boundary is native_pty_adapter.dart -> terminal_service.dart -> MainActivity.kt -> zion_pty.c, but multiple alternative terminal UIs remain.

A-02: Two biometric service contracts exist. The lock screen uses the core service.

A-03: core/wm/window_manager.dart is a compatibility export/typedef layer around the feature window manager.

A-04: MainActivity.kt and ZionApiChannel.kt both own substantial native API responsibilities, increasing the size of the platform boundary.

A-05: RESOLVED. Both the package bridge and general external Zion API path require their respective per-install credentials; ZION_API additionally has a signature-level component permission.

A-06: OTA models an honest unavailable state rather than pretending to succeed, but remains incomplete.

A-07: The PTY contract itself is present: availability, start, byte events, write, resize and stop are implemented.

A-08: The requested features/lock path does not exist; the real implementation is screens/lock_screen.dart.