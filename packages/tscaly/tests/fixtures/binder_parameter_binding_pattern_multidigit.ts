// slice 40 — a TWO-DIGIT index. `strconv.Itoa` is a decimal conversion and the
// port has to write the digits most-significant-first out of an arithmetic that
// produces them the other way round, so eleven parameters is the cheapest place
// where a wrong loop bound or a wrong buffer offset shows up as `__1`, `__01` or
// a truncated name rather than `__10`.
function f(
    a0: number, a1: number, a2: number, a3: number, a4: number,
    a5: number, a6: number, a7: number, a8: number, a9: number,
    { ten }: { ten: number },
    a11: number,
    [twelve]: number[]
) {
    return ten + twelve;
}
