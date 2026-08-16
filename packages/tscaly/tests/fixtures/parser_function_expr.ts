const a = function () { return 1; };
const b = function named() { return 1; };
const c = function* () { yield 1; };
const d = function* gen() { yield* gen(); };
const e = async function () { await 1; };
const f = async function* () { yield 1; };
const g = function (x: number, y = 2): number { return x; };
const h = function <T>(x: T): T { return x; };
const i = function () { return function () { return 1; }; };
