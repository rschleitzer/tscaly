// "Decorators are parsed in the outer [Await] context, the rest of the
// parameter is parsed in the function's [Await] context" — the reference's own
// comment at parseParameterEx, and the reason parse_parameters_worker captures
// inAwaitContext BEFORE it moves the flags (CLAUDE.md §3.5g).
//
// The two lines below are that sentence from both sides, and the flag column is
// where it shows: on the first, the Decorator carries AwaitContext and the
// Parameter does not; on the second, exactly the reverse. Until slice 12 the
// decorator half of that claim had no text that could reach it.
declare const d: any;

async function o() { function i(@d p: string) { } }
function o2() { async function i2(@d p: string) { } }
