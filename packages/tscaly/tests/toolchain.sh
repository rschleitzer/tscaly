# SPDX-License-Identifier: Apache-2.0
# toolchain.sh -- which compiler and which runtime archive the tests use.
# Sourced by every script here, from the repository root.
#
#   SCALYC     the compiler; default: the `scalyc` on the PATH, that is an
#              installed Scaly (https://scaly.io)
#   LIBSCALY   the runtime archive a program is linked against; default:
#              lib/libscaly.a of the installation that compiler belongs to
#
# Set both to test against a compiler built somewhere else.
if [ -z "${SCALYC:-}" ]; then
  SCALYC=$(command -v scalyc 2>/dev/null || true)
  if [ -z "$SCALYC" ]; then
    echo "no scalyc on the PATH: install Scaly (https://scaly.io) or set SCALYC" >&2
    return 2
  fi
fi
if [ -z "${LIBSCALY:-}" ]; then
  # <home>/libexec/scalyc, usually reached through a link in <home>/../bin
  tc_real=$SCALYC
  while [ -L "$tc_real" ]; do
    tc_link=$(readlink "$tc_real")
    case "$tc_link" in
      /*) tc_real=$tc_link ;;
      *)  tc_real=$(dirname "$tc_real")/$tc_link ;;
    esac
  done
  tc_home=$(cd "$(dirname "$tc_real")/.." && pwd)
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) LIBSCALY=$tc_home/lib/libscaly.lib ;;
    *)                    LIBSCALY=$tc_home/lib/libscaly.a ;;
  esac
fi
