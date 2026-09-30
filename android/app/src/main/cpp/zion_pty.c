#include <jni.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/prctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>

#define ZION_MAX_PTY_SESSIONS 8

typedef struct {
    int master_fd;
    pid_t child_pid;
} ZionPtySession;

static ZionPtySession g_sessions[ZION_MAX_PTY_SESSIONS];
static pthread_mutex_t g_sessions_lock = PTHREAD_MUTEX_INITIALIZER;

static void init_sessions(void) {
    static int initialized = 0;
    if (initialized) return;
    for (int i = 0; i < ZION_MAX_PTY_SESSIONS; ++i) {
        g_sessions[i].master_fd = -1;
        g_sessions[i].child_pid = -1;
    }
    initialized = 1;
}

static ZionPtySession *get_session(jint handle) {
    init_sessions();
    if (handle <= 0 || handle > ZION_MAX_PTY_SESSIONS) return NULL;
    ZionPtySession *session = &g_sessions[handle - 1];
    return session->master_fd >= 0 ? session : NULL;
}

static int set_winsize(int fd, int rows, int cols) {
    struct winsize ws;
    memset(&ws, 0, sizeof(ws));
    ws.ws_row = (unsigned short)(rows > 0 ? rows : 24);
    ws.ws_col = (unsigned short)(cols > 0 ? cols : 80);
    return ioctl(fd, TIOCSWINSZ, &ws);
}

static void mkdir_p(const char *path, mode_t mode) {
    char buffer[512];
    size_t length = strlen(path);
    if (length == 0 || length >= sizeof(buffer)) return;
    memcpy(buffer, path, length + 1);
    for (char *p = buffer + 1; *p; ++p) {
        if (*p != '/') continue;
        *p = '\\0';
        (void)mkdir(buffer, mode);
        *p = '/';
    }
    (void)mkdir(buffer, mode);
}

static void prepare_environment(void) {
    const char *home = "/data/data/com.zion.os/files/home";
    const char *prefix = "/data/data/com.zion.os/files/usr";
    const char *path = "/data/data/com.zion.os/files/usr/bin:/data/data/com.zion.os/files/usr/sbin:/system/bin:/system/xbin";
    const char *directories[] = {
        "/data/data/com.zion.os/files/home",
        "/data/data/com.zion.os/files/tmp",
        "/data/data/com.zion.os/files/etc",
        "/data/data/com.zion.os/files/home/storage",
        "/data/data/com.zion.os/files/usr",
        "/data/data/com.zion.os/files/usr/bin",
        "/data/data/com.zion.os/files/usr/sbin",
        "/data/data/com.zion.os/files/usr/etc",
        "/data/data/com.zion.os/files/usr/include",
        "/data/data/com.zion.os/files/usr/lib",
        "/data/data/com.zion.os/files/usr/libexec",
        "/data/data/com.zion.os/files/usr/share",
        "/data/data/com.zion.os/files/usr/tmp",
        "/data/data/com.zion.os/files/usr/var",
        "/data/data/com.zion.os/files/usr/var/lib",
        "/data/data/com.zion.os/files/usr/var/lib/zion-pkg",
        "/data/data/com.zion.os/files/usr/var/cache",
        "/data/data/com.zion.os/files/usr/var/log",
    };
    for (size_t i = 0; i < sizeof(directories) / sizeof(directories[0]); ++i) {
        mkdir_p(directories[i], 0700);
    }
    setenv("HOME", home, 1);
    setenv("PREFIX", prefix, 1);
    setenv("TERMUX_HOME", home, 1);
    setenv("PATH", path, 1);
    setenv("TERM", "xterm-256color", 1);
    setenv("COLORTERM", "truecolor", 1);
    setenv("LANG", "C.UTF-8", 1);
    setenv("LC_ALL", "C.UTF-8", 1);
    setenv("SHELL", "/system/bin/sh", 1);
    setenv("ZION_TERMINAL", "1", 1);
}

static int is_allowed_shell(const char *shell) {
    if (shell == NULL || shell[0] == '\\0') return 0;
    return strcmp(shell, "/system/bin/sh") == 0 ||
           strcmp(shell, "/data/data/com.zion.os/files/usr/bin/bash") == 0 ||
           strcmp(shell, "/data/data/com.zion.os/files/usr/bin/zsh") == 0 ||
           strcmp(shell, "/data/data/com.zion.os/files/usr/bin/fish") == 0 ||
           strcmp(shell, "/data/data/com.zion.os/files/usr/bin/ash") == 0;
}

static void exec_best_shell(const char *configured_shell) {
    if (!is_allowed_shell(configured_shell)) configured_shell = NULL;
    const char *configured = configured_shell;
    const char *candidates[] = {
        configured,
        "/data/data/com.zion.os/files/usr/bin/bash",
        "/data/data/com.zion.os/files/usr/bin/zsh",
        "/data/data/com.zion.os/files/usr/bin/fish",
        "/data/data/com.zion.os/files/usr/bin/ash",
        "/system/bin/sh",
        NULL
    };

    for (int i = 0; candidates[i] != NULL; ++i) {
        if (candidates[i][0] == '\0') continue;
        if (access(candidates[i], X_OK) != 0) continue;
        const char *name = strrchr(candidates[i], '/');
        name = name ? name + 1 : candidates[i];
        setenv("SHELL", candidates[i], 1);
        execl(candidates[i], name, "-i", (char *)NULL);
    }
    _exit(127);
}

JNIEXPORT jboolean JNICALL
Java_com_zion_os_MainActivity_nativePtyAvailable(JNIEnv *env, jobject thiz) {
    (void)env; (void)thiz;
    int fd = open("/dev/ptmx", O_RDWR | O_NOCTTY | O_CLOEXEC);
    if (fd < 0) return JNI_FALSE;
    close(fd);
    return JNI_TRUE;
}

JNIEXPORT jint JNICALL
Java_com_zion_os_MainActivity_nativeStartPty(JNIEnv *env, jobject thiz, jint rows, jint cols, jstring shell_arg) {
    (void)thiz;
    char configured_shell[128] = {0};
    if (shell_arg != NULL) {
        const char *raw = (*env)->GetStringUTFChars(env, shell_arg, NULL);
        if (raw != NULL) {
            size_t length = strlen(raw);
            if (length < sizeof(configured_shell)) {
                memcpy(configured_shell, raw, length);
                configured_shell[length] = '\\0';
            }
            (*env)->ReleaseStringUTFChars(env, shell_arg, raw);
        }
    }
    pthread_mutex_lock(&g_sessions_lock);
    init_sessions();

    int slot = -1;
    for (int i = 0; i < ZION_MAX_PTY_SESSIONS; ++i) {
        if (g_sessions[i].master_fd < 0) {
            slot = i;
            break;
        }
    }
    if (slot < 0) {
        pthread_mutex_unlock(&g_sessions_lock);
        return 0;
    }

    int master = open("/dev/ptmx", O_RDWR | O_NOCTTY | O_CLOEXEC | O_NONBLOCK);
    if (master < 0) {
        pthread_mutex_unlock(&g_sessions_lock);
        return 0;
    }
    if (grantpt(master) != 0 || unlockpt(master) != 0) {
        close(master);
        pthread_mutex_unlock(&g_sessions_lock);
        return 0;
    }

    char slave_name[128];
    if (ptsname_r(master, slave_name, sizeof(slave_name)) != 0) {
        close(master);
        pthread_mutex_unlock(&g_sessions_lock);
        return 0;
    }

    pid_t pid = fork();
    if (pid < 0) {
        close(master);
        pthread_mutex_unlock(&g_sessions_lock);
        return 0;
    }

    if (pid == 0) {
        pthread_mutex_unlock(&g_sessions_lock);
        // The child owns the slave side only. Keeping the PTY master open in
        // the child can prevent EOF/EIO from reaching the Flutter reader and
        // can leave a stopped shell session looking alive.
        close(master);
        int slave = open(slave_name, O_RDWR | O_NOCTTY);
        if (slave < 0) _exit(127);

        prctl(PR_SET_PDEATHSIG, SIGHUP);
        setsid();
#ifdef TIOCSCTTY
        ioctl(slave, TIOCSCTTY, 0);
#endif
        set_winsize(slave, rows, cols);
        dup2(slave, STDIN_FILENO);
        dup2(slave, STDOUT_FILENO);
        dup2(slave, STDERR_FILENO);
        if (slave > STDERR_FILENO) close(slave);

        prepare_environment();
        chdir("/data/data/com.zion.os/files/home");
        exec_best_shell(configured_shell[0] == '\\0' ? NULL : configured_shell);
    }

    g_sessions[slot].master_fd = master;
    g_sessions[slot].child_pid = pid;
    pthread_mutex_unlock(&g_sessions_lock);
    return slot + 1;
}

JNIEXPORT jbyteArray JNICALL
Java_com_zion_os_MainActivity_nativeReadPty(JNIEnv *env, jobject thiz, jint handle) {
    (void)thiz;
    pthread_mutex_lock(&g_sessions_lock);
    ZionPtySession *session = get_session(handle);
    if (!session) {
        pthread_mutex_unlock(&g_sessions_lock);
        return NULL;
    }

    unsigned char buffer[8192];
    ssize_t n = read(session->master_fd, buffer, sizeof(buffer));
    if (n > 0) {
        jbyteArray out = (*env)->NewByteArray(env, (jsize)n);
        if (!out) {
            pthread_mutex_unlock(&g_sessions_lock);
            return NULL;
        }
        (*env)->SetByteArrayRegion(env, out, 0, (jsize)n, (const jbyte *)buffer);
        pthread_mutex_unlock(&g_sessions_lock);
        return out;
    }
    if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR)) {
        pthread_mutex_unlock(&g_sessions_lock);
        return (*env)->NewByteArray(env, 0);
    }

    // EIO/EOF means the slave side closed. Close and reap so the native slot
    // is reusable and the child cannot become a zombie.
    pid_t pid = session->child_pid;
    int fd = session->master_fd;
    session->master_fd = -1;
    session->child_pid = -1;
    if (fd >= 0) close(fd);
    if (pid > 0) {
        int status = 0;
        (void)waitpid(pid, &status, WNOHANG);
    }
    pthread_mutex_unlock(&g_sessions_lock);
    return NULL;
}

JNIEXPORT jint JNICALL
Java_com_zion_os_MainActivity_nativeWritePty(JNIEnv *env, jobject thiz, jint handle, jbyteArray data) {
    (void)thiz;
    pthread_mutex_lock(&g_sessions_lock);
    ZionPtySession *session = get_session(handle);
    if (!session || !data) {
        pthread_mutex_unlock(&g_sessions_lock);
        return -1;
    }

    jsize len = (*env)->GetArrayLength(env, data);
    jbyte *bytes = (*env)->GetByteArrayElements(env, data, NULL);
    if (!bytes) {
        pthread_mutex_unlock(&g_sessions_lock);
        return -1;
    }

    jsize written = 0;
    while (written < len) {
        struct pollfd pfd = {session->master_fd, POLLOUT, 0};
        int ready = poll(&pfd, 1, 1000);
        if (ready <= 0) break;
        ssize_t n = write(session->master_fd, bytes + written, (size_t)(len - written));
        if (n > 0) written += (jsize)n;
        else if (n < 0 && errno == EINTR) continue;
        else break;
    }

    (*env)->ReleaseByteArrayElements(env, data, bytes, JNI_ABORT);
    pthread_mutex_unlock(&g_sessions_lock);
    return written;
}

JNIEXPORT jboolean JNICALL
Java_com_zion_os_MainActivity_nativeResizePty(JNIEnv *env, jobject thiz, jint handle, jint rows, jint cols) {
    (void)env; (void)thiz;
    pthread_mutex_lock(&g_sessions_lock);
    ZionPtySession *session = get_session(handle);
    if (!session) {
        pthread_mutex_unlock(&g_sessions_lock);
        return JNI_FALSE;
    }
    int ok = set_winsize(session->master_fd, rows, cols) == 0;
    pthread_mutex_unlock(&g_sessions_lock);
    return ok ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT void JNICALL
Java_com_zion_os_MainActivity_nativeStopPty(JNIEnv *env, jobject thiz, jint handle) {
    (void)env; (void)thiz;
    pthread_mutex_lock(&g_sessions_lock);
    ZionPtySession *session = get_session(handle);
    if (!session) {
        pthread_mutex_unlock(&g_sessions_lock);
        return;
    }

    int fd = session->master_fd;
    pid_t pid = session->child_pid;
    session->master_fd = -1;
    session->child_pid = -1;
    if (fd >= 0) close(fd);
    pthread_mutex_unlock(&g_sessions_lock);

    if (pid > 0) {
        kill(-pid, SIGHUP);
        kill(-pid, SIGTERM);
        int reaped = 0;
        for (int i = 0; i < 50; ++i) {
            pid_t result = waitpid(pid, NULL, WNOHANG);
            if (result == pid || (result < 0 && errno == ECHILD)) {
                reaped = 1;
                break;
            }
            usleep(10000);
        }
        if (!reaped) {
            kill(-pid, SIGKILL);
            kill(pid, SIGKILL);
            waitpid(pid, NULL, 0);
        }
    }
}
