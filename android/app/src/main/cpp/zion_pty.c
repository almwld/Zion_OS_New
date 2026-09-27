#include <jni.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>

static int g_master_fd = -1;
static pid_t g_child_pid = -1;

static int set_winsize(int fd, int rows, int cols) {
    struct winsize ws;
    memset(&ws, 0, sizeof(ws));
    ws.ws_row = (unsigned short)(rows > 0 ? rows : 24);
    ws.ws_col = (unsigned short)(cols > 0 ? cols : 80);
    return ioctl(fd, TIOCSWINSZ, &ws);
}

JNIEXPORT jboolean JNICALL
Java_com_zion_os_MainActivity_nativePtyAvailable(JNIEnv *env, jobject thiz) {
    (void)env; (void)thiz;
    int fd = open("/dev/ptmx", O_RDWR | O_NOCTTY | O_CLOEXEC);
    if (fd < 0) return JNI_FALSE;
    close(fd);
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_zion_os_MainActivity_nativeStartPty(JNIEnv *env, jobject thiz, jint rows, jint cols) {
    (void)env; (void)thiz;
    if (g_master_fd >= 0) return JNI_TRUE;

    int master = open("/dev/ptmx", O_RDWR | O_NOCTTY | O_CLOEXEC);
    if (master < 0) return JNI_FALSE;
    if (grantpt(master) != 0 || unlockpt(master) != 0) {
        close(master);
        return JNI_FALSE;
    }

    char slave_name[128];
    if (ptsname_r(master, slave_name, sizeof(slave_name)) != 0) {
        close(master);
        return JNI_FALSE;
    }

    pid_t pid = fork();
    if (pid < 0) {
        close(master);
        return JNI_FALSE;
    }

    if (pid == 0) {
        int slave = open(slave_name, O_RDWR | O_NOCTTY);
        if (slave < 0) _exit(127);

        setsid();
#ifdef TIOCSCTTY
        ioctl(slave, TIOCSCTTY, 0);
#endif
        set_winsize(slave, rows, cols);
        dup2(slave, STDIN_FILENO);
        dup2(slave, STDOUT_FILENO);
        dup2(slave, STDERR_FILENO);
        if (slave > STDERR_FILENO) close(slave);

        setenv("TERM", "xterm-256color", 1);
        setenv("ZION_TERMINAL", "1", 1);
        setenv("PATH", "/system/bin:/system/xbin", 1);
        if (!getenv("HOME")) setenv("HOME", "/data/local/tmp", 1);

        execl("/system/bin/sh", "sh", "-i", (char *)NULL);
        _exit(127);
    }

    g_master_fd = master;
    g_child_pid = pid;
    return JNI_TRUE;
}

JNIEXPORT jbyteArray JNICALL
Java_com_zion_os_MainActivity_nativeReadPty(JNIEnv *env, jobject thiz) {
    (void)thiz;
    if (g_master_fd < 0) return NULL;

    unsigned char buffer[4096];
    ssize_t n;
    do {
        n = read(g_master_fd, buffer, sizeof(buffer));
    } while (n < 0 && errno == EINTR);

    if (n <= 0) return NULL;

    jbyteArray out = (*env)->NewByteArray(env, (jsize)n);
    if (!out) return NULL;
    (*env)->SetByteArrayRegion(env, out, 0, (jsize)n, (const jbyte *)buffer);
    return out;
}

JNIEXPORT jint JNICALL
Java_com_zion_os_MainActivity_nativeWritePty(JNIEnv *env, jobject thiz, jbyteArray data) {
    (void)thiz;
    if (g_master_fd < 0 || !data) return -1;

    jsize len = (*env)->GetArrayLength(env, data);
    jbyte *bytes = (*env)->GetByteArrayElements(env, data, NULL);
    if (!bytes) return -1;

    jsize written = 0;
    while (written < len) {
        ssize_t n = write(g_master_fd, bytes + written, (size_t)(len - written));
        if (n > 0) {
            written += (jsize)n;
        } else if (n < 0 && errno == EINTR) {
            continue;
        } else {
            break;
        }
    }

    (*env)->ReleaseByteArrayElements(env, data, bytes, JNI_ABORT);
    return written;
}

JNIEXPORT jboolean JNICALL
Java_com_zion_os_MainActivity_nativeResizePty(JNIEnv *env, jobject thiz, jint rows, jint cols) {
    (void)env; (void)thiz;
    if (g_master_fd < 0) return JNI_FALSE;
    return set_winsize(g_master_fd, rows, cols) == 0 ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT void JNICALL
Java_com_zion_os_MainActivity_nativeStopPty(JNIEnv *env, jobject thiz) {
    (void)env; (void)thiz;
    int fd = g_master_fd;
    pid_t pid = g_child_pid;
    g_master_fd = -1;
    g_child_pid = -1;

    if (fd >= 0) close(fd);
    if (pid > 0) {
        kill(pid, SIGHUP);
        kill(pid, SIGTERM);
        int reaped = 0;
        for (int i = 0; i < 25; ++i) {
            pid_t result = waitpid(pid, NULL, WNOHANG);
            if (result == pid) {
                reaped = 1;
                break;
            }
            if (result < 0 && errno == ECHILD) {
                reaped = 1;
                break;
            }
            usleep(10000);
        }
        if (!reaped) {
            kill(pid, SIGKILL);
            waitpid(pid, NULL, 0);
        }
    }
}
