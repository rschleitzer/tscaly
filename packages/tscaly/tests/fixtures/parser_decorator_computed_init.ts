// The same guard on the shape a real file writes — `@d` and a computed property
// name with an initializer. It gates by the MATCHED COUNT rather than by a red:
// with element access allowed the port reads `@(d[1])` and then meets `=`,
// which cannot start a class member, so it reports unported instead of
// answering wrongly. See parser_decorator_computed.ts for the red half.
declare const d: any;

class C {
    @d [1] = 2;
}
