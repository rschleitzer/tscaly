// Slice 57. ONE generic interface with a reserved name, and it exists because
// the prediction written for it was wrong.
//
// ★★★ THE ARM REACHES ITS HOLE AND REPORTS TS2427 ANYWAY. checkInterfaceDeclaration
// asks checkTypeParameters BEFORE checkTypeNameIsReserved, and this port stops
// inside checkTypeParameters — so the fixture was written expecting silence. It
// is not silent: record_unported MARKS the unit and does not return, so the C
// section runs on past the hole and the reserved-name report is still made. That
// is the file's convention rather than an accident (check_signature_declaration
// has had the same shape since slice 52), and it is sound because diagcheck's
// relation is a SUBSEQUENCE — a line we print must be one of the reference's,
// and this one is.
//
// ★★ WHAT THE HOLE DOES MOVE IS THE TAG, and that is the only place the order is
// visible at all. This unit's unported tag is `check-type-parameter`; its
// type-alias twin's is `check-exports-on-merged-declarations`, because the alias
// arm asks the reserved name second and reaches its own hole later. The two
// files are a PAIR for that reason — either alone reads as a rule about
// generics, and no yardstick compares a tag, so only the battery's pin measures
// this.
//
// ★ ONE declaration, because record_unported keeps the FIRST report: a generic
// interface behind a non-generic one would carry the non-generic one's tag and
// witness nothing (slice 56's *a fixture that cannot be first is not a witness*).
interface never<T> {}
