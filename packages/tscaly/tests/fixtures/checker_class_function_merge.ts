// ★★★ THE ONE BLOCK OF THE WORKER A **CLASS** SYMBOL CAN REACH ON ITS OWN, and
// it is why the class arm is one of this slice's two call sites. A class
// declaration merged with a function declaration gives one symbol carrying both
// SymbolFlagsClass and SymbolFlagsFunction, hasNonAmbientClass is set by the
// class declaration and the block reports once per declaration with a code
// chosen by the declaration's KIND: TS2813 on the class, TS2814 on the function.
//
// ★ The related diagnostic the reference attaches to each report
// (`Consider_adding_a_declare_modifier_to_this_class`, TS6506) is not among a
// file's C lines, so no instrument here can see it — see the family header.
function m(a: string): void { }
class m { }
