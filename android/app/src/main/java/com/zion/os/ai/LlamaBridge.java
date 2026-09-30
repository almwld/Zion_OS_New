package com.zion.os.ai;

public final class LlamaBridge {
    static { System.loadLibrary("llama_jni"); }

    public native boolean nativeLoadModel(String modelPath, int threads);
    public native String nativeGenerate(String prompt, int maxTokens, float temperature);
    public native void nativeFreeModel();
    public native boolean nativeIsLoaded();
    public native String nativeVersion();
}
