declare const o: any;
o?.a;
o?.[{ b: 1 }];
o?.c({ d: 2 }, { e: 3 });
o!.f;
o?.g.h({ i: 4 });
o?.().j;
(o?.k)!.m({ n: 5 });
