({ a: (eval = 1) } = { b: (eval = 2) });
[y] = [{ c: 3 }];
({ p: [eval = 4] = [eval = 5] } = { q: 6 });
({ r: { s: eval = 7 } = { t: eval = 8 } } = { u: 9 });
declare function fn(v: any): any;
({ v: fn([eval = 10] = [eval = 11]) } = { w: 12 });
declare const t: any;
({ y: fn(t)[eval = 13] = (eval = 14) } = { z: 15 });
