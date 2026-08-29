// Slice 97: the container-decided reports that are not the computed name, plus the
// one arm of tryGetThisTypeAtEx that answers a type without asking a table.
//
// ★ A `this` at the top level of a MODULE answers `undefined` (arm 5), which is the
// reference's own TODO at the line: *Maybe issue a better error than 'object is
// possibly undefined'*.
export {}

const top = this

// TS2331, and the walk does NOT return — the reference's comment is repeated at
// both arms: *do not return here so in case if lexical this is captured*. So the
// module `this` gets TS2683 as well, which is what makes the pair a subsequence
// rather than one line.
namespace N {
    const a = this
}

module M {
    const b = this
}

// ★★ TS2332 has NO INPUT and this is the proof: an enum member's initializer is
// reached through computeEnumMemberValues, which stops one chapter in front of the
// expression — so the EnumDeclaration arm is written and unreachable, exactly as
// the computed-name arm is.
enum E {
    A = <any>this
}
