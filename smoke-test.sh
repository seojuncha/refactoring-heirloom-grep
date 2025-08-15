#!/usr/bin/env bash
# Minimal smoke tests for grep with optional valgrind and per-test artifacts.
# Usage:
#   bash smoke-test.sh [--valgrind] [--outdir DIR] [--grep PATH] [--sys-grep PATH]
# Examples:
#   bash smoke-test.sh
#   bash smoke-test.sh --valgrind
#   bash smoke-test.sh --outdir artifacts/smoke-1 --valgrind
set -euo pipefail

# -------------------------------
# Defaults / CLI parsing
# -------------------------------
VALGRIND=0
OUTDIR=""
G="${G:-./grep}"
SYS_GREP="${SYS_GREP:-/bin/grep}"
VALGRIND_OPTS="${VALGRIND_OPTS:---leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=definite --error-exitcode=99}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --valgrind) VALGRIND=1; shift ;;
    --outdir) OUTDIR="${2:-}"; shift 2 ;;
    --grep) G="${2:-}"; shift 2 ;;
    --sys-grep) SYS_GREP="${2:-}"; shift 2 ;;
    -h|--help)
      sed -n '1,35p' "$0"
      exit 0
      ;;
    *)
      echo "[Error] Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "${OUTDIR}" ]]; then
  ts=$(date +%Y%m%d-%H%M%S)
  OUTDIR="out/smoke-${ts}"
fi

# -------------------------------
# Preconditions
# -------------------------------
if [[ ! -x "$G" ]]; then
  echo "[Error] $G is not executable. Build your grep or pass --grep PATH."
  exit 1
fi
if [[ ! -x "$SYS_GREP" ]]; then
  echo "[Error] System grep ($SYS_GREP) not found or not executable. Pass --sys-grep PATH."
  exit 1
fi

need_files=(tests/small.txt tests/multi.txt tests/case.txt tests/longline.txt tests/no_newline.txt)
for f in "${need_files[@]}"; do
  [[ -f "$f" ]] || { echo "[Error] Missing: $f"; exit 1; }
done

mkdir -p "$OUTDIR"

# -------------------------------
# Helpers
# -------------------------------
slugify() {
  # Convert test name to a filesystem-friendly slug
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '_' | sed 's/^_//; s/_$//'
}

run_with_capture() {
  # Args:
  #   $1: base path (without extension)
  #   "${@:2}": command to run
  # Captures stdout, stderr, exit code. Respects VALGRIND for the local grep (not for system grep).
  local base="$1"; shift
  local stdout="${base}.stdout"
  local stderr="${base}.stderr"
  local rcfile="${base}.rc"
  local vglog="${base}.valgrind.txt"

  # Disable immediate exit for this block to capture non-zero exit codes
  set +e
  if [[ $VALGRIND -eq 1 && "$1" == "$G" ]]; then
    # Wrap only the local grep under test
    valgrind $VALGRIND_OPTS --log-file="$vglog" "$@" >"$stdout" 2>"$stderr"
  else
    "$@" >"$stdout" 2>"$stderr"
  fi
  echo $? >"$rcfile"
  set -e
}

check() {
  # Compare stdout of local grep vs system grep for a given test case.
  # Args:
  #   $1: human-readable test name
  #   "${@:2}": command line with $G as the first element
  local name="$1"; shift
  local slug; slug="$(slugify "$name")"
  local base_local="${OUTDIR}/${slug}_local"
  local base_sys="${OUTDIR}/${slug}_sys"
  local base_diff="${OUTDIR}/${slug}"

  # Local under test
  run_with_capture "$base_local" "$@"
  # System baseline
  local sys_cmd=("$@")
  sys_cmd[0]="$SYS_GREP"
  run_with_capture "$base_sys" "${sys_cmd[@]}"

  # Diff stdout
  if ! diff -u "${base_sys}.stdout" "${base_local}.stdout" >"${base_diff}.diff_stdout" ; then
    echo "[Fail] $name - stdout mismatch"
    echo "See: ${base_diff}.diff_stdout"
    exit 1
  fi

  echo "[Pass] $name"
}

assert_match() {
  # Only check that the command succeeds in finding a match (exit code == 0).
  # Saves outputs per test as well.
  # Args:
  #   $1: human-readable test name
  #   "${@:2}": command line with $G as the first element
  local name="$1"; shift
  local slug; slug="$(slugify "$name")"
  local base_local="${OUTDIR}/${slug}_local"

  run_with_capture "$base_local" "$@"
  local rc; rc=$(cat "${base_local}.rc" || echo 1)
  if [[ "$rc" -eq 0 ]]; then
    echo "[Pass] $name"
  else
    echo "[Fail] $name - expected success (match), got exit code $rc"
    echo "See: ${base_local}.stdout, ${base_local}.stderr"
    exit 1
  fi
}

# -------------------------------
# Test Plan
# -------------------------------
echo "[Info] Output directory: $OUTDIR"
echo "[Info] Local grep: $G"
echo "[Info] System grep: $SYS_GREP"
echo "[Info] Valgrind: $([[ $VALGRIND -eq 1 ]] && echo ON || echo OFF)"

# 1) Basic match
check "basic match"         "$G" "foo" tests/small.txt

# 2) Line numbers (-n)
check "-n line numbers"     "$G" -n "foo" tests/multi.txt

# 3) Ignore case (-i) - ASCII only
check "-i ignore case"      "$G" -i "foo" tests/case.txt

# 4) Invert match (-v)
check "-v invert match"     "$G" -v "foo" tests/multi.txt

# 5) Multiple input files
check "multi-file inputs"   "$G" "foo" tests/small.txt tests/multi.txt

# 6) File without trailing newline
check "no newline at EOF"   "$G" "foo" tests/no_newline.txt

# 7) Very long line handling (buffer boundary check) - existence check only
assert_match "long line handling (-q)" "$G" -q "foo" tests/longline.txt

echo "All minimal smoke tests PASSED"