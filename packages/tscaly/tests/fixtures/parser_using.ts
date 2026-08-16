declare function g(): any;
using a = g();
async function f() {
    using b = g();
    await using c = g();
    await 1;
    using;
}
