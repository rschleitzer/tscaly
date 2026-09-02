// checkJsxOpeningLikeElementOrOpeningFragment's ELEMENT-TYPE fork: with
// JSX.ElementType declared, the tag's own type is related to it and the failure is
// TS2786 at the tag name — the head of a chain whose links a dump cannot see.
declare namespace JSX {
    type ElementType = () => any;
    interface Element { readonly brand: "jsx" }
}
declare const C: number;
const a = <C />;
