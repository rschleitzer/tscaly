// Slice 20 — ScanJsxTokenEx's text arm, which is where the JSX grammar stops
// looking like a grammar and starts looking like a document scanner.
//
// ★ The whitespace-only child is the reason JsxTextData carries a bool: the
// scanner answers JsxTextAllWhiteSpaces, the factory builds a node of kind
// JsxText for it anyway, and the distinction survives only in that field — which
// a tree dump cannot see. See the record.
//
// ★ `>` and `}` are legal in JSX text and almost always a mistake, so each is
// REPORTED (1382 / 1381) and then consumed: the text token still covers them.
// @Filename: text.tsx
const a = <div>
</div>;
const b = <div>   </div>;
const c = <div>
  first line
  second line
</div>;
const d = <div>a > b</div>;
const e = <div>a } b</div>;
const f = <div>&amp; &#65; &#x41;</div>;
const g = <div>text with 'quotes' and "quotes"</div>;
const h = <div>
  <span />
</div>;
// ★★★ What tells parse_jsx_expression's non-expression exit apart is NOT the token
// it leaves behind — parse_jsx_children re-scans from the full start before every
// child, so that token is always discarded (control 33 proves the re-scan is
// load-bearing). It is a scan DIAGNOSTIC: the ordinary scanner reports on text the
// JSX scanner accepts as content, and a report survives a discarded token.
//
// `#` and `@` do NOT distinguish it, measured: both are valid ordinary tokens and
// the ordinary scan is silent on them. A lone quote does — the ordinary scan calls
// it an unterminated string literal and the JSX scan calls it text.
const i = <div>{x}#tail</div>;
const j = <div>{x}@ok</div>;
const k = <div>{x}"quote</div>;
