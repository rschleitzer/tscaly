#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# emptylist.py — every site where a LIST GETTER's null answer is tested, and what
# the test does with it.
#
# ★★★ WHY THIS EXISTS. `get_named_members` answers null for a member table of size
# zero — that is upstream's nil slice, and `range` over one is a no-op — so
# `resolve_structured_type_members(...).properties` is NULL for `{}`. A caller that
# reads that null as a FAILURE loses the answer silently: slice 186 found four,
# of which the widening fill was the expensive one (`[{ a: 1, b: 2 }, { a: "abc" },
# {}][0]` abandoned the whole `?: undefined` fill and fell back to the UNWIDENED
# union, at rc 0, because ONE sibling had no properties).
#
# ★★★ AND IT CANNOT RANK, WHICH IS THE HONEST THING TO SAY ABOUT IT (§3.5ho's
# *an instrument that cannot rank is an instrument that cannot be read* — this one
# is read anyway because the population is 82 lines, not 8 622). For most sites the
# failure value and the empty answer COINCIDE: `has_excess_properties` with no
# properties has no excess either way, `index_signatures_related_to` with no target
# index infos is related either way. What separates a defect from a correct line is
# not the shape here but the reference's own line AFTER the loop — so this prints
# the site, the getter and the null branch's ACTION, and a reader takes it to the
# Go source one row at a time. Four of 82 were defects.
#
# Usage:  python3 packages/tscaly/tools/emptylist.py [--all]
#         --all also lists the sites whose null branch is a `continue` or a value
#         other than the function's failure sentinel.

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "0.1.0", "tscaly", "checker.scaly")

# The getters that answer a LIST and use null for "empty". Every one of them ends
# in a slot that get_named_members or a `new_*_list` may have left null.
GETTERS = {
    "get_properties_of_type",
    "get_properties_of_object_type",
    "get_properties_of_union_or_intersection_type",
    "get_index_infos_of_type",
    "get_index_infos_of_structured_type",
    "get_signatures_of_type",
    "get_signatures_of_structured_type",
    "get_base_types",
    "get_type_arguments",
    "get_element_types",
    "get_outer_type_parameters",
    "get_outer_type_parameters_of_class_or_interface",
    "get_expanded_parameters",
    "get_effective_call_arguments",
    "get_all_jsdoc_tags",
    "local_type_parameters_of",
    "get_switch_clause_types",
}

BIND = re.compile(r"\s*(?:let|var)\s+([a-z_0-9]+)\s+this\.([a-z_0-9]+)\(")
SET = re.compile(r"\s*set\s+([a-z_0-9]+):\s*this\.([a-z_0-9]+)\(")
DECL = re.compile(r"\s*(function|procedure)\s+([a-z_0-9]+)")


def enclosing(lines, i):
    for j in range(i, -1, -1):
        m = DECL.match(lines[j])
        if m:
            return m.group(2)
    return "?"


def main():
    show_all = "--all" in sys.argv
    lines = open(SRC, encoding="utf8").read().splitlines()
    rows = []
    for i, line in enumerate(lines):
        m = BIND.match(line) or SET.match(line)
        if not m:
            continue
        name, getter = m.group(1), m.group(2)
        if getter not in GETTERS:
            continue
        for k in range(i + 1, min(i + 6, len(lines))):
            if re.match(r"\s*if " + re.escape(name) + r" = null\s*$", lines[k]):
                rows.append((i + 1, enclosing(lines, i), getter, lines[k + 1].strip()))
                break
    plain = [r for r in rows if r[3].startswith("return") or r[3] == "return"]
    print("%d sites test a list getter's null; %d answer with a bare return"
          % (len(rows), len(plain)))
    print("Read each against the reference's line AFTER its loop — that is the")
    print("only thing that separates an empty answer from a lost one.\n")
    for ln, fn, getter, act in rows if show_all else plain:
        print("%7d  %-46s %-44s -> %s" % (ln, fn, getter, act))


if __name__ == "__main__":
    main()
