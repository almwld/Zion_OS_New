# Performance Audit

P-01: zion_pty.c opens the master in nonblocking mode. EAGAIN becomes an empty byte array; MainActivity retries after 8 ms. Idle sessions can therefore cause frequent wakeups.

P-02: terminalSink is one global EventChannel sink shared by PTY sessions. Session IDs are included, but lifecycle changes affect the shared channel.

P-03: every PTY session creates a Kotlin reader thread. The UI caps sessions at eight, so the resource use is bounded but not minimal.

P-04: zion_desktop.dart is 916 lines and owns several controllers/managers. The inspected dispose method releases its controllers, which is positive; runtime profiling is still required.

P-05: TerminalScreen.dispose starts asynchronous service cleanup. This is normal for Flutter State.dispose, but service cleanup must remain race-safe.

Positive controls: explicit stream disposal exists in the inspected terminal services; MainActivity stops all terminals in onDestroy; the AI executor and model are also released in onDestroy.