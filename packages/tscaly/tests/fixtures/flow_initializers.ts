// bindInitializer: a default initializer is joined with the flow that skipped
// it, so a mutation inside one does not narrow the parameter for the body. The
// binding element and the parameter both bind their NAME last.
declare let counter: number;

function initializers(
    a = (counter = 1),
    { b, c = (counter = 2) }: { b: number; c?: number } = { b: 0 },
    [d, e = 3]: number[] = [],
    ...rest: number[]
) {
    return a + b + c + d + e + rest.length;
}
