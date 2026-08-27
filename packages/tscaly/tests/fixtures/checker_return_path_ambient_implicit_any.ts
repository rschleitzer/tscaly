// SLICE 82: the same report from the OTHER shape a missing body has — an ambient
// declaration rather than an overload signature. Two files rather than one because
// the unported tag is FIRST-WINS (slice 72) and because the reference reaches the
// two through different node flags.
declare function ambientNoReturn(x: number);
