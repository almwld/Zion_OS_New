# Dead Code Candidates

D-01 lib/services/biometric_service.dart is a second biometric implementation while the current lock screen imports lib/core/services/biometric_service.dart.

D-02 TerminalService._interactiveProcess is declared and consumed by fallback branches but the inspected interactive start path never assigns it.

D-03 MainActivity.terminalProcesses is declared and checked by resize/stop paths but the native PTY start path populates terminalReaders instead.

D-04 features/terminal/cosmic_terminal.dart is a six-line static terminal placeholder.

D-05 core/wm/window_manager.dart is only an export/typedef compatibility facade. It is not called dead by itself, but it is not a second window manager implementation.