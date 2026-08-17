// parseArgumentExpression CLEARS DisallowIn and DecoratorContext; the array
// literal's element parser is called directly and INHERITS both. The two are
// otherwise the same routine, so only a position that is inside a decorator or
// inside a `for` initializer can tell them apart.
//
// ★ parse_list_element has carried that sentence since slice 5, naming both
// halves as unported. Slice 9 made the `for` half live; this is the other half
// (§3.5p). The `1` inside `@[1]` carries DecoratorContext and the one inside
// `@d([1])` does not.
declare const d: any;

class C { @d([1]) m() { } }
class D { @[1] n() { } }
