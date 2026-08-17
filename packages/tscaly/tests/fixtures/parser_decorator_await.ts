// `@await` inside an [Await] context: the reference parses a MISSING identifier
// and reports Expression_expected, so this port stops. Permanently UNPORTED,
// and a red-producing control for the arm that stops it — without it the port
// parses `await class C {}` as an await expression and answers a tree the
// reference does not have.
declare const d: any;

async function f() { @await class C { } }
