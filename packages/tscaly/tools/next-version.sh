#!/bin/bash
# tools/next-version.sh <version> -- begin the next version of the tscaly
# package.
#
# A published version does not change (packages/tscaly/published names them;
# `scaly publish` writes it). So the first change after a release begins a new
# version: the package's directory is renamed to the new number -- the
# published one lives on at its commit, which is where a build that declares
# it fetches it --, and everything in this repository that names the old
# directory or declares the old version follows: the scripts, the generators,
# the programs' `package tscaly <old>`, the documents.
#
# The same renames a version that is NOT published yet -- 0.1.1 to 0.2.0, when
# `scaly publish --check` says the change takes the second number.
set -eu
cd "$(dirname "$0")/../../.."
[ $# = 1 ] || { echo "usage: packages/tscaly/tools/next-version.sh <version>" >&2; exit 2; }
new="$1"
old="$(packages/tscaly/tools/version.sh)"
echo "$new" | grep -q '^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' || { echo "next-version: $new is no version (three numbers)" >&2; exit 2; }
[ "$(printf '%s\n%s\n' "$old" "$new" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "$new" ] && [ "$old" != "$new" ] \
  || { echo "next-version: tscaly is at $old, $new is not higher" >&2; exit 1; }
[ -z "$(git status --porcelain -- . ':!packages/tscaly/_submodules')" ] || { echo "next-version: the tree has uncommitted changes -- commit them first" >&2; exit 1; }
olde="$(echo "$old" | sed 's/\./\\./g')"

git mv "packages/tscaly/$old" "packages/tscaly/$new"
n=0
# The directory is named in many spellings here (packages/tscaly/<v>,
# "$PKG"/<v>, os.path.join(PKG, "<v>", ...), `<v>/` in the documents), so the
# rule is the other way round: every mention of the old number follows,
# except those that are another package's -- `package scaly <v>` and the
# compiler's own packages/scaly/<v>, scalyc/<v>, scalyls/<v>.
for f in $(git grep -l -e "$olde" -- . ':!packages/tscaly/_submodules' ':!packages/tscaly/published' || true); do
  before="$(cksum < "$f")"
  perl -pi -e "s{(?<!package scaly )(?<!/scaly/)(?<!scalyc/)(?<!scalyls/)(?<![0-9.])\\Q$old\\E(?![0-9.])}{$new}g" "$f"
  [ "$(cksum < "$f")" = "$before" ] || n=$((n+1))
done
echo "next-version: tscaly $old -> $new (packages/tscaly/$new; $n files named the old one)"
if [ -f packages/tscaly/published ] && grep -q "^$old " packages/tscaly/published; then
  echo "  $old is published: it stays what it was, at its commit."
else
  echo "  $old was not published: this is a renumbering."
fi
echo "  Next: the yardsticks, commit."
