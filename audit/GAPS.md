# Confirmed Gaps

G-01 High: MainActivity accepts the ZION_API intent and forwards it to ZionApiChannel. The package bridge has a token check, but the general API path has no equivalent caller authentication in the inspected flow.

G-02 High: TerminalService declares _interactiveProcess and has fallback branches for it, but startInteractive uses the native PTY and does not assign a Process. The fallback state is therefore not a functioning fallback.

G-03 Medium: PTY master is nonblocking. nativeReadPty returns an empty array on EAGAIN and MainActivity retries after only 8 ms. Idle sessions can therefore wake frequently.

G-04 Medium: Multiple terminal surfaces exist: features/terminal/terminal_screen.dart, features/terminal/cosmic_terminal.dart, lib/cosmic_terminal.dart, screens/terminal/advanced_terminal.dart, zion_advanced_terminal.dart and screens/apps/terminal_app.dart.

G-05 Medium: Two biometric service implementations exist. The lock screen imports the core service.

G-06 Medium: zion_ota_system.dart reports isConfigured false and checkForUpdates returns null after setting an unavailable error.

G-07 Medium: notes_app.dart defines a local jsonDecode helper that returns [] unconditionally at line 471.

G-08: The requested features/lock directory is absent; the real lock screen is screens/lock_screen.dart.

These are confirmed findings, not a claim that they are the only defects in the 559-file scope.