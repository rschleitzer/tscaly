// slice 41 — the plainest private name. A private member is NOT named after
// itself: `getDeclarationName` sends it to
// `GetSymbolNameForPrivateIdentifier(containingClass.Symbol(), name.Text())`,
// which is the 0xFE prefix, a `#`, the CONTAINING CLASS's symbol id, an `@` and
// the text. So `#x` in class C is `%FE#1@#x` in the dump.
//
// ★ The description carries its OWN `#`, which is why the name has two of them:
// a PrivateIdentifier's `Text()` is the whole token including the hash, so the
// arm passes it through rather than stripping it. Measured against the
// reference, not assumed.
//
// ★★ The name is unspellable for the usual reason — the 0xFE byte. The `@` is a
// transcription and not a separator that earns its keep: the description always
// begins with its own `#`, so the id can never run into it. It is here because the
// reference writes it, and control c8 measures that any other byte disagrees.
class C {
    #x = 1;
    m() { return this.#x; }
}
