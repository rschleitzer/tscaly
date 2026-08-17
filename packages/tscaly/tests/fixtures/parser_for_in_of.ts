// `for await` FIRST, because the awaitModifier is the ForInOrOf record's slot
// 0 and it is the only shape in which it is present — a control on that order
// has nothing to bite on in the two forms below it.
for await (const x of y) ;
for (const p in q) { r(p); }
for (let s of t) u(s);
for (v in w) ;
