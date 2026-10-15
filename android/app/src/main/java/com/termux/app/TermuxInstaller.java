package com.termux.app;

/**
 * JNI entry point exported by the official Termux libtermux-bootstrap.so.
 * Keep this package/class/method name aligned with
 * Java_com_termux_app_TermuxInstaller_getZip in termux-bootstrap.c.
 */
public final class TermuxInstaller {
    static {
        System.loadLibrary("termux-bootstrap");
    }

    private TermuxInstaller() {}

    public static native byte[] getZip();
}
