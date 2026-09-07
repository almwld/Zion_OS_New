package com.zion.os

internal object PtyNative {
    init {
        System.loadLibrary("zionpty")
    }

    external fun start(shell: String, rows: Int, cols: Int): Int
    external fun pid(): Int
    external fun resize(masterFd: Int, rows: Int, cols: Int): Int
    external fun stop(pid: Int, masterFd: Int): Int
}
