#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice116.sh — the control battery for THE ENUM.
#
# ★★★ THE ROW TO READ FIRST IS g02, because it is the one whose defect is INVISIBLE
# to every yardstick and visible to diagcheck alone. `computeEnumMemberValues` is
# reached from two sides — checkEnumDeclaration walks the members, and
# getEnumMemberValue asks for one — so without the once-bit the auto-numbering runs
# again per member and every report inside it is emitted a second time. The T section
# is unchanged by that, because the VALUES are the same; what changes is the C
# section, and diagcheck's relation is a SUBSEQUENCE, where a duplicate line fails.
#
# ★★★ AND g22 IS THE ONE THAT SAYS WHY THIS FILE HAS TWO ANSWERS TO ONE QUESTION.
# NaN is EQUAL to itself in get_enum_literal_type's table — a Go map cannot be keyed
# on NaN, which is why upstream keeps a second table there — and NOT equal to itself
# in literal_values_equal, because `source.value == target.value` on a Go `any`
# holding a float64 is IEEE equality. Reading either rule as the other is a defect no
# fixture in this corpus can show, and the row is what fixes that in place of one.
#
# ★★★ THE VERDICTS — TWENTY-FOUR OF TWENTY-SIX GATE, measured on ONE corpus
# (1 374 cases / 1 627 units, baseline diagcheck 1 626 consistent / 716 speaking /
# 1 864 diagnostics, typegate 641 901 9876):
#
#   g01 six pins RED, 5 gates       g14 diagpin RED
#   g02 diagcheck RED, 4 pins       g15 seven pins RED, 5 gates
#   g03 typepin RED + typegate      g16 five pins RED, 5 gates
#   g04 typepin RED + typegate      g17 three pins RED, 3 gates
#   g05 diagcheck RED + typepin     g18 typegate
#   g06 five pins RED, 4 gates      g19 typepin RED + typegate
#   g07 typepin RED + typegate      g20 typegate
#   g08 typepin RED + typegate      g21 UNGATED
#   g09 typepin RED + typegate      g22 UNGATED
#   g10 typepin RED + typegate      g23 typepin RED + typegate
#   g11 typepin RED + typegate      g24 diagcheck RED + typepin
#   g12 diagcheck RED, 5 pins       g25 diagpin RED
#   g13 stoppin RED + stopgate      g26 five pins RED, 4 gates
#
# ★★★ AND THE BATTERY'S REAL PRODUCT IS THE ANSWER TO A QUESTION ITS FIRST RUN
# ASKED: **HOW DOES AN ENUM MEMBER'S VALUE BECOME VISIBLE TO A TYPE DUMP AT ALL?**
# It gated 14 of 26 on that run, and five of the twelve misses — ToInt32's wrap,
# the unsigned shift, the number stringified into a concatenation, the Infinity
# identity, the ambient computed member — were aimed at arms the fixtures DID
# contain. `E.A` prints as `E.A` whatever its value is, so a wrong VALUE is
# invisible. What makes it visible is TYPE IDENTITY: two members of one enum whose
# values are EQUAL share a single literal type, and the second prints the FIRST
# one's name. `enum_value_identity.ts` is that fixture, one pair per arm, and it
# turned four of those five. ★The fifth, g04, is the same trick one step over: an
# ambient member with no initializer is COMPUTED, so it does not continue the
# numbering and the member after it keeps a type of its own.
#
# ★★ AND ONE ROW TOOK TWO TRIES FOR A REASON WORTH KEEPING. g09's first input was
# `4294967296 | 0`, whose answer is 0 with the int32 wrap and 0 without it —
# `fmod(x, 2^32)` has already done the work, and the wrap only shows on a value
# whose remainder lands at or above 2^31. **A control aimed at a transformation
# needs an input the transformation MOVES**, which is §3.5v's *a refuter that
# cannot fire is worse than none* read from the input side rather than the code
# side.
#
# ★★★ TWO ROWS ARE UNGATED AND BOTH ARE STRUCTURAL, not a corpus gap:
#
#   g21  getBaseTypeOfEnumLikeType is reached through the WIDENING chain, and
#        `let x = E.A` stops at `recursive-type-related-to` — a chapter away — so
#        no unit in either corpus gets a fresh enum literal type as far as this
#        function with its answer still printable.
#   g22  literal_values_equal's NaN rule needs a NaN NumberLiteral that is NOT an
#        enum literal on one side of the relation, and TypeScript has no spelling
#        for a NaN literal type. The row's twin g23 measures the same pair of
#        rules from the side that DOES have an input, which is why both exist.
#
# ★★ WHAT HAS NO ROW, one sentence each. The isolatedModules reports (three of
# them: the member after a non-literal numeric one, the syntactically-non-string
# value, and resolve_name's TS1281) are behind `get_isolated_modules()`, which is
# FALSE under this harness because neither compiler option is set by the oracle's
# stub program — so they have no input on either side and a row would measure the
# flag. The cross-file arms of evaluate_entity and evaluate_enum_member are the
# same shape one level down: this suite compares ONE FILE (tests/oracle/types.go's
# header), so `GetSourceFileOfNode(location) != GetSourceFileOfNode(declaration)`
# is false by construction. And isEnumTypeRelatedTo's property walk needs two
# DIFFERENT symbols with one name, which a single unit cannot have — its first
# line answers true.
#
# ★★★ AND A REPORT REMOVED IS INVISIBLE TO diagcheck BY CONSTRUCTION, which is
# what g13, g14 and g25 are the measurement of: the relation is a SUBSEQUENCE, so
# printing FEWER lines is never red. Those three gate on a PIN (the diagnostics of
# the ten pin files, compared exactly) or on the stop log, and a row that removes
# a report and reaches for diagcheck alone measures nothing.
#
# Cost, MEASURED rather than estimated (§3.5v-cost's rule about a claim without a
# clock): on a stage-1 artifact tree the 26 rows plus baseline took **58 minutes**,
# i.e. about 2 min 10 s a row — the build dominates, and the whole-corpus gates
# sweep 1 627 units each. At stage 2 that is 18 000 units a row; do not.
. "$(dirname "$0")/battery-lib.sh"
PINFILES="$FIX/enum_values.ts \
$FIX/enum_members.ts \
$FIX/enum_merged.ts \
$FIX/enum_relation.ts \
$FIX/enum_shift_simplify.ts \
$FIX/enum_reports.ts \
$FIX/enum_evaluator_edges.ts \
$FIX/enum_nan.ts \
$FIX/enum_const_access.ts \
$FIX/enum_name_escape.ts \
$FIX/enum_value_identity.ts \
$FIX/enum_self_reference.ts"
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

# g01 — the chapter's premise: computeEnumMemberValues back to a report. Every enum
# value, every enum type and the seven stops this slice closed go with it.
mk('g01.py',
   '''        this.compute_enum_member_values(node)''',
   '''        this.record_unported("compute-enum-member-values", KindEnumDeclaration)
        return''')

# g02 — the once-bit never SET, so the member walk runs again for every member whose
# value is asked for. The values are unchanged; the REPORTS are doubled.
mk('g02.py',
   '''        set links.enum_values_computed: true''',
   '''        if false
            set links.enum_values_computed: true''')

# g03 — a non-numeric member leaving the auto-value PRESENT, so `enum E { A = "x", B }`
# numbers B instead of reporting that it needs an initializer.
mk('g03.py',
   '''                else
                    set auto_present: false
                set previous: m''',
   '''                set previous: m''')

# g04 — the ambient non-const arm removed: a member with no initializer in a
# `declare enum` is auto-numbered instead of becoming a COMPUTED member.
mk('g04.py',
   '''            if (AstNode.flags_of(parent as ref[AstNode]) & NodeFlagsAmbient) <> 0
            {
                if this.is_enum_const(parent) = false
                    return Checker.eval_none()
            }''',
   '''            if false
            {
                if this.is_enum_const(parent) = false
                    return Checker.eval_none()
            }''')

# g05 — the numeric-name report without its Infinity/NaN exception, so a member
# actually named `Infinity` or `NaN` is reported as a numeric name.
mk('g05.py',
   '''                    if AstNode.is_infinity_or_nan_string(data, len) = false
                        this.error_on_node(name, DiagAn_enum_member_cannot_have_a_numeric_name)''',
   '''                    this.error_on_node(name, DiagAn_enum_member_cannot_have_a_numeric_name)''')

# g06 — the evaluator not skipping outer expressions, so `(1 + 2)` evaluates to
# nothing and the member becomes computed.
mk('g06.py',
   '''        let expr Parser.skip_outer_expressions(expr_in, OEKParentheses)''',
   '''        let expr expr_in''')

# g07 — the prefix MINUS answering its operand unchanged.
mk('g07.py',
   '''                if op = KindMinusToken
                    return EvalResult(EvalKindNumber, null, 0, jsnum_negate_value(result.bits), is_syntactically_string, resolved_other_files, has_external_references)''',
   '''                if op = KindMinusToken
                    return EvalResult(EvalKindNumber, null, 0, result.bits, is_syntactically_string, resolved_other_files, has_external_references)''')

# g08 — the shift count without its `& 31` mask, so `1 << 33` is a 33-bit shift
# instead of a one-bit one.
mk('g08.py',
   '''function jsnum_to_shift_count(bits: u64) returns int
    (jsnum_to_uint32(bits) as int) & 31''',
   '''function jsnum_to_shift_count(bits: u64) returns int
    jsnum_to_uint32(bits) as int''')

# g09 — ToInt32 without the wrap, so a value past 2^31 keeps its magnitude and every
# bitwise operator on a large enum value answers a 64-bit quantity.
mk('g09.py',
   '''function jsnum_wrap_int32(v: int) returns int
{
    let low v & 4294967295
    if low >= 2147483648
        return low - 4294967296
    low
}''',
   '''function jsnum_wrap_int32(v: int) returns int
    v''')

# g10 — the unsigned right shift computed on the SIGNED value, which is the one shift
# whose left operand is not int32.
mk('g10.py',
   '''    jsnum_bits_of((jsnum_to_uint32(x) >> (jsnum_to_shift_count(y) as u64)) as double)''',
   '''    jsnum_bits_of((jsnum_to_int32(x) >> jsnum_to_shift_count(y)) as double)''')

# g11 — the string concatenation not stringifying a NUMBER operand, so `1 + "a"`
# answers "a".
mk('g11.py',
   '''        if r.kind = EvalKindNumber
        {
            var nb char[JSNUM_MAX_TEXT]
            let n jsnum_to_string(r.bits, &nb[0])
            out.append(&nb[0], n as size_t)
            return
        }''',
   '''        if r.kind = EvalKindNumber
            return''')

# g12 — evaluate_entity's Infinity/NaN arm removed, so those two identifiers are not
# constant and the member becomes computed.
mk('g12.py',
   '''            if AstNode.is_infinity_or_nan_string(data, len)
            {
                let g this.lookup_globals(data, len, SymbolFlagsValue)''',
   '''            if false
            {
                let g this.lookup_globals(data, len, SymbolFlagsValue)''')

# g13 — the forward-reference test removed from evaluateEnumMember: a member that
# references a LATER member answers that member's value instead of reporting.
mk('g13.py',
   '''        if this.is_block_scoped_name_declared_before_use(d, location) = false
        {
            this.error_on_node(expr, DiagA_member_initializer_in_a_enum_declaration_cannot_reference_members_declared_after_it_including_members_defined_in_other_enums)
            return Checker.eval_number(jsnum_from_int(0))
        }''',
   '''        if false
        {
            this.error_on_node(expr, DiagA_member_initializer_in_a_enum_declaration_cannot_reference_members_declared_after_it_including_members_defined_in_other_enums)
            return Checker.eval_number(jsnum_from_int(0))
        }''')

# g14 — the used-before-assigned report removed (a member whose value declaration IS
# the location, i.e. an initializer naming its own member).
mk('g14.py',
   '''        if d = location
        {
            this.error_on_node(expr, DiagProperty_0_is_used_before_being_assigned)
            return Checker.eval_none()
        }''',
   '''        if false
        {
            this.error_on_node(expr, DiagProperty_0_is_used_before_being_assigned)
            return Checker.eval_none()
        }''')

# g15 — getDeclaredTypeOfEnum not writing the MEMBER's own declared type, which is
# the slot getDeclaredTypeOfEnumMember reads: every member's type becomes the enum's.
mk('g15.py',
   '''                                if member_symbol <> null
                                {
                                    let ml2 this.declared_type_link_of(member_symbol as ref[Symbol])
                                    set ml2.declared_type: this.get_fresh_type_of_literal_type(mt)
                                }''',
   '''                                if false
                                {
                                    let ml2 this.declared_type_link_of(member_symbol as ref[Symbol])
                                    set ml2.declared_type: this.get_fresh_type_of_literal_type(mt)
                                }''')

# g16 — the union's SYMBOL and alias not written, so an enum type prints as the union
# of its members instead of by its name.
mk('g16.py',
   '''        if (et.flags & TypeFlagsUnion) <> 0
        {
            set et.flags: et.flags | TypeFlagsEnumLiteral
            set et.symbol: symbol
            if et.alias_symbol = null
                set et.alias_symbol: symbol
        }''',
   '''        if false
        {
            set et.flags: et.flags | TypeFlagsEnumLiteral
            set et.symbol: symbol
            if et.alias_symbol = null
                set et.alias_symbol: symbol
        }''')

# g17 — the enum-literal table keyed on the VALUE alone, so two enums with a member
# of the same value share one type and one name.
mk('g17.py',
   '''                if r.enum_symbol = enum_symbol''',
   '''                if true''')

# g18 — createComputedEnumType without its FRESH twin, so a computed member's type is
# its own fresh type and isFreshLiteralType answers wrongly for it.
mk('g18.py',
   '''        Checker.set_literal_fresh_type(regular, fresh)
        Checker.set_literal_fresh_type(fresh, fresh)''',
   '''        Checker.set_literal_fresh_type(regular, regular)
        Checker.set_literal_fresh_type(fresh, fresh)''')

# g19 — the printer's `getDeclaredTypeOfSymbol(parent) == t` test removed, so a
# SINGLE-MEMBER enum's member prints qualified where the reference prints the parent.
mk('g19.py',
   '''            if this.get_declared_type_of_symbol(ps) = t
                return this.symbol_to_type_node(ps, SymbolFlagsType, out)''',
   '''            if false
                return this.symbol_to_type_node(ps, SymbolFlagsType, out)''')

# g20 — the printer's identifier-text test removed, so a member whose name is not an
# identifier prints as `E.1` instead of as an indexed access over a type query.
mk('g20.py',
   '''            if Checker.is_identifier_text(Symbol.name_data_of(sym), Symbol.name_len_of(sym)) = false''',
   '''            if false''')

# g21 — getBaseTypeOfEnumLikeType answering its argument, so a fresh enum member type
# widens to itself instead of to the enum.
mk('g21.py',
   '''        if (Symbol.flags_of(t.symbol as ref[Symbol]) & SymbolFlagsEnumMember) = 0
            return t''',
   '''        if true
            return t''')

# g22 — literal_values_equal treating NaN as equal to itself, which is
# get_enum_literal_type's rule applied where the reference uses Go `any` equality.
mk('g22.py',
   '''            let ab Checker.literal_bits_of(a)
            let bb Checker.literal_bits_of(b)
            if jsnum_is_nan(ab)
                return false
            if jsnum_is_nan(bb)
                return false
            return ab = bb''',
   '''            let ab Checker.literal_bits_of(a)
            let bb Checker.literal_bits_of(b)
            return Checker.enum_values_equal(ab, bb)''')

# g23 — the enum-literal table treating two NaNs as different keys, which is the
# relation's rule applied where the reference keeps a table of its own.
mk('g23.py',
   '''function enum_values_equal(a: u64, b: u64) returns bool
    {
        if a = b
            return true
        if jsnum_is_nan(a) = false
            return false
        jsnum_is_nan(b)
    }''',
   '''function enum_values_equal(a: u64, b: u64) returns bool
        a = b''')

# g24 — the shift-simplification report without its magnitude test, so every shift
# in an enum member reports.
mk('g24.py',
   '''                            if jsnum_at_least(jsnum_abs(rhs_eval.bits), jsnum_from_int(32))''',
   '''                            if true''')

# g25 — checkConstEnumAccess accepting every position, so the const-enum object's
# illegal uses stop being reported.
mk('g25.py',
   '''        if ok = false
            this.error_on_node(node, DiagX_const_enums_can_only_be_used_in_property_or_index_access_expressions_or_the_right_hand_side_of_an_import_declaration_or_export_assignment_or_type_query)''',
   '''        if false
            this.error_on_node(node, DiagX_const_enums_can_only_be_used_in_property_or_index_access_expressions_or_the_right_hand_side_of_an_import_declaration_or_export_assignment_or_type_query)''')

# g26 — someType's union walk back to a stop, which is where slice 116 found an
# expired note rather than a defect: an enum's declared type is the first union that
# reaches it.
mk('g26.py',
   '''    function some_type_is_generic_with_union_constraint(this, t: ref[Type]) returns bool
    {
        if (t.flags & TypeFlagsUnion) <> 0
        {''',
   '''    function some_type_is_generic_with_union_constraint(this, t: ref[Type]) returns bool
    {
        if (t.flags & TypeFlagsUnion) <> 0
        {
            this.record_unported("some-type", 0)
            return true
        }
        if false
        {''')
MK

JS=$PKG/0.1.2/tscaly/jsnum.scaly

control "g01 computeEnumMemberValues back to a report"          $CHECKER "$PATCHDIR/g01.py"
control "g02 the once-bit never set"                            $CHECKER "$PATCHDIR/g02.py"
control "g03 a string member leaving the auto-value present"    $CHECKER "$PATCHDIR/g03.py"
control "g04 the ambient non-const arm removed"                 $CHECKER "$PATCHDIR/g04.py"
control "g05 the numeric-name report without its exception"     $CHECKER "$PATCHDIR/g05.py"
control "g06 the evaluator not skipping parentheses"            $CHECKER "$PATCHDIR/g06.py"
control "g07 the prefix minus answering its operand"            $CHECKER "$PATCHDIR/g07.py"
control "g08 the shift count without its mask"                  $JS      "$PATCHDIR/g08.py"
control "g09 ToInt32 without the wrap"                          $JS      "$PATCHDIR/g09.py"
control "g10 the unsigned shift computed signed"                $JS      "$PATCHDIR/g10.py"
control "g11 the concatenation not stringifying a number"       $CHECKER "$PATCHDIR/g11.py"
control "g12 the Infinity/NaN arm removed"                      $CHECKER "$PATCHDIR/g12.py"
control "g13 the forward-reference test removed"                $CHECKER "$PATCHDIR/g13.py"
control "g14 the used-before-assigned report removed"           $CHECKER "$PATCHDIR/g14.py"
control "g15 the member's own declared type not written"        $CHECKER "$PATCHDIR/g15.py"
control "g16 the union's symbol and alias not written"          $CHECKER "$PATCHDIR/g16.py"
control "g17 the literal table keyed on the value alone"        $CHECKER "$PATCHDIR/g17.py"
control "g18 createComputedEnumType without its fresh twin"     $CHECKER "$PATCHDIR/g18.py"
control "g19 the printer's parent-type test removed"            $CHECKER "$PATCHDIR/g19.py"
control "g20 the printer's identifier-text test removed"        $CHECKER "$PATCHDIR/g20.py"
control "g21 getBaseTypeOfEnumLikeType answering its argument"  $CHECKER "$PATCHDIR/g21.py"
control "g22 literal_values_equal with NaN equal to itself"     $CHECKER "$PATCHDIR/g22.py"
control "g23 the enum table with NaN unequal to itself"         $CHECKER "$PATCHDIR/g23.py"
control "g24 the shift report without its magnitude test"       $CHECKER "$PATCHDIR/g24.py"
control "g25 checkConstEnumAccess accepting every position"     $CHECKER "$PATCHDIR/g25.py"
control "g26 someType's union walk back to a stop"              $CHECKER "$PATCHDIR/g26.py"
