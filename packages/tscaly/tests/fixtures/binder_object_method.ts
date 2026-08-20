let o = {
    m() { let inner = 1; return inner; },
    get g() { return 1; },
    set g(v: number) { },
    async am() { },
    *gen() { },
};
