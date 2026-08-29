// Everything that records a FlowFlagsAssignment or a FlowFlagsArrayMutation:
// a plain assignment, a destructuring one, a prefix and a postfix update, a
// `delete`, an element write, and the two Array methods that mutate.
declare const src: { p: number; q: number };
declare const xs: number[];

function mutations(o: { p: number }, i: number) {
    let m = 0;
    m = 1;
    m += 2;
    ++m;
    m--;
    o.p = 3;
    xs[i] = 4;
    xs.push(5);
    xs.unshift(6);
    delete (o as any).p;
    let p = 0, q = 0;
    ({ p, q } = src);
    [p, q] = [q, p];
    const [r = 1, ...rest] = xs;
    const { p: s = 2 } = src;
    return r + s + rest.length;
}
