// getTypeOfNode's FALLTHROUGH, which is what the kind inventory used to admit three
// kinds of by hand. Every statement here is neither a type node nor an expression
// nor a declaration, so each answers errorType and prints `any`.
{
    ;
    label: while (0) { break label; }
    do { } while (0);
    try { } catch (e) { } finally { }
    debugger;
}
