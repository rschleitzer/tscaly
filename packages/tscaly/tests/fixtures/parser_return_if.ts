function a() { return; }
function b() { return 1; }
function c() { return "s"; }
function d() { return null; }
function e() { return this; }
function f() {
    return
    1;
}
function g(x) { if (x) return 1; }
function h(x) { if (x) return 1; else return 2; }
function i(x, y) {
    if (x) {
        return 1;
    } else {
        if (y) return 2;
        return 3;
    }
}
function j(x) { if (x) ; }
function k(x) { if (x) var y = 1; }
