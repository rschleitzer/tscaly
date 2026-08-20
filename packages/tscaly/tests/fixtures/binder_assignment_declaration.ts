function f() {}
f.x = 1;
f["y"] = 2;
namespace N { export const v = 1; }
N.w = 3;
declare const h: any;
h().z = { a: 4 };
(h as any).b = { c: 5 };
h[h].d = { e: 6 };
