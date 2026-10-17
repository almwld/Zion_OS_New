#!/system/bin/sh
# Run on the Android device from Zion's Android system shell or terminal.
# Verifies the linker-backed Userland runtime without altering PREFIX.
set -u
PREFIX="/data/data/com.zion.os/files/usr"
HOME_DIR="/data/data/com.zion.os/files/home"
LINKER="/system/bin/linker64"
BASH_REAL="$PREFIX/bin/bash.real"
# bash.real was built with a Termux RUNPATH. Always point the Android linker
# at Zion's private libraries before asking it to resolve libreadline.so.8.
export PREFIX
export HOME="$HOME_DIR"
export LD_LIBRARY_PATH="$PREFIX/lib:$PREFIX/lib64:$PREFIX/libexec"
export TMPDIR="/data/data/com.zion.os/files/tmp"
export PATH="$PREFIX/bin:$PREFIX/sbin:/system/bin:/system/xbin:/vendor/bin"
fail=0

pass() { printf '[PASS] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
bad() { printf '[FAIL] %s\n' "$1"; fail=1; }

[ -x "$LINKER" ] && pass "Android linker exists" || bad "Android linker missing"
[ -f "$BASH_REAL" ] && pass "bash.real exists" || bad "bash.real missing"
[ -f "$PREFIX/bin/coreutils" ] && pass "coreutils multi-call binary exists" || warn "coreutils missing"
[ -f "$PREFIX/bin/curl" ] && pass "curl binary exists" || warn "curl missing"
[ -f "$PREFIX/etc/zion-bashrc" ] && pass "zion-bashrc exists" || bad "zion-bashrc missing"

if [ -x "$LINKER" ] && [ -f "$BASH_REAL" ]; then
  out=$("$LINKER" "$BASH_REAL" --version 2>&1)
  case "$out" in *"GNU bash"*) pass "Bash loads through linker64 with Zion LD_LIBRARY_PATH";; *) bad "Bash linker launch failed: $out";; esac

  cat > "$HOME_DIR/.zion-runtime-check.sh" <<'EOS'
set -e
printf 'ZION_SCRIPT_OK\n'
printf 'test\n' | grep test
printf '3\n1\n2\n' | sort -n
EOS
  if "$LINKER" "$BASH_REAL" "$HOME_DIR/.zion-runtime-check.sh" > "$HOME_DIR/.zion-runtime-check.out" 2>&1; then
    if /system/bin/toybox grep -q 'ZION_SCRIPT_OK' "$HOME_DIR/.zion-runtime-check.out" &&
       /system/bin/toybox grep -q '^test$' "$HOME_DIR/.zion-runtime-check.out"; then
      pass "Noninteractive script + linker-backed grep/sort"
    else
      bad "Script exited zero but expected output is missing"
      /system/bin/toybox cat "$HOME_DIR/.zion-runtime-check.out"
    fi
  else
    bad "Noninteractive Bash script failed"
    /system/bin/toybox cat "$HOME_DIR/.zion-runtime-check.out"
  fi
fi

printf '\nRuntime diagnostic exit=%s\n' "$fail"
exit "$fail"
