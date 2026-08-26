// ★★★ checkQuestionTokenAgreementBetweenOverloads (TS2386), and the TYPE LITERAL
// is the reason this fixture is reachable at all. A MethodSignature is walked by
// the type-MEMBER arm slice 62 ported — but only from a type literal: an
// INTERFACE declaration stops at checkIndexConstraints, one call before its own
// members walk, and a class's MethodDeclaration is not walked at all. So of the
// reference's four overload-agreement reports this is the only one the corpus can
// reach; the other three (public/private/protected, abstract, static) need a
// modifier only a class member can carry.
type T = {
    m?(a: string): void;
    m(a: number): void;
};
