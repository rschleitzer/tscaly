// SLICE 85. The index info's `is_readonly` slot — written by
// get_index_infos_of_index_symbol off the declaration's modifier, and read by
// nobody until the relation lands.
interface I {
    readonly [k: string]: string;
}
