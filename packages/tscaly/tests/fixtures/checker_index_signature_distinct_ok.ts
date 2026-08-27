// SLICE 77: the NEGATIVE control that the grouping is by type and not by count.
// A string index and a number index are two declarations of one index symbol and
// must produce nothing — `declarations <= 1` is not the test the reference makes.
interface J { [k: string]: any; [j: number]: any; }
