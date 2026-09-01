// Slice 103: The primitive-union short circuit inside typeRelatedToSomeType —
// "we know the relation is false unless the union contains the base primitive
// type or the literal type in one of its fresh/regular forms", with the two
// exclusions the reference's own comment names.
var shortHit: string | boolean = "a";
var shortBase: string | number = "a";
var shortMiss: string | boolean = 1n;
var shortNum: string | boolean = 1;
var shortBool: number | string = false;
