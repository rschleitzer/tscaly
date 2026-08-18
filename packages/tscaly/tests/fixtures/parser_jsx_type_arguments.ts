// Slice 20 — the type-argument list on a tag, which is the one thing in this
// grammar the JavaScriptFile context flag switches off. Under TSX it is parsed;
// the `.jsx` unit here is compared under TSX too (see classify_unit), so the
// clause it gates is exercised and the JS reading is not reachable from this port
// yet — stated so the fixture is not read as covering both.
// @Filename: typeargs.tsx
const a = <Foo<string> />;
const b = <Foo<string, number>>child</Foo>;
const c = <Foo<T> a="1">{x}</Foo>;
