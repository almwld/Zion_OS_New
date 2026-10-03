# Stubs and Placeholder Implementations — status refreshed 2026-10-03

S-01 **RESOLVED:** features/terminal/cosmic_terminal.dart now delegates to the canonical TerminalScreen.

S-02 **INTENTIONAL:** zion_ota_system.dart reports configuration unavailable and does not fabricate update/download/install success. It remains pending a trusted signed update source.

S-03 **RESOLVED:** notes_app.dart no longer contains an unconditional JSON decoder returning [].

S-04 **INTENTIONAL PLATFORM FALLBACK:** llama_jni_stub.cpp explicitly reports that the local AI engine is unsupported on non-ARM64; it does not claim success.

Other return-null or empty-list branches remain unclassified unless direct evidence proves they are unconditional placeholders.
