// A stage-2 finding of slice 115: the type-parameter CONSTRAINT is the nodebuilder's
// one node-REUSE site, so the reference reprints the source — `<T extends (1)>`, with
// the parentheses — where a canonical name says `1`. It is UNPORTED (nodecopy.go is
// 900 reference lines) and the stop TAG is the witness; `g` beside it is the control
// whose source spelling IS its canonical name and which therefore still completes.
declare namespace N {
    declare function f<T extends (1)>(test: T): void;
}
