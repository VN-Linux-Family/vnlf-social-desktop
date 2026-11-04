#!/usr/bin/env bash
set -euo pipefail

BASE_URL="https://vietnamlinuxfamily.net/api/v1"
USER_AGENT="vlf-flutter-dev/0.1 (unofficial community client)"
LIVE_DIR="$HOME/vlf-reference/live"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$LIVE_DIR"

cleanup() {
  rm -rf "$LIVE_DIR"
}
trap cleanup EXIT

ENDPOINTS=(
  "feed|feed?type=latest&limit=2"
  "leaderboards|leaderboards?period=week"
  "projects|projects?sort=featured"
  "channels|channels"
  "discover|discover"
)

first=true
for item in "${ENDPOINTS[@]}"; do
  name="${item%%|*}"
  path="${item#*|}"
  url="${BASE_URL}/${path}"
  out_file="${LIVE_DIR}/${name}.json"

  if [ "$first" = true ]; then
    first=false
  else
    sleep 2
  fi

  curl -sSL --fail --max-time 20 \
    -H "User-Agent: ${USER_AGENT}" \
    -H "Accept: application/json" \
    "${url}" -o "${out_file}"
done

for item in "${ENDPOINTS[@]}"; do
  name="${item%%|*}"
  out_file="${LIVE_DIR}/${name}.json"
  if [ -f "$out_file" ]; then
    echo "=== Live shape: ${name} ==="
    (cd "${REPO_ROOT}" && dart run tool/shape_check.dart "${out_file}")
    echo ""
  fi
done

echo "=== Shape Diffs against test/fixtures/ ==="
for item in "${ENDPOINTS[@]}"; do
  name="${item%%|*}"
  out_file="${LIVE_DIR}/${name}.json"
  fixture="${REPO_ROOT}/test/fixtures/${name}.json"
  if [ -f "$out_file" ] && [ -f "$fixture" ]; then
    echo "--- Diff: ${name} (live vs ${name}.json) ---"
    (cd "${REPO_ROOT}" && dart run tool/shape_check.dart --diff "${out_file}" "${fixture}" || true)
    echo ""
  fi
done
