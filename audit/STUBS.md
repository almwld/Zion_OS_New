# Stubs and Placeholder Implementations

S-01 features/terminal/cosmic_terminal.dart: six-line widget whose build method returns only static TERMINAL text.

S-02 zion_ota_system.dart: line 41 reports configuration false; line 50 returns null; download/install report unavailable.

S-03 screens/apps/notes_app.dart: line 471 local jsonDecode returns an empty list unconditionally.

S-04 android/app/src/main/cpp/llama_jni_stub.cpp is an explicit non-ARM64 fallback that reports the local AI engine is unsupported on that ABI. This is platform-specific by design, not a false success.

Other return-null or empty-list branches found by search were not classified as stubs without direct proof that they are unconditional placeholders.