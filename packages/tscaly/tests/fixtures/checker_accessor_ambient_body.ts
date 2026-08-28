// TS1183: an implementation cannot be declared in ambient contexts — an accessor
// with a body inside an INTERFACE.
interface I {
    get x(): number { return 1; }
}
