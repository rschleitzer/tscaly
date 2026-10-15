"""portfiles.py — where the port's sources lie, for the tools.

The port is three packages, each built over the ones before it (tsbase,
tscaly, tsdriver; tests/packages.sh says what is in each), each at its highest
version directory under packages/<name>/. A module's file lies in exactly one
of them.
"""
import glob
import os

TOOLS = os.path.dirname(os.path.abspath(__file__))
PACKAGES = os.path.dirname(os.path.dirname(TOOLS))
PORT = ("tsbase", "tscaly", "tsdriver")


def version_dir(name):
    """packages/<name>/<its highest version>"""
    d = os.path.join(PACKAGES, name)
    vs = [v for v in os.listdir(d) if v[:1].isdigit()]
    vs.sort(key=lambda v: tuple(int(x) for x in v.split(".")))
    return os.path.join(d, vs[-1])


def module_files():
    """every module file of the three packages, package by package"""
    out = []
    for p in PORT:
        out += sorted(glob.glob(os.path.join(version_dir(p), p, "*.scaly")))
    return out


def root_files():
    """the three package roots and the programs beside tscaly's"""
    out = [os.path.join(version_dir(p), p + ".scaly") for p in PORT]
    return out + sorted(f for f in glob.glob(os.path.join(version_dir("tscaly"), "tscaly_*.scaly")))


def module_path(fname):
    """the file of a module by its file name, in whichever package holds it;
    tscaly's place for one that is not there yet"""
    for p in PORT:
        f = os.path.join(version_dir(p), p, fname)
        if os.path.exists(f):
            return f
    return os.path.join(version_dir("tscaly"), "tscaly", fname)
