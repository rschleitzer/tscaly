#!/bin/bash
# tools/version.sh [package] -- the version of a package of the port that is
# being worked on (tscaly when none is named; tsbase, tsdriver): the highest
# version directory under packages/<package>. (A package's versions are
# directories, and the published ones may have left the tree for its history
# -- packages/<package>/published names those.)
p="${1:-tscaly}"
cd "$(dirname "$0")/../../$p" 2>/dev/null || { echo "version.sh: no package $p" >&2; exit 2; }
v="$(ls . | grep '^[0-9][0-9.]*$' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)"
[ -n "$v" ] || { echo "version.sh: packages/$p holds no version directory" >&2; exit 1; }
echo "$v"
