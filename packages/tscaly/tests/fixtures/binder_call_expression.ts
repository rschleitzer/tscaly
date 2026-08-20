declare function f(...args: any[]): any;
f({ a: 1 }, { b: 2 });
f<{ c: 3 }>({ d: 4 });
f()({ e: 5 });
f().g = { h: 6 };
new Date({ i: 7 } as any);
