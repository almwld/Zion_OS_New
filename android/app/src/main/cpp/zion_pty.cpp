#include <jni.h>
#include <pty.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <unistd.h>
#include <cerrno>

namespace {
pid_t g_child_pid = -1;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_zion_os_PtyNative_start(JNIEnv* env, jclass, jstring shell, jint rows, jint cols) {
    const char* shell_chars = env->GetStringUTFChars(shell, nullptr);
    if (shell_chars == nullptr) return -1;

    struct winsize ws{};
    ws.ws_row = static_cast<unsigned short>(rows > 0 ? rows : 24);
    ws.ws_col = static_cast<unsigned short>(cols > 0 ? cols : 80);

    int master = -1;
    const pid_t pid = forkpty(&master, nullptr, nullptr, &ws);
    if (pid < 0) {
        env->ReleaseStringUTFChars(shell, shell_chars);
        return -errno;
    }

    if (pid == 0) {
        setenv("TERM", "xterm-256color", 1);
        setenv("COLORTERM", "truecolor", 1);
        execl(shell_chars, shell_chars, "-i", static_cast<char*>(nullptr));
        _exit(127);
    }

    env->ReleaseStringUTFChars(shell, shell_chars);
    g_child_pid = pid;
    return master;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_zion_os_PtyNative_pid(JNIEnv*, jclass) {
    return static_cast<jint>(g_child_pid);
}

extern "C" JNIEXPORT jint JNICALL
Java_com_zion_os_PtyNative_resize(JNIEnv*, jclass, jint master, jint rows, jint cols) {
    if (master < 0) return -EINVAL;
    struct winsize ws{};
    ws.ws_row = static_cast<unsigned short>(rows > 0 ? rows : 24);
    ws.ws_col = static_cast<unsigned short>(cols > 0 ? cols : 80);
    return ioctl(master, TIOCSWINSZ, &ws) == 0 ? 0 : -errno;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_zion_os_PtyNative_stop(JNIEnv*, jclass, jint pid) {
    int rc = 0;
    if (pid > 0 && kill(static_cast<pid_t>(pid), SIGHUP) != 0 && errno != ESRCH) {
        rc = -errno;
    }
    if (g_child_pid == static_cast<pid_t>(pid)) g_child_pid = -1;
    return rc;
}
