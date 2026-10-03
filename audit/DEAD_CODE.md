# Dead Code Candidates — status refreshed 2026-10-03

D-01 **CONTROLLED:** lib/services/biometric_service.dart remains for compatibility and is now deprecated; it delegates to the canonical core biometric service.

D-02 **RESOLVED:** TerminalService._interactiveProcess is no longer present in the current implementation.

D-03 **RESOLVED:** MainActivity.terminalProcesses is no longer present; native PTY readers are the authoritative lifecycle state.

D-04 **RESOLVED:** features/terminal/cosmic_terminal.dart is now a compatibility adapter to TerminalScreen.

D-05 **UNCHANGED:** core/wm/window_manager.dart is a compatibility export/typedef facade. It is not deleted because the current trace does not prove all external compatibility callers are absent.
