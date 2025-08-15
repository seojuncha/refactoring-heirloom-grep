#!/usr/bin/env bash
# Minimal smoke tests for grep (basic, -n, -i, -v, multi-file, long line, no-newline)
set -euo pipefail

# Path to the grep binary to test (local build is preferred)
G="${G:-./grep}"
SYS_GREP="${SYS_GREP:-/bin/grep}"

if [[ ! -x "$G" ]]; then
  echo "[Error] $G is not executable. Set environment variable G or build ./grep."
  exit 1
fi
if [[ ! -x "$SYS_GREP" ]]; then
  echo "[Error] System grep ($SYS_GREP) not found."
  exit 1
fi

# Check if required test input files exist
need_files=(tests/small.txt tests/multi.txt tests/case.txt tests/longline.txt tests/no_newline.txt)
for f in "${need_files[@]}"; do
  [[ -f "$f" ]] || { echo "[Error] Missing: $f"; exit 1; }
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Helper: Compare stdout of local grep vs system grep
check() {
  local name="$1"; shift
  local cmd_local=("$@")
  local cmd_sys=("${cmd_local[@]}")
  cmd_sys[0]="$SYS_GREP"

  # Capture outputs
  if ! "${cmd_local[@]}" >"$tmp/out_local" 2>"$tmp/err_local"; then :; fi
  if ! "${cmd_sys[@]}"   >"$tmp/out_sys"   2>"$tmp/err_sys";   then :; fi

  # Compare stdout
  if ! diff -u "$tmp/out_sys" "$tmp/out_local" >"$tmp/diff_stdout"; then
    echo "[Fail] $name - stdout mismatch"
    echo "---- diff(stdout) ----"
    cat "$tmp/diff_stdout"
    exit 1
  fi
  echo "[Pass] $name"
}

# Helper: Only check if match exists, without comparing stdout
assert_match() {
  local name="$1"; shift
  if "${@}"; then
    echo "[Pass] $name"
  else
    echo "[Fail] $name - match not found or incorrect exit code"
    exit 1
  fi
}

echo "== Running minimal smoke tests =="

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

# 7) Very long line handling (buffer boundary check) - only existence check
assert_match "long line handling (-q)" "$G" -q "foo" tests/longline.txt

echo "All minimal smoke tests PASSED"