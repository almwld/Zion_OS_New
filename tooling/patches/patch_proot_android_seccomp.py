#!/usr/bin/env python3
"""Port Termux PRoot's cancelled-syscall/seccomp ordering fix to OpenMinis PRoot.

The OpenMinis fork has a different syscall translation implementation, so this
uses guarded, exact anchors instead of blindly applying an upstream patch.
It intentionally fails the build if the expected source shape changes.
"""
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
files = {
    "syscall": root / "src/syscall/syscall.c",
    "event": root / "src/tracee/event.c",
    "tracee": root / "src/tracee/tracee.h",
}
for name, path in files.items():
    if not path.is_file():
        raise SystemExit(f"[proot-seccomp-patch] missing {name} source: {path}")

def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"[proot-seccomp-patch] expected one anchor for {label}, found {count}")
    return text.replace(old, new, 1)

# Keep track of whether the syscall translator replaced a syscall with a
# negative avoider that the kernel cancels before reporting a ptrace entry stop.
p = files["tracee"]
s = p.read_text()
s = replace_once(
    s,
    "\tbool seccomp_already_handled_enter;\n",
    "\tbool seccomp_already_handled_enter;\n\n"
    "\t/* True when the kernel cancels a PRoot-voided syscall before the\n"
    "\t * expected ptrace sysenter stop; event.c must not swallow sysexit. */\n"
    "\tbool voided_syscall_cancelled;\n",
    "Tracee cancellation state",
)
p.write_text(s)

p = files["syscall"]
s = p.read_text()
anchor = "void translate_syscall(Tracee *tracee)\n{"
helpers = """/* On Android kernels where seccomp runs before the ptrace entry stop,
 * a negative syscall avoider cancels the syscall completely. */
static bool kernel_cancels_voided_syscall(void)
{
\treturn (long) SYSCALL_AVOIDER < 0;
}

static bool is_voided_syscall(const Tracee *tracee, RegVersion version)
{
\treturn peek_reg(tracee, version, SYSARG_NUM) == SYSCALL_AVOIDER
\t\t&& peek_reg(tracee, ORIGINAL, SYSARG_NUM) != SYSCALL_AVOIDER;
}

"""
s = replace_once(s, anchor, helpers + anchor, "syscall helper insertion")
s = replace_once(
    s,
    "\t\ttracee->restore_original_regs = false;\n",
    "\t\ttracee->restore_original_regs = false;\n"
    "\t\ttracee->voided_syscall_cancelled = false;\n",
    "reset cancellation state at syscall entry",
)
s = replace_once(
    s,
    "\tif (is_enter_stage)\n\t\tprint_current_regs(tracee, 5, \"sysenter end\" );",
    "\tif (is_enter_stage) {\n"
    "\t\t/* A negative avoider never reaches the kernel. On kernels that\n"
    "\t\t * evaluate seccomp before ptrace entry, no sysenter stop follows. */\n"
    "\t\ttracee->voided_syscall_cancelled = override_sysnum\n"
    "\t\t\t\t&& push_regs_status == 0\n"
    "\t\t\t\t&& kernel_cancels_voided_syscall()\n"
    "\t\t\t\t&& is_voided_syscall(tracee, CURRENT);\n"
    "\t\tprint_current_regs(tracee, 5, \"sysenter end\" );\n"
    "\t}",
    "record cancelled syscall before event loop",
)
p.write_text(s)

p = files["event"]
s = p.read_text()
s = replace_once(
    s,
    "if (!seccomp_after_ptrace_enter && tracee->restart_how == PTRACE_SYSCALL)\n"
    "\t\t\t\ttracee->seccomp_already_handled_enter = true;",
    "if (!seccomp_after_ptrace_enter && tracee->restart_how == PTRACE_SYSCALL\n"
    "\t\t\t    && !tracee->voided_syscall_cancelled)\n"
    "\t\t\t\ttracee->seccomp_already_handled_enter = true;",
    "do not swallow the next exit stop",
)
s = replace_once(
    s,
    "if (siginfo.si_code == SYS_SECCOMP) {\n",
    "if (siginfo.si_code == SYS_SECCOMP) {\n"
    "\t\t\t\t/* SECCOMP_RET_TRAP cancels the syscall; do not treat its\n"
    "\t\t\t\t * following stop as an already-handled sysenter. */\n"
    "\t\t\t\ttracee->seccomp_already_handled_enter = false;\n",
    "clear stale enter-stop state on SIGSYS",
)
p.write_text(s)

print("[proot-seccomp-patch] applied guarded Android seccomp/syscall-stop fix")
