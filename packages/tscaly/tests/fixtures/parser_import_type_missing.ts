// The two failing heads. `import` with no paren reports 1005; `import(` with no
// type reports Type_expected (1110) through the qualifier's own routine, which
// is the diagnostic this port did not carry before slice 18.
type A = import;
type B = import(;
