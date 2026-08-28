// SLICE 85. The same stop from the other side: an interface that mentions `this`
// is not thisless, so it too gets a `this` type and the Reference flag.
interface I {
    self(): this;
}
