function f(x: any) {
    with (x) { }
    delete x;
    delete x.p;
    eval++;
    arguments--;
    ++eval;
    --arguments;
    !eval;
    -arguments;
    try { } catch (eval) { }
    try { } catch { }
    l1: var v = 1;
    l2: function g() { }
    l3: x;
    l4: { x; }
}
