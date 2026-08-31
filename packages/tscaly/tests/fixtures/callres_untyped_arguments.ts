// Slice 108. resolveUntypedCall's ARGUMENT WALK, and the one thing that makes it
// observable.
//
// ★★★ THE WALK IS NOT AN ALTERNATIVE TO THE REPORT, which is the reference's own
// comment on the line above it: the type arguments and then every argument are
// checked "even though we will give an error that untyped calls may not accept type
// arguments", so that the arguments are still typed and still marked as referenced. A
// port that returned early on TS2347 would lose every diagnostic inside an argument.
//
// ★★★ AND THE ARGUMENT HAS TO CARRY A DIAGNOSTIC OF ITS OWN OR THE WALK IS INVISIBLE.
// A well-typed argument of an untyped call produces nothing in either direction, so
// the fixture's argument is a PRIVATE property access — TS2341, which this port
// reports — and the walk is then exactly the difference between that line arriving
// and not.
//
// ★★ IT IS A FILE OF ITS OWN AND NOT A SECOND LINE OF callres_untyped.ts, for a
// mechanism neither fixture is about: a call in a LATER statement narrows its callee
// through the flow graph, the walk visits the earlier call, and
// `get-effects-signature`'s memoised stop REPLAYS its mark — so a second untyped call
// in one file answers 0 and the fixture would have measured the flow graph.
declare const anyf: any;
class K { private q: number = 1; }
declare const k: K;
anyf(k.q);
