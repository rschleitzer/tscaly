# tests/packages.sh -- sourced by every script that builds the port's programs
# by hand: the port is three packages, each built over the ones before it.
#   tsbase    the constant tables, the scanner, the AST, the parser, jsnum,
#             tspath, the option declarations, the instruments over them
#   tscaly    the binder, the program, the checker, the printer, the emitter
#   tsdriver  the options, the program host, incremental, tsc's execute,
#             watch and build
# Run from the repository's root, where ./packages lies: the compiler finds a
# package a root declares there.
#
#   package_root <name>             its root file, packages/<name>/<v>/<name>.scaly
#   build_packages <outdir> <log>   one object each, <outdir>/<name>.o, in order,
#                                   and the interfaces of the two below the top
#                                   in the build cache; false at the first that
#                                   does not compile
#   package_objects <outdir>        the objects for a link, dependents first

PORT_PACKAGES="tsbase tscaly tsdriver"

package_root() {
  echo "packages/$1/$(packages/tscaly/tools/version.sh "$1")/$1.scaly"
}

build_packages() {
  local p
  : > "$2"
  for p in $PORT_PACKAGES; do
    # the interface first, into the build cache, for the packages above:
    # read from its sources a package gives the checks less (what a
    # routine's result reaches), and tsdriver was refused on that
    if [ "$p" != tsdriver ]; then
      "$SCALYC" --emit-interface "$(package_root "$p")" >> "$2" 2>&1 || return 1
    fi
    "$SCALYC" -c --no-prelude -o "$1/$p.o" "$(package_root "$p")" >> "$2" 2>&1 || return 1
  done
}

package_objects() {
  echo "$1/tsdriver.o $1/tscaly.o $1/tsbase.o"
}
