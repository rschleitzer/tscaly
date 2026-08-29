// Slice 95, and the fixture the chapter opens on: a type reference whose name
// resolves LOCALLY, which is the only half of getTypeFromTypeReference this port
// can reach without the globals table (§3.11). Every name below is declared in a
// namespace, because a SCRIPT file's top-level names are merged into globals
// upstream and `is_global_source_file` is exactly why resolve_name skips them —
// so `interface Foo {}` at file scope would MISS here and measure the table's
// absence instead of this chapter.
//
// What the TYPEREF PIN reads off it: the interface (symbol flags 64), the class
// (32) and the type parameter (262144), and the name each one prints back as.
declare namespace N {
    interface Foo { a: number; }
    class Bar { b: string; }
    let f: Foo;
    let g: Bar;
    function id(x: Foo): Bar;
}
