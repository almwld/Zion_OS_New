# Audit Inventory
Commit 0176b75ce42574cfef95fd8e1141d6d86ab15e99

Scope counts:
lib Dart 495
test Dart 49
Kotlin 8
Java 1
native C/C++ 3
manifest/build/pubspec 3
total 559

Priority files:
lib/features/terminal/native_pty_adapter.dart 148 lines partial
lib/features/terminal/terminal_service.dart 389 lines partial
lib/features/terminal/terminal_screen.dart partial
lib/features/terminal/termux_runtime_service.dart partial
lib/features/terminal/cosmic_terminal.dart 6 lines placeholder
lib/features/terminal/remote_session_manager.dart partial
lib/features/terminal/telnet_session_manager.dart partial
lib/screens/lock_screen.dart 378 lines partial
lib/core/services/biometric_service.dart 106 lines real
lib/services/biometric_service.dart 64 lines duplicate candidate
android/app/src/main/cpp/zion_pty.c 381 lines partial
android/app/src/main/kotlin/com/zion/os/MainActivity.kt 1030 lines partial
lib/zion_ota_system.dart 77 lines unconfigured
lib/screens/apps/notes_app.dart 473 lines broken decoder

The requested lib/features/lock directory does not exist. The actual lock screen is lib/screens/lock_screen.dart.

Tree inventory is complete. Semantic line-by-line review of all 559 files was not completed; unread files are not assigned a fabricated status.