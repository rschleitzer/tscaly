#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice111.sh — the control battery for the OBJECT-TYPE PRINTER.
#
# ★★★ THE FIRST THING TO READ HERE IS THAT FOUR ROWS ARE THE SLICE'S OWN DEFECTS, and
# that NONE of the four was found by a stop, a diagnostic or any of the fifteen
# instruments in battery-lib.sh — every one came from the REFERENCE COMPARISON, which
# is the only gate in this port that sees a name. g01, g02, g03 and g09 restore the
# four wrong versions this slice actually shipped, so each fix is pinned by the
# breakage that motivated it rather than by an argument:
#
#   g01  the union constituent written WITHOUT the printer's parenthesis, which is
#        `() => void | undefined` for `(() => void) | undefined` — a DIFFERENT TYPE,
#        not a formatting slip. The note it replaced was a containment proof over what
#        was PORTED (*"the only constituents reachable here are the keyword and literal
#        arms"*) and this slice's own object arm invalidated it. §3.5p.
#   g02  a null signature list read as a FAILURE instead of as the empty list, which
#        is what get_signatures_of_structured_type answers for every type literal that
#        has no call signature. Fourteen units printed NOTHING for those nodes, with no
#        stop logged, because TypeDump skips a node whose name answers false.
#   g03  the alias arm removed: `type T = { x: number }` printing `{ x: number; }`
#        where the reference prints `T`. The slot was deferred with the reason *"its
#        reader is typeToString's alias arm, which reports"* — true until this slice
#        made that arm answer. §3.5as.
#   g09  `filterType(propertyType, !Undefined)` called the IDENTITY in a comment
#        written in the same commit as the call that disproved it: an OPTIONAL
#        method's type is a UNION, so the unfiltered type reached getReducedType's
#        union arm and `{ m?(): void }` stopped.
#
# ★★★ AND THE SHAPE OF THAT LIST IS THE SLICE'S LESSON. Four defects, four different
# symptoms — a wrong type, a silent absence, a well-formed wrong name and a stop — and
# a single instrument caught all four while fifteen others were green on every one.
# **A printer's product is a STRING, and this port owns no gate over a string except
# the oracle.** The TYPEPIN and the TYPEGATE (slice 109) come closest and they are
# our side against our side: they would have held every one of these four steady.
#
# ★★★ ONE SENTENCE REPLACES FIVE ROWS, which is §3.5v-budget's rule met with a
# measurement: **the `typeof` family's IMPORT half has zero input this port can
# reach.** symbolToTypeNode's ImportTypeNode branch needs the chain's root to be an
# external module symbol, and getting there needs a module specifier —
# getSpecifierForModuleSymbol — which is `modulespecifiers` and its whole
# preference apparatus. Slice 110 measured the neighbouring fact (under this harness no
# specifier resolves at all), and the corpus agrees: every `typeof import("m")` in the
# reference's dumps sits in a unit that stops. So the import branch, the resolution-mode
# override, the node_modules re-derivation, getSpecifierForModuleSymbol itself and the
# IndexedAccess split have no row.
#
# ★★★ THE VERDICTS — FOURTEEN OF FIFTEEN GATE, measured on ONE corpus (1 330 cases /
# 1 583 units), and the fifteenth carries a number rather than a colour:
#
#   g01 typepin + typegate cks    g06 typepin + typegate cks   g11 typepin + typegate cks
#   g02 typepin + typegate        g07 typepin + typegate cks   g12 stopgate + typegate
#       T lines 3536 -> 3480      g08 typepin + typegate cks   g13 typepin + typegate cks
#   g03 mempin + typepin + cks    g09 tagpin + stoppin +       g14 UNGATED — see below
#   g04 typepin + typegate cks        mempin + typepin +       g15 typepin + typegate cks
#   g05 typepin + typegate cks        stopgate
#
# ★★★ TWELVE OF THE FOURTEEN MOVE THE TYPEGATE'S CHECKSUM AND NOTHING ELSE ON THE WHOLE
# CORPUS — same units answering, same units reporting, same T-line count, different
# bytes. That is slice 109's instrument earning its keep twice over: **every one of
# those twelve is a WRONG NAME AT A RIGHT POSITION, which is the breakage no count can
# see**, and before TYPEGATE existed this battery would have printed UNGATED on all
# twelve. ★g02 is the exception that proves the shape: it moves the T-LINE COUNT
# (3 536 -> 3 480), because reading a null signature list as a failure does not
# mis-name anything — it makes 56 lines vanish.
#
#   g14  FOUR ARRIVALS AND ZERO DIVERGENCES, probed rather than argued: a temporary
#        `record_unported` at the initializer arm answers 4 events over 4 units of the
#        stage-1 corpus, and a second one comparing the two spellings answers 0. The
#        reason is structural and not a corpus gap — getMinArgumentCountEx's VOID LOOP
#        is the whole difference between the field and get_min_argument_count, and it
#        only lowers the count when a parameter BEFORE the defaulted one accepts
#        `void`. Nothing of that shape reaches an optional-parameter test here. ★The
#        row stays because the two spellings are not interchangeable in general and the
#        wrong one is silent: it would answer `?` on a parameter that has none.
#
# Cost: run it on a STAGE-1 artifact tree. The whole-corpus gates in battery-lib.sh
# sweep the tree they find, and at stage 2 that is 18 348 units a row. Fifteen rows
# plus baseline is about 15 minutes at stage 1.
. "$(dirname "$0")/battery-lib.sh"
PINFILES="$FIX/checker_object_printer_shapes.ts \
$FIX/checker_object_printer_names.ts \
$FIX/checker_object_printer_union.ts \
$FIX/checker_object_printer_alias.ts \
$FIX/checker_object_printer_typeparams.ts"
battery_init "$@"
baseline

python3 - "$PATCHDIR" <<'MK'
import os, sys
D = sys.argv[1]
def mk(name, old, new, count=1):
    open(os.path.join(D, name), 'w').write(
        "import sys\n"
        "old = %r\n" % old +
        "new = %r\n" % new +
        "path = sys.argv[1]\n"
        "s = open(path).read()\n"
        "assert s.count(old) == %d, s.count(old)\n" % count +
        "open(path,'w').write(s.replace(old,new))\n")

# g01 — THE SLICE'S FIRST DEFECT: the union constituent's parenthesis removed, i.e.
# the containment proof that stood here before the object arm existed.
mk('g01.py',
   '''        if wrote_paren_needing_type
            out.append("(" as char)''',
   '''        if false
            out.append("(" as char)''')

# g02 — THE SLICE'S SECOND DEFECT: a null signature list read as a failure. This is
# the silent one — no stop, no diagnostic, the T line simply absent.
mk('g02.py',
   '''        let calls this.signature_list_or_empty(call_sigs)''',
   '''        if call_sigs = null
            return false
        let calls this.signature_list_or_empty(call_sigs)''')

# g03 — THE SLICE'S THIRD DEFECT: the alias arm removed, so a type literal prints its
# structure where the reference prints the name it was declared under.
mk('g03.py',
   '''        if t.alias_symbol <> null
        {
            let asym t.alias_symbol as ref[Symbol]''',
   '''        if false
        {
            let asym t.alias_symbol as ref[Symbol]''')

# g04 — the member ORDER of a type literal turned into the source's: properties first.
# The reference's order is call, construct, index, properties.
mk('g04.py',
   '''        if sm.index_infos <> null
        {
            let infos sm.index_infos as ref[Array[ref[IndexInfo]?]]''',
   '''        if sm.properties <> null
        {
            let props0 sm.properties as ref[Array[ref[Symbol]?]]
            var j 0
            while j < (props0.get_length() as int)
            {
                let p0 props0[j]
                if p0 <> null
                    if this.write_property_member(p0 as ref[Symbol], out) = false
                        return false
                set j: j + 1
            }
        }
        if sm.index_infos <> null
        {
            let infos sm.index_infos as ref[Array[ref[IndexInfo]?]]''')

# g05 — the type literal's TERMINATOR dropped, so `; ` becomes a separator only and a
# one-member literal reads `{ a: number }`. The printer's punctuation is not symmetric.
mk('g05.py',
   '''        if this.write_property_name_of_symbol(sym, out) = false
            return false
        if optional
            out.append("?" as char)
        out.append(": ")
        if this.type_to_string(ptype, out) = false
            return false
        out.append("; ")
        true''',
   '''        if this.write_property_name_of_symbol(sym, out) = false
            return false
        if optional
            out.append("?" as char)
        out.append(": ")
        if this.type_to_string(ptype, out) = false
            return false
        out.append(" ")
        true''')

# g06 — the METHOD arm removed, so `m(p: number): void` is written as the property
# form `m: (p: number) => void`. Both are well formed; only the reference decides.
mk('g06.py',
   '''        if (Symbol.flags_of(sym) & (SymbolFlagsFunction | SymbolFlagsMethod)) <> 0
        {
            let own this.get_properties_of_object_type(ptype)''',
   '''        if false
        {
            let own this.get_properties_of_object_type(ptype)''')

# g07 — the function type's separator turned into a call signature's, i.e. the FORM
# distinction collapsed: `(a: string) => void` becomes `(a: string): void`.
mk('g07.py',
   '''        if form = SigFormFunctionType
            out.append(" => ")''',
   '''        if form = SigFormFunctionType
            out.append(": ")''')

# g08 — the `this` parameter not prepended. It is not one of the signature's own
# parameters, so dropping it is invisible to every arity the port carries.
mk('g08.py',
   '''        if sig.this_parameter <> null
        {
            if this.write_parameter_declaration(sig.this_parameter as ref[Symbol], out) = false''',
   '''        if false
        {
            if this.write_parameter_declaration(sig.this_parameter as ref[Symbol], out) = false''')

# g09 — THE SLICE'S FOURTH DEFECT: filterType treated as the identity, which sends an
# optional method's union type into getReducedType.
mk('g09.py',
   '''                    let filtered this.filter_undefined_out(ptype)''',
   '''                    let filtered ptype as ref[Type]?''')

# g10 — the property-name classification flattened to two-way: everything that is not
# an identifier is quoted, so `{ 1: number; }` becomes `{ "1": number; }`.
mk('g10.py',
   '''                    if Checker.is_numeric_literal_name(data, n)''',
   '''                    if false''')

# g11 — `stringNamed` ignored, which turns the middle arm back ON for a member
# declared `"1"`: it prints unquoted where the reference quotes it.
mk('g11.py',
   '''                if string_named = false
                {
                    if Checker.is_numeric_literal_name(data, n)''',
   '''                if true
                {
                    if Checker.is_numeric_literal_name(data, n)''')

# g12 — the `typeof` fork answered false always, so a class's static side, an enum and
# a value module print their structure instead of `typeof X`.
mk('g12.py',
   '''        if (f & (SymbolFlagsEnum | SymbolFlagsValueModule)) <> 0
            return true''',
   '''        if (f & (SymbolFlagsEnum | SymbolFlagsValueModule)) <> 0
            return false''')

# g13 — the type parameter's DEFAULT dropped: `<T = string, U>` becomes `<T, U>`.
mk('g13.py',
   '''        if d0 <> null
        {
            out.append(" = ")''',
   '''        if false
        {
            out.append(" = ")''')

# g14 — the optional parameter's `?` decided by get_min_argument_count instead of by
# the signature's own field. The two differ by getMinArgumentCountEx's VOID LOOP,
# which the flags this call site passes return before.
mk('g14.py',
   '''            return idx >= (sig as ref[Signature]).min_argument_count''',
   '''            return idx >= this.get_min_argument_count(sig as ref[Signature])''')

# g15 — the constraint written as the annotation's SOURCE TEXT instead of from the TYPE.
# ★★★THE PREDICTION WAS *UNGATED* AND IT WAS WRONG FOR A REASON THAT CORRECTS THE ROW'S
# OWN PREMISE: raw source text is NOT what upstream's node reuse produces. Reuse hands
# the printer a NODE, which re-emits `{ a: number }` as `{ a: number; }` — so this patch
# models a third thing, and what it proves is only that the constraint is written from
# the type. **The reuse divergence itself is measured by no row here; what measures it is
# the reference comparison, which is green on every constrained parameter either corpus
# holds.**
mk('g15.py',
   '''        if c <> null
        {
            out.append(" extends ")
            if this.type_to_string(c, out) = false
                return false
        }''',
   '''        if c <> null
        {
            out.append(" extends ")
            let cd this.get_constraint_declaration(tp)
            if cd <> null
            {
                if this.write_declaration_name(cd, out) = false
                    return false
            }
            if cd = null
                if this.type_to_string(c, out) = false
                    return false
        }''')
MK

control "g01 the union constituent's PARENTHESIS removed"        $CHECKER "$PATCHDIR/g01.py"
control "g02 a null signature list read as a FAILURE"            $CHECKER "$PATCHDIR/g02.py"
control "g03 the type-ALIAS arm removed"                         $CHECKER "$PATCHDIR/g03.py"
control "g04 the type literal's member ORDER made the source's"  $CHECKER "$PATCHDIR/g04.py"
control "g05 the type literal's member TERMINATOR dropped"       $CHECKER "$PATCHDIR/g05.py"
control "g06 the METHOD arm removed (property form for a method)" $CHECKER "$PATCHDIR/g06.py"
control "g07 the function type's ARROW made a colon"             $CHECKER "$PATCHDIR/g07.py"
control "g08 the THIS parameter not prepended"                   $CHECKER "$PATCHDIR/g08.py"
control "g09 filterType treated as the IDENTITY"                 $CHECKER "$PATCHDIR/g09.py"
control "g10 the property name quoted whenever not an identifier" $CHECKER "$PATCHDIR/g10.py"
control "g11 stringNamed ignored in the name classification"     $CHECKER "$PATCHDIR/g11.py"
control "g12 the typeof fork answering false"                    $CHECKER "$PATCHDIR/g12.py"
control "g13 the type parameter's DEFAULT dropped"               $CHECKER "$PATCHDIR/g13.py"
control "g14 the optional-parameter test using the VOID LOOP"    $CHECKER "$PATCHDIR/g14.py"
control "g15 the constraint written as the ANNOTATION'S SOURCE TEXT" $CHECKER "$PATCHDIR/g15.py"
