// SLICE 86. A GENERIC class: allTypeParameters is [T, thisType] and the padded
// arguments are [T, C], so newTypeMapper builds the ARRAY arm rather than the
// simple one and MapsThisOnly is false — every member goes the long way round.
class C<T> {
    [k: string]: any;
    a: T;
}
