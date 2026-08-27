// Slice 73. Two INSTANCE private fields of one name — the map that reports and the
// map that does not, on one shape.
//
// ★★★ IT SEPARATES THE TWO REPORTS. Both `#x` are one symbol with two
// declarations, so instanceNames trips and TS2300 lands twice; privateNames
// meanwhile ORs 1 into 1 and never reaches 3, so TS2804 does NOT appear. A port
// that keyed the private map by declaration count, or that read `flags == 3` as
// `flags != 0`, would add a diagnostic here and stay green on
// checker_class_private_name_static_instance.ts.
export {};
class C {
    #x: number = 1;
    #x: string = "y";
}
