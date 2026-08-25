// ★★★ THE ONLY SHAPE THAT REACHES resolveBaseTypesOfInterface'S LOOP BODY, and
// it needs BOTH an `extends` clause and a `this` in the body. An interface with
// `extends` alone is claimed one call EARLIER by isThislessInterface's heritage
// branch, which reports resolve-entity-name; the ContainsThis test stands in
// front of that branch and answers false first, so the interface gets a `this`
// type, its declared type is built, and getBaseTypes then finds the heritage
// element and stops at getTypeFromTypeNode.
//
// ★★★ IT IS ALSO THE GATE ON A BINDER CHANGE THIS SLICE HAD TO MAKE.
// NodeFlagsContainsThis had no WRITER in this port until slice 67 — the binder
// listed b.seenThisKeyword among its flow-only omissions — so this fixture
// answered resolve-entity-name, and every interface mentioning `this` was
// silently denied its `this` type. Nothing printed the difference; this tag is
// the only place it shows.
//
// ★ `Base` is declared AFTER `J` because record_unported is first-wins per unit
// and interfaces hoist, so the order costs no diagnostic.
interface J extends Base {
    self(): this;
}
interface Base {
    b: string;
}
