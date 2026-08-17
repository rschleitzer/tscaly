// `@await` OUTSIDE an [Await] context is legal: `await` is an ordinary
// identifier there, and the reference emits nothing. The twin of
// parser_decorator_await.ts, and the reason parseDecoratorExpression's arm is
// conditional on inAwaitContext rather than on the token alone — drop that test
// and this case reports unported.
declare const d: any;

function f() { @await class C { } }
