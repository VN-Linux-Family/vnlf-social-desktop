#!/usr/bin/env bash
# One bounded local build/test process tree across every VNLF worktree.
set -euo pipefail
if [[ $# -eq 0 ]]; then
  echo 'Usage: tool/with_build_slot.sh COMMAND [ARG ...]' >&2
  exit 64
fi
slot_file="${VNLF_BUILD_LOCK_FILE:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/vnlf-local-build.lock}"
exec 9>"$slot_file"
if ! flock -n 9; then
  echo 'The local build slot is busy. Wait for the current VNLF build/test to finish.' >&2
  exit 75
fi
cpu_list="$(python3 -c 'import os; print(",".join(map(str, sorted(os.sched_getaffinity(0))[:2])))')"
export CMAKE_BUILD_PARALLEL_LEVEL=2
export CARGO_BUILD_JOBS=2
exec ionice -c 2 -n 7 taskset -c "$cpu_list" nice -n 10 "$@"
