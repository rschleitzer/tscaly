#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# runwatch.sh — run one measurement under /usr/bin/time with a hard memory and
# time limit, sampling the process every 5 s.
#
#   runwatch.sh <tag> <max-seconds> <max-footprint-mb> -- <command...>
#
# Writes into the current directory: <tag>.out (stdout), <tag>.time (time's
# report), <tag>.mem (elapsed seconds and footprint MB per sample) and
# <tag>.status (exit code, whether and why the watcher killed it).
#
# ★★★ THE LIMIT IS ON THE FOOTPRINT, NOT ON RSS. On macOS the memory compressor
# takes pages out of the resident set, so RSS FALLS while the process grows:
# measured 2026-09-16, tscaly on VS Code showed 7 GB RSS beside a 23 GB
# footprint, the machine swapped, and an RSS limit of 20 GB never fired. On
# macOS the sample is `footprint -p`; elsewhere RSS is the best available.
# Keep the limit well below the machine's memory.

set -u
if [ "$#" -lt 5 ] || [ "$4" != "--" ]; then
  echo "usage: runwatch.sh <tag> <max-seconds> <max-footprint-mb> -- <command...>" >&2
  exit 2
fi
TAG=$1; MAXS=$2; MAXMB=$3; shift 4
ulimit -s 65520

/usr/bin/time -l "$@" > "$TAG.out" 2> "$TAG.time" &
TPID=$!
CPID=""
for _ in 1 2 3 4 5 6 7 8 9 10; do
  CPID=$(pgrep -P "$TPID" | head -1)
  [ -n "$CPID" ] && break
  sleep 0.2
done

sample_mb() {
  local pid=$1
  if command -v footprint > /dev/null 2>&1; then
    footprint -p "$pid" 2> /dev/null | awk '/Footprint:/ {
      for (i = 1; i <= NF; i++) if ($i == "Footprint:") { v = $(i+1); u = $(i+2) }
      if (u == "GB") v = v * 1024; else if (u == "KB") v = v / 1024; else if (u == "B") v = 0
      printf "%d\n", v; exit }'
  else
    ps -o rss= -p "$pid" 2> /dev/null | awk '{ printf "%d\n", $1 / 1024 }'
  fi
}

START=$(date +%s)
: > "$TAG.mem"
REASON=exited
while kill -0 "$TPID" 2> /dev/null; do
  EL=$(( $(date +%s) - START ))
  MB=""
  [ -n "$CPID" ] && MB=$(sample_mb "$CPID")
  echo "$EL ${MB:-0}" >> "$TAG.mem"
  if [ -n "$MB" ] && [ "$MB" -gt "$MAXMB" ]; then
    REASON="killed: footprint ${MB} MB > ${MAXMB} MB"
    kill -9 "$CPID" 2> /dev/null
    break
  fi
  if [ "$EL" -gt "$MAXS" ]; then
    REASON="killed: ${EL} s > ${MAXS} s"
    kill -9 "$CPID" 2> /dev/null
    break
  fi
  sleep 5
done
wait "$TPID"
RC=$?
echo "rc=$RC $REASON elapsed=$(( $(date +%s) - START ))s" > "$TAG.status"
cat "$TAG.status"
