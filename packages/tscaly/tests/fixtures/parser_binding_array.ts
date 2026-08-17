// Array binding patterns — the whole element shape in one file, as a coverage
// instrument. The controls get their own small files, because the run stops at
// the FIRST divergence and a packed fixture hides every claim behind it.
var [a] = x;
var [b, c] = x;
var [d = 1] = x;
var [...e] = x;
var [f, ...g] = x;
var [[h], [i, j]] = x;
var [{ k }] = x;
let [l]: [number] = x;
const [m = 1, n = 2] = x;
for (var [o] of p) ;
for (const [q, r] in s) ;
