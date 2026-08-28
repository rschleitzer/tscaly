// The constructor's ERROR SPAN with modifiers in front of the keyword: the
// reference scans FORWARD to `constructor` and reports from the first token, so
// one scan and a loop answer differently here and nowhere else.
class C {
    private constructor(x: number);
    private constructor(x: string);
}
