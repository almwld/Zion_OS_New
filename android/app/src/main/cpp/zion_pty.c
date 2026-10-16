#include <jni.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <sys/prctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>

#ifndef MFD_CLOEXEC
#define MFD_CLOEXEC 0x0001U
#endif

extern char **environ;

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

static void configure_terminal(int fd) {
    struct termios settings;
    if (tcgetattr(fd, &settings) != 0) return;

    // Do not rely on the PTY driver's inherited defaults: some Android builds
    // expose a slave with ECHO/ICANON disabled. In that state characters appear
    // to vanish when Enter submits a line, and shells can receive CR without
    // the expected line discipline processing.
    settings.c_iflag |= (ICRNL | IXON);
#ifdef IMAXBEL
    settings.c_iflag |= IMAXBEL;
#endif
    settings.c_oflag |= (OPOST | ONLCR);
    settings.c_lflag |= (ISIG | ICANON | ECHO | ECHOE | ECHOK);
#ifdef ECHOCTL
    settings.c_lflag |= ECHOCTL;
#endif
#ifdef IUTF8
    settings.c_iflag |= IUTF8;
#endif
    settings.c_cc[VERASE] = 0x7f;
    settings.c_cc[VKILL] = 0x15;
    settings.c_cc[VEOF] = 0x04;
    settings.c_cc[VINTR] = 0x03;
    settings.c_cc[VQUIT] = 0x1c;
    settings.c_cc[VSUSP] = 0x1a;
    (void)tcsetattr(fd, TCSANOW, &settings);
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
        *p = '\0';
        (void)mkdir(buffer, mode);
        *p = '/';
    }
    (void)mkdir(buffer, mode);
}

static void prepare_environment(void) {
    const char *home = "/data/data/com.zion.os/files/home";
    const char *prefix = "/data/data/com.zion.os/files/usr";
    const char *path = "/data/data/com.zion.os/files/usr/bin:/data/data/com.zion.os/files/usr/sbin:/system/bin:/system/xbin:/vendor/bin";
    const char *library_path = "/data/data/com.zion.os/files/usr/lib:/data/data/com.zion.os/files/usr/lib64";
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
    setenv("PATH", path, 1);
    setenv("LD_LIBRARY_PATH", library_path, 1);
    setenv("TERM", "xterm-256color", 1);
    setenv("COLORTERM", "truecolor", 1);
    setenv("PS1", "$ ", 1);
    setenv("LANG", "C.UTF-8", 1);
    setenv("LC_ALL", "C.UTF-8", 1);
    setenv("SHELL", "/data/data/com.zion.os/files/usr/bin/bash", 1);
    setenv("ZION_TERMINAL", "1", 1);
}

static int is_allowed_shell(const char *shell) {
    if (shell == NULL || shell[0] == '\0') return 0;
    return strncmp(shell, "kali:", 5) == 0 ||
           strcmp(shell, "/data/data/com.zion.os/files/usr/bin/bash") == 0 ||
           strcmp(shell, "/data/data/com.zion.os/files/usr/bin/zsh") == 0 ||
           strcmp(shell, "/data/data/com.zion.os/files/usr/bin/fish") == 0 ||
           strcmp(shell, "/data/data/com.zion.os/files/usr/bin/ash") == 0 ||
           strcmp(shell, "/system/bin/sh") == 0;
}

static const char *select_shell(const char *configured_shell) {
    if (configured_shell != NULL && strncmp(configured_shell, "kali:", 5) == 0) return configured_shell;
    if (is_allowed_shell(configured_shell) && access(configured_shell, X_OK) == 0) {
        return configured_shell;
    }

    static const char *fallbacks[] = {
        "/system/bin/sh",
        "/data/data/com.zion.os/files/usr/bin/bash",
        "/data/data/com.zion.os/files/usr/bin/zsh",
        "/data/data/com.zion.os/files/usr/bin/fish",
        "/data/data/com.zion.os/files/usr/bin/ash",
        NULL
    };
    for (int i = 0; fallbacks[i] != NULL; ++i) {
        if (access(fallbacks[i], X_OK) == 0) return fallbacks[i];
    }
    return NULL;
}

static void exec_kali_proot(const char *proot, const char *rootfs) {
    execl(proot, "proot",
          "--link2symlink", "-0", "-r", rootfs,
          "-b", "/dev", "-b", "/proc", "-b", "/sys",
          "-b", "/storage/emulated/0",
          "-b", "/data/data/com.zion.os/files/home:/root", "-w", "/root",
          "/usr/bin/env", "-i",
          "HOME=/root",
          "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
          "TERM=xterm-256color", "LANG=C.UTF-8", "LC_ALL=C.UTF-8",
          "SHELL=/bin/bash", "ZION_KALI=1",
          "/bin/bash", "--login", (char *)NULL);
    _exit(127);
}

/*
 * Best-effort fallback for direct execution of a private-files ELF. This is
 * not a SELinux bypass: Android kernels may prohibit executable memfds too.
 */
static void exec_via_memfd(const char *src_path, char *const argv[], char *const envp[]) {
#if defined(SYS_memfd_create)
    int src = open(src_path, O_RDONLY | O_CLOEXEC);
    if (src < 0) _exit(127);

    struct stat st;
    if (fstat(src, &st) != 0 || !S_ISREG(st.st_mode) || st.st_size <= 0) {
        close(src);
        _exit(127);
    }

    int fd = (int)syscall(SYS_memfd_create, "zion-shell", MFD_CLOEXEC);
    if (fd < 0) {
        close(src);
        _exit(127);
    }

    char buf[65536];
    for (;;) {
        ssize_t n = read(src, buf, sizeof(buf));
        if (n == 0) break;
        if (n < 0) {
            if (errno == EINTR) continue;
            close(src);
            close(fd);
            _exit(127);
        }
        ssize_t written = 0;
        while (written < n) {
            ssize_t w = write(fd, buf + written, (size_t)(n - written));
            if (w < 0 && errno == EINTR) continue;
            if (w <= 0) {
                close(src);
                close(fd);
                _exit(127);
            }
            written += w;
        }
    }
    close(src);

    if (fchmod(fd, 0700) != 0 || lseek(fd, 0, SEEK_SET) < 0) {
        close(fd);
        _exit(127);
    }

    fexecve(fd, argv, envp);
    close(fd);
#endif
    _exit(127);
}

static void exec_selected_shell(const char *shell_path) {
    if (shell_path == NULL || shell_path[0] == '\0') _exit(127);
    const char *name = shell_path;
    for (const char *p = shell_path; *p != '\0'; ++p) {
        if (*p == '/') name = p + 1;
    }
    char *const argv[] = {(char *)name, (char *)"-i", NULL};
    execl(shell_path, name, "-i", (char *)NULL);
    exec_via_memfd(shell_path, argv, environ);
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
    char configured_shell[512] = {0};
    char kali_proot[512] = {0};
    char kali_rootfs[512] = {0};
    char kali_loader[512] = {0};
    int kali_mode = 0;
    if (shell_arg != NULL) {
        const char *raw = (*env)->GetStringUTFChars(env, shell_arg, NULL);
        if (raw != NULL) {
            size_t length = strlen(raw);
            if (length < sizeof(configured_shell)) {
                memcpy(configured_shell, raw, length);
                configured_shell[length] = '\0';
            }
            (*env)->ReleaseStringUTFChars(env, shell_arg, raw);
        }
    }

    if (strncmp(configured_shell, "kali:", 5) == 0) {
        kali_mode = 1;
        const char *spec = configured_shell + 5;
        const char *sep1 = strchr(spec, '|');
        const char *sep2 = sep1 ? strchr(sep1 + 1, '|') : NULL;
        if (!sep1 || !sep2) return 0;
        size_t pLen = (size_t)(sep1 - spec);
        size_t rLen = (size_t)(sep2 - sep1 - 1);
        size_t lLen = strlen(sep2 + 1);
        if (pLen == 0 || pLen >= sizeof(kali_proot) ||
            rLen == 0 || rLen >= sizeof(kali_rootfs) ||
            lLen == 0 || lLen >= sizeof(kali_loader)) return 0;
        memcpy(kali_proot, spec, pLen); kali_proot[pLen] = '\0';
        memcpy(kali_rootfs, sep1 + 1, rLen); kali_rootfs[rLen] = '\0';
        memcpy(kali_loader, sep2 + 1, lLen); kali_loader[lLen] = '\0';
        if (access(kali_proot, X_OK) != 0 || access(kali_rootfs, R_OK) != 0 ||
            access(kali_loader, X_OK) != 0) return 0;
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

    // Prepare the base process environment before fork(). Android/Flutter is
    // heavily multi-threaded; calling malloc-backed functions such as
    // setenv()/mkdir() in the post-fork child can deadlock or crash.
    prepare_environment();
    const char *selected_shell = select_shell(configured_shell[0] == '\0' ? NULL : configured_shell);
    if (selected_shell == NULL) {
        close(master);
        pthread_mutex_unlock(&g_sessions_lock);
        return 0;
    }
    setenv("SHELL", selected_shell, 1);
    if (kali_mode) {
        setenv("PROOT_LOADER", kali_loader, 1);
        setenv("PROOT_TMP_DIR", "/data/data/com.zion.os/files/zion/tmp", 1);
        mkdir_p("/data/data/com.zion.os/files/zion/tmp", 0700);
        setenv("ZION_SHELL_MODE", "kali-proot", 1);
    } else if (strcmp(selected_shell, "/system/bin/sh") == 0) {
        // Android host-shell mode is intentionally independent of the broken
        // Userland prefix: keep PATH limited to Android's shipped commands.
        setenv("HOME", "/data/data/com.zion.os/files/home", 1);
        setenv("TMPDIR", "/data/data/com.zion.os/files/tmp", 1);
        setenv("PATH", "/system/bin:/system/xbin:/vendor/bin", 1);
        setenv("LD_LIBRARY_PATH", "", 1);
        setenv("TERM", "xterm-256color", 1);
        setenv("COLORTERM", "truecolor", 1);
        setenv("SHELL", "/system/bin/sh", 1);
        // Keep a conventional, stable Android shell prompt with no path prefix.
        setenv("PS1", "$ ", 1);
        setenv("ZION_SHELL_MODE", "android-system", 1);
    } else {
        setenv("ZION_SHELL_MODE", "zion-userland", 1);
    }

    pid_t pid = fork();
    if (pid < 0) {
        close(master);
        pthread_mutex_unlock(&g_sessions_lock);
        return 0;
    }

    if (pid == 0) {
        // After fork(), never unlock g_sessions_lock here: if another thread
        // held it at fork time, the inherited pthread mutex is not safely
        // unlockable in the child and can deadlock the PTY process.
        // The child owns the slave side only. Keeping the PTY master open in
        // the child can prevent EOF/EIO from reaching the Flutter reader and
        // can leave a stopped shell session looking alive.
        close(master);
        int slave = open(slave_name, O_RDWR | O_NOCTTY);
        if (slave < 0) _exit(127);
        configure_terminal(slave);

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

        if (chdir("/data/data/com.zion.os/files/home") != 0) {
            _exit(126);
        }
        if (kali_mode) exec_kali_proot(kali_proot, kali_rootfs);
        exec_selected_shell(selected_shell);
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
    if (data == NULL) return -1;

    // Duplicate the master descriptor while the session table is locked, then
    // release the global lock before polling/writing. A slow paste must never
    // stall PTY readers, resize, or teardown for every terminal session.
    pthread_mutex_lock(&g_sessions_lock);
    ZionPtySession *session = get_session(handle);
    if (!session) {
        pthread_mutex_unlock(&g_sessions_lock);
        return -1;
    }
    int fd = dup(session->master_fd);
    pthread_mutex_unlock(&g_sessions_lock);
    if (fd < 0) return -1;

    jsize len = (*env)->GetArrayLength(env, data);
    jbyte *bytes = (*env)->GetByteArrayElements(env, data, NULL);
    if (!bytes) {
        close(fd);
        return -1;
    }

    jsize written = 0;
    while (written < len) {
        struct pollfd pfd = {fd, POLLOUT, 0};
        int ready = poll(&pfd, 1, 1000);
        if (ready < 0 && errno == EINTR) continue;
        if (ready <= 0 || (pfd.revents & (POLLERR | POLLHUP | POLLNVAL)) != 0) break;
        ssize_t n = write(fd, bytes + written, (size_t)(len - written));
        if (n > 0) written += (jsize)n;
        else if (n < 0 && (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK)) continue;
        else break;
    }

    (*env)->ReleaseByteArrayElements(env, data, bytes, JNI_ABORT);
    close(fd);
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
