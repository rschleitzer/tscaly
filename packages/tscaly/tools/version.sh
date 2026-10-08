#!/bin/bash
# tools/version.sh -- the version of the tscaly package that is being worked
# on: the highest version directory under packages/tscaly. (A package's
# versions are directories, and the published ones may have left the tree for
# its history -- packages/tscaly/published names those.)
cd "$(dirname "$0")/.." || exit 2
v="$(ls . | grep '^[0-9][0-9.]*$' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)"
[ -n "$v" ] || { echo "version.sh: packages/tscaly holds no version directory" >&2; exit 1; }
echo "$v"
